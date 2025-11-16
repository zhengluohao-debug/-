@echo off
chcp 65001 >nul
title 立即生成 words.json

cd /d "%~dp0"

powershell -ExecutionPolicy Bypass -File "立即生成words_json.ps1"

if %errorlevel% neq 0 (
    echo.
    echo 處理失敗，請檢查錯誤信息
    pause
)



