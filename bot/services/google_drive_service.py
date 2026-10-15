import io
import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaInMemoryUpload, MediaIoBaseDownload

from config import Config
from services.text_normalizer import normalize_persian_text

logger = logging.getLogger(__name__)

SCOPES = ["https://www.googleapis.com/auth/drive"]

FOLDER_MAP = {
    "doaa": "doaa",
    "دعا": "doaa",
    "ziarat": "ziarat",
    "زیارت": "ziarat",
    "quran": "quran",
    "قرآن": "quran",
    "daily": "daily",
    "روزانه": "daily",
}


class GoogleDriveService:
    def __init__(self):
        self._service = None
        self._folder_cache: dict[str, str] = {}
        self._index_cache: list[dict[str, Any]] | None = None
        self._playlist_file_id: str | None = None

    def _get_service(self):
        """دریافت یا ساخت کلاینت احراز هویت شده گوگل درایو."""
        if self._service is None:
            credentials = service_account.Credentials.from_service_account_file(
                Config.SERVICE_ACCOUNT_FILE,
                scopes=SCOPES,
            )
            self._service = build("drive", "v3", credentials=credentials, cache_discovery=False)
        return self._service

    def get_subfolder_id(self, folder_name: str) -> str | None:
        """یافتن شناسه زیرپوشه‌های موجود در درایو."""
        normalized = FOLDER_MAP.get(folder_name.lower(), folder_name.lower())
        if normalized in self._folder_cache:
            return self._folder_cache[normalized]

        service = self._get_service()
        results = service.files().list(
            q=(
                f"'{Config.GOOGLE_DRIVE_FOLDER_ID}' in parents"
                f" and name='{normalized}'"
                f" and mimeType='application/vnd.google-apps.folder'"
                f" and trashed=false"
            ),
            fields="files(id, name)",
        ).execute()

        files = results.get("files", [])
        if not files:
            return None

        folder_id = files[0]["id"]
        self._folder_cache[normalized] = folder_id
        return folder_id

    def load_index(self, force_refresh: bool = False) -> list[dict[str, Any]]:
        """خواندن و کش کردن محتویات index.txt از درایو."""
        if self._index_cache is not None and not force_refresh:
            return self._index_cache

        service = self._get_service()
        results = service.files().list(
            q=(
                f"'{Config.GOOGLE_DRIVE_FOLDER_ID}' in parents"
                f" and name='index.txt'"
                f" and trashed=false"
            ),
            fields="files(id, name)",
        ).execute()

        files = results.get("files", [])
        if not files:
            logger.error("❌ فایل index.txt در پوشه اصلی پیدا نشد!")
            return []

        file_id = files[0]["id"]
        request = service.files().get_media(fileId=file_id)
        buffer = io.BytesIO()
        downloader = MediaIoBaseDownload(buffer, request)
        done = False
        while not done:
            _, done = downloader.next_chunk()

        content = buffer.getvalue().decode("utf-8", errors="ignore")

        items: list[dict[str, Any]] = []
        for line in content.splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue

            path, aliases_str = line.split("=", 1)
            path = path.strip()
            aliases = [a.strip() for a in aliases_str.split(",") if a.strip()]

            if not path or not aliases:
                continue

            parts = path.split("/")
            if len(parts) != 2:
                continue

            folder, filename = parts
            items.append({
                "path": path,
                "folder": folder,
                "filename": filename,
                "aliases": aliases,
                "normalized_aliases": [normalize_persian_text(a) for a in aliases],
            })

        self._index_cache = items
        return items

    def find_file_in_folder(self, filename: str, folder_name: str) -> dict[str, Any] | None:
        """جستجوی فایل دقیق در یک زیرپوشه مشخص."""
        folder_id = self.get_subfolder_id(folder_name)
        if not folder_id:
            return None

        service = self._get_service()
        candidates = [filename]
        if not filename.endswith(".mp3"):
            candidates.append(f"{filename}.mp3")

        for exact_name in candidates:
            results = service.files().list(
                q=(
                    f"'{folder_id}' in parents"
                    f" and name='{exact_name}'"
                    f" and trashed=false"
                ),
                fields="files(id, name, size, mimeType)",
            ).execute()

            files = results.get("files", [])
            if files:
                return files[0]

        return None

    def resolve_item(self, query: str) -> dict[str, Any] | None:
        """
        یافتن مشخصات فایل و فایل آیدی در درایو بر اساس عنوان وارد شده توسط کاربر.
        """
        norm_query = normalize_persian_text(query)
        if not norm_query:
            return None

        # اگر با نماز شروع شود صوت ندارد
        if norm_query.startswith("نماز"):
            return {
                "type": "namaz",
                "title": query,
                "has_audio": False,
                "drive_file": None,
                "index_item": None,
            }

        index = self.load_index()

        # تطابق در ایندکس
        matched_index_item = None
        for item in index:
            if norm_query in item["normalized_aliases"]:
                matched_index_item = item
                break

        # اگر در حالت عادی پیدا نشد، بررسی تطابق جزیی
        if not matched_index_item:
            for item in index:
                for alias in item["normalized_aliases"]:
                    if norm_query in alias or alias in norm_query:
                        matched_index_item = item
                        break
                if matched_index_item:
                    break

        if not matched_index_item:
            return None

        # پیدا کردن فایل در پوشه مربوطه در گوگل درایو
        drive_file = self.find_file_in_folder(
            matched_index_item["filename"], matched_index_item["folder"]
        )

        if not drive_file:
            return None

        return {
            "type": "audio",
            "title": matched_index_item["aliases"][0] if matched_index_item["aliases"] else query,
            "has_audio": True,
            "drive_file": drive_file,
            "index_item": matched_index_item,
        }

    def get_playlist_file_id(self) -> str | None:
        """یافتن شناسه فایل playlist.json در درایو اگر موجود باشد."""
        if self._playlist_file_id:
            return self._playlist_file_id

        service = self._get_service()
        results = service.files().list(
            q=(
                f"'{Config.GOOGLE_DRIVE_FOLDER_ID}' in parents"
                f" and name='playlist.json'"
                f" and trashed=false"
            ),
            fields="files(id, name)",
        ).execute()

        files = results.get("files", [])
        if files:
            self._playlist_file_id = files[0]["id"]
            return self._playlist_file_id
        return None

    def read_current_playlist(self) -> dict[str, Any] | None:
        """خواندن آخرین محتوای playlist.json از درایو."""
        file_id = self.get_playlist_file_id()
        if not file_id:
            return None

        try:
            service = self._get_service()
            request = service.files().get_media(fileId=file_id)
            buffer = io.BytesIO()
            downloader = MediaIoBaseDownload(buffer, request)
            done = False
            while not done:
                _, done = downloader.next_chunk()

            return json.loads(buffer.getvalue().decode("utf-8"))
        except Exception as e:
            logger.error("خطا در خواندن playlist.json: %s", e)
            return None

    def _get_github_token(self) -> str:
        """یافتن خودکار توکن گیت‌هاب از فایل کانفیگ یا Credential Manager سیستم."""
        if Config.GITHUB_TOKEN:
            return Config.GITHUB_TOKEN
        try:
            import subprocess
            p = subprocess.Popen(["git", "credential", "fill"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
            out, _ = p.communicate(input="protocol=https\nhost=github.com\n\n", timeout=3)
            for line in out.splitlines():
                if line.startswith("password="):
                    return line.split("=", 1)[1]
        except Exception:
            pass
        return ""

    def sync_to_github(self, playlist_data: dict) -> bool:
        """ارسال خودکار فایل playlist.json به مخزن آنلاین گیت‌هاب جهت دریافت لحظه‌ای توسط اپلیکیشن."""
        token = self._get_github_token()
        if not token or not Config.GITHUB_REPO:
            return False

        try:
            import base64
            import urllib.request

            sha = None
            get_url = f"https://api.github.com/repos/{Config.GITHUB_REPO}/contents/playlist.json"
            req = urllib.request.Request(
                get_url,
                headers={"Authorization": f"token {token}", "User-Agent": "worship-bot"},
            )
            try:
                with urllib.request.urlopen(req, timeout=8) as resp:
                    sha = json.loads(resp.read().decode("utf-8")).get("sha")
            except Exception:
                pass

            content_bytes = json.dumps(playlist_data, ensure_ascii=False, indent=2).encode("utf-8")
            body = {
                "message": "sync: update playlist from Telegram bot",
                "content": base64.b64encode(content_bytes).decode("ascii"),
            }
            if sha:
                body["sha"] = sha

            put_req = urllib.request.Request(
                get_url,
                data=json.dumps(body).encode("utf-8"),
                headers={
                    "Authorization": f"token {token}",
                    "User-Agent": "worship-bot",
                    "Content-Type": "application/json",
                },
                method="PUT",
            )
            with urllib.request.urlopen(put_req, timeout=12) as put_resp:
                return put_resp.status in (200, 201)
        except Exception as e:
            logger.error("خطا در همگام‌سازی گیت‌هاب: %s", e)
            return False

    def save_playlist(self, resolved_items: list[dict[str, Any]]) -> tuple[bool, str, dict[str, Any]]:
        """
        به‌روزرسانی محتوای playlist.json در فضای ابری (گیت‌هاب و درایو) و ذخیره نسخه محلی.
        """
        service = self._get_service()

        playlist_data = {
            "version": 1,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "title": "برنامه عبادی",
            "count": len(resolved_items),
            "items": [],
        }

        for idx, item in enumerate(resolved_items, start=1):
            drive_file = item.get("drive_file") or {}
            file_id = drive_file.get("id", "")
            size = int(drive_file.get("size", 0))

            playlist_data["items"].append({
                "id": str(idx),
                "position": idx,
                "title": item["title"],
                "file_name": drive_file.get("name", ""),
                "folder": item.get("index_item", {}).get("folder", "") if item.get("index_item") else "",
                "drive_file_id": file_id,
                "size_bytes": size,
                "has_audio": bool(file_id),
                "stream_url": f"https://drive.google.com/uc?export=download&id={file_id}" if file_id else "",
            })

        # ۱. ذخیره محلی روی دیسک (در پوشه بات و ریشه پروژه)
        local_bot_path = Path(__file__).resolve().parent.parent / "current_playlist.json"
        with open(local_bot_path, "w", encoding="utf-8") as f:
            json.dump(playlist_data, f, ensure_ascii=False, indent=2)

        local_root_path = Path(__file__).resolve().parent.parent.parent / "playlist.json"
        with open(local_root_path, "w", encoding="utf-8") as f:
            json.dump(playlist_data, f, ensure_ascii=False, indent=2)

        # ۲. ارسال به گیت‌هاب برای همگام‌سازی زنده و بدون وقفه اپلیکیشن
        github_synced = self.sync_to_github(playlist_data)
        if github_synced:
            logger.info("✅ لیست پخش با موفقیت روی گیت‌هاب همگام شد.")

        # ۳. اگر فایل playlist.json در گوگل درایو نیز وجود داشته باشد، آن را هم به‌روزرسانی می‌کنیم
        existing_file_id = self.get_playlist_file_id()
        if existing_file_id:
            try:
                content_bytes = json.dumps(playlist_data, ensure_ascii=False, indent=2).encode("utf-8")
                media = MediaInMemoryUpload(content_bytes, mimetype="application/json", resumable=False)
                service.files().update(
                    fileId=existing_file_id,
                    media_body=media,
                    fields="id, name, modifiedTime",
                ).execute()
                logger.info("✅ فایل playlist.json در درایو نیز به‌روزرسانی شد: %s", existing_file_id)
            except Exception as e:
                logger.warning("به‌روزرسانی درایو: %s", e)

        return True, "cloud_synced", playlist_data


# سینگلتون سرویس
drive_service = GoogleDriveService()
