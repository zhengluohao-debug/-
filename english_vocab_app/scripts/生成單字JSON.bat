@echo off
chcp 65001 >nul
title 生成單字 JSON 文件

echo ========================================
echo    生成 words.json 文件
echo ========================================
echo.

cd /d "%~dp0"

echo 正在檢查數據文件...
echo.

if exist vocab_data.txt (
    echo [√] 找到 vocab_data.txt
    echo.
    echo 正在處理數據...
    echo.
    
    python "直接生成words_json.py"
    
    if %errorlevel% equ 0 (
        echo.
        echo ========================================
        echo 處理完成！
        echo ========================================
        echo.
        echo 生成的 JSON 文件位置:
        echo ..\assets\data\words.json
        echo.
        echo 請重新運行 Flutter 應用程序以查看所有單字
    ) else (
        echo.
        echo [×] 處理失敗
        echo 請檢查錯誤信息
    )
) else (
    echo [×] 找不到 vocab_data.txt 文件
    echo.
    echo 請將您的完整單字數據保存到以下位置:
    echo %CD%\vocab_data.txt
    echo.
    echo 數據格式: 級別^t單字^t屬性^t輸出^t中文
    echo 例如: 1^ta/an^tart.^ta/an (art.)^t一個/一個
    echo.
    echo 提示: 您可以從 Excel 或文本編輯器中複製數據
    echo       確保使用 Tab 鍵分隔各列
)

echo.
pause

