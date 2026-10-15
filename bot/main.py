import logging
from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import (
    ApplicationBuilder,
    CallbackQueryHandler,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

from config import Config
from services.google_drive_service import drive_service
from services.text_normalizer import parse_input_items

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger("WorshipBot")


def is_admin(user_id: int) -> bool:
    """چک کردن اینکه آیا کاربر مجاز است یا خیر (اگر تنظیم شده باشد)."""
    if Config.ADMIN_CHAT_ID == 0:
        return True
    return user_id == Config.ADMIN_CHAT_ID


async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """پیام راهنما و معرفی ربات."""
    text = (
        "🌿 **ربات اختصاصی مدیریت لیست عبادی و سوره‌ها**\n\n"
        "این ربات به گوگل درایو شما متصل است و لیست انتخابی شما را برای **اپلیکیشن اندروید** آماده و منتشر می‌کند.\n\n"
        "📌 **روش استفاده:**\n"
        "کافیست اسامی سوره‌ها یا دعاهایی که می‌خواهید در لیست پخش قرار گیرند را برایم بفرستید.\n"
        "می‌توانید هر کدام را در یک خط یا با ویرگول (،) جدا کنید.\n\n"
        "🔹 **مثال:**\n"
        "`یاسین، لقمان، جن`\n\n"
        "یا:\n"
        "`زیارت عاشورا`\n"
        "`سوره یاسین`\n"
        "`دعای عهد`\n\n"
        "دستور /status : مشاهده لیست پخش فعلی اپلیکیشن\n"
        "دستور /help : راهنما"
    )
    await update.message.reply_text(text, parse_mode="Markdown")


async def status_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """نمایش لیست فعال کنونی در درایو."""
    await update.message.reply_text("⏳ در حال دریافت وضعیت لیست از گوگل درایو...")
    data = drive_service.read_current_playlist()

    if not data or not data.get("items"):
        await update.message.reply_text("⚠️ در حال حاضر هیچ لیست پخشی در گوگل درایو تعریف نشده است.")
        return

    items = data["items"]
    lines = [f"📋 **لیست پخش فعال در اپلیکیشن** (تعداد: {len(items)}):"]
    for item in items:
        status_icon = "🎵" if item.get("has_audio") else "🙏"
        size_str = f" ({item['size_bytes'] / (1024*1024):.1f} MB)" if item.get("size_bytes") else ""
        lines.append(f"{item['position']}. {status_icon} **{item['title']}**{size_str}")

    await update.message.reply_text("\n".join(lines), parse_mode="Markdown")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """پردازش متن ورودی و استخراج ادعیه/سوره‌ها از گوگل درایو."""
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("⛔ شما دسترسی لازم برای استفاده از این ربات را ندارید.")
        return

    raw_text = update.message.text.strip()
    if not raw_text:
        return

    item_names = parse_input_items(raw_text)
    if not item_names:
        await update.message.reply_text("❌ لطفاً حداقل نام یک سوره یا دعا را ارسال کنید.")
        return

    status_msg = await update.message.reply_text("🔍 در حال جستجو در گوگل درایو و تطبیق فایل‌ها...")

    resolved_items = []
    missing_items = []

    for name in item_names:
        result = drive_service.resolve_item(name)
        if result:
            resolved_items.append(result)
        else:
            missing_items.append(name)

    if not resolved_items:
        await status_msg.edit_text(
            f"❌ هیچ‌کدام از موارد ارسالی در پوشه و ایندکس درایو پیدا نشدند:\n"
            + "\n".join(f"• {m}" for m in missing_items)
        )
        return

    # ذخیره در حافظه مکالمه کاربر جهت تایید
    context.user_data["pending_playlist"] = resolved_items

    # ساخت متن پیش‌نمایش
    preview_lines = ["📋 **پیش‌نمایش لیست ارسالی به اپلیکیشن:**\n"]
    for idx, item in enumerate(resolved_items, start=1):
        if item.get("has_audio"):
            drive_file = item["drive_file"]
            size_mb = int(drive_file.get("size", 0)) / (1024 * 1024)
            preview_lines.append(f"{idx}. 🎵 **{item['title']}** ({size_mb:.1f} MB)")
        else:
            preview_lines.append(f"{idx}. 🙏 **{item['title']}** (بدون صوت)")

    if missing_items:
        preview_lines.append("\n⚠️ **موارد یافت‌نشده در درایو:**")
        for m in missing_items:
            preview_lines.append(f"❌ {m}")

    preview_lines.append("\nآیا این لیست در اپلیکیشن اعمال و ذخیره شود؟")

    keyboard = InlineKeyboardMarkup([
        [
            InlineKeyboardButton("✅ تأیید و انتشار به اپلیکیشن", callback_data="confirm_playlist"),
            InlineKeyboardButton("❌ لغو", callback_data="cancel_playlist"),
        ]
    ])

    await status_msg.edit_text("\n".join(preview_lines), reply_markup=keyboard, parse_mode="Markdown")


async def handle_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """پردازش دکمه‌های اینلاین تایید و لغو."""
    query = update.callback_query
    await query.answer()

    if query.data == "cancel_playlist":
        context.user_data.pop("pending_playlist", None)
        await query.edit_message_text("❌ عملیات ذخیره لیست لغو شد.")
        return

    if query.data == "confirm_playlist":
        pending = context.user_data.get("pending_playlist")
        if not pending:
            await query.edit_message_text("⚠️ داده‌های لیست منقضی شده‌اند. لطفاً مجدداً ارسال کنید.")
            return

        await query.edit_message_text("⏳ در حال ثبت و آپلود فایل playlist.json در گوگل درایو...")

        success, result, data = drive_service.save_playlist(pending)
        context.user_data.pop("pending_playlist", None)

        if success:
            await query.edit_message_text(
                "🎉 **لیست با موفقیت در فضای ابری منتشر شد!**\n\n"
                f"📊 تعداد آیتم‌ها: {len(data['items'])}\n"
                "🌐 وضعیت: **همگام‌سازی ابری فعال و آماده پخش**\n\n"
                "📱 اکنون در اپلیکیشن اندروید صفحه را به پایین بکشید تا لیست جدید بلافاصله بارگذاری شود.",
                parse_mode="Markdown",
            )
        else:
            await query.edit_message_text(
                f"❌ متأسفانه در ذخیره اطلاعات در درایو خطایی رخ داد:\n`{result}`",
                parse_mode="Markdown",
            )


def main():
    if not Config.BOT_TOKEN or Config.BOT_TOKEN == "YOUR_TELEGRAM_BOT_TOKEN_HERE":
        print("⚠️ هشدار: لطفاً توکن ربات تلگرام خود را در فایل bot/.env وارد نمایید.")
        print("ربات بدون توکن قادر به اتصال به تلگرام نخواهد بود.")
        return

    app = ApplicationBuilder().token(Config.BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", start_command))
    app.add_handler(CommandHandler("help", start_command))
    app.add_handler(CommandHandler("status", status_command))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    app.add_handler(CallbackQueryHandler(handle_callback))

    print("🚀 ربات Worship Bot آماده اجراست...")
    app.run_polling()


if __name__ == "__main__":
    main()
