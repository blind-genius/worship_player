@echo off
chcp 65001 >nul
title Worship Assistant Bot
cd /d "%~dp0"

echo ========================================================
echo        ربات تلگرام مدیریت برنامه عبادی و سوره‌ها
echo ========================================================

if not exist "venv\Scripts\python.exe" (
    echo [INFO] محیط مجازی venv یافت نشد. در حال ساخت خودکار...
    python -m venv venv
    if errorlevel 1 (
        echo [ERROR] لطفاً از نصب بودن پایتون اطمینان حاصل کنید.
        pause
        exit /b 1
    )
    echo [INFO] در حال نصب پیش‌نیازها از requirements.txt...
    venv\Scripts\python.exe -m pip install --upgrade pip
    venv\Scripts\python.exe -m pip install -r requirements.txt
)

echo [INFO] در حال اجرای ربات...
venv\Scripts\python.exe main.py
if errorlevel 1 (
    echo [ERROR] ربات با خطا مواجه شد.
    pause
)
