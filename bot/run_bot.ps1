$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "       ربات تلگرام مدیریت برنامه عبادی و سوره‌ها" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$VenvPython = Join-Path $ScriptDir "venv\Scripts\python.exe"

if (-not (Test-Path $VenvPython)) {
    Write-Host "[INFO] محیط مجازی venv یافت نشد. در حال ساخت خودکار..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "[INFO] در حال نصب پیش‌نیازها..." -ForegroundColor Yellow
    & $VenvPython -m pip install --upgrade pip
    & $VenvPython -m pip install -r requirements.txt
}

Write-Host "[INFO] در حال اجرای ربات..." -ForegroundColor Green
& $VenvPython main.py
