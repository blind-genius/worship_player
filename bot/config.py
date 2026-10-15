import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent

# بارگذاری تنظیمات از فایل .env
load_dotenv(BASE_DIR / ".env")


class Config:
    # Telegram Bot Token
    BOT_TOKEN = os.getenv("BOT_TOKEN", "").strip()

    # ادمین مجاز
    ADMIN_CHAT_ID = int(os.getenv("ADMIN_CHAT_ID", 0))

    # شناسه پوشه اصلی worship در گوگل درایو
    GOOGLE_DRIVE_FOLDER_ID = os.getenv(
        "GOOGLE_DRIVE_FOLDER_ID", "1wPcJ84M0WiRIn85mbYaaVsu11rdMALA9"
    ).strip()

    # مسیر فایل احراز هویت Service Account
    SERVICE_ACCOUNT_FILE = str(BASE_DIR / os.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", "service_account.json"))

    # تنظیمات همگام‌سازی ابری گیت‌هاب برای دسترسی اپلیکیشن
    GITHUB_REPO = os.getenv("GITHUB_REPO", "blind-genius/worship_player").strip()
    GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "").strip()
