import re

# اعراب و حرکات عربی
ARABIC_DIACRITICS = re.compile(r"[\u064B-\u065F\u0670]")


def normalize_persian_text(text: str) -> str:
    """نرمال‌سازی پیشرفته متن فارسی و عربی جهت تطبیق حداکثری."""
    if not text:
        return ""

    # حذف اعراب
    text = ARABIC_DIACRITICS.sub("", text)

    # تبدیل حروف عربی به معادل فارسی
    text = text.replace("ي", "ی").replace("ك", "ک").replace("ة", "ه")

    # جایگزینی نیم‌فاصله‌ها و سایر فاصله‌های خاص با فاصله عادی
    text = text.replace("\u200c", " ").replace("\u200b", " ").replace("\xa0", " ")

    # حذف فاصله‌های متوالی و فاصله‌های ابتدا و انتها
    text = " ".join(text.split()).strip().lower()

    return text


def parse_input_items(raw_text: str) -> list[str]:
    """
    تجزیه متن ورودی کاربر به لیستی از اسامی جداگانه.
    پشتیبانی از تفکیک با ویرگول فارسی (،)، انگلیسی (,)، خط جدید (\n) و نقطه ویرگول.
    """
    if not raw_text:
        return []

    # جایگزینی جداکننده‌ها با خط جدید
    normalized_delimiters = (
        raw_text.replace("،", "\n")
        .replace(",", "\n")
        .replace(";", "\n")
        .replace("؛", "\n")
        .replace("-", "\n")
    )

    items = []
    for line in normalized_delimiters.splitlines():
        line = line.strip()
        # حذف شماره‌گذاری ابتدای خط مانند 1. یا ۱-
        line = re.sub(r"^[\d\u06F0-\u06F9]+[\.\-\)\s]+", "", line).strip()
        if line:
            items.append(line)

    return items
