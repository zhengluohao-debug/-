@echo off
chcp 65001 >nul
echo 正在處理單字數據...
echo.

cd /d "%~dp0"

if not exist vocab_data.txt (
    echo 錯誤: 找不到 vocab_data.txt 文件
    echo.
    echo 請將您提供的單字數據保存到 vocab_data.txt 文件中
    echo 格式: 級別^t單字^t屬性^t輸出^t中文
    echo.
    pause
    exit /b 1
)

echo 找到 vocab_data.txt 文件，開始處理...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0process_vocab_data.ps1"

if %errorlevel% equ 0 (
    echo.
    echo 處理完成！
    echo 生成的 JSON 文件: ..\assets\data\words.json
) else (
    echo.
    echo 處理失敗，請檢查錯誤信息
)

echo.
pause

