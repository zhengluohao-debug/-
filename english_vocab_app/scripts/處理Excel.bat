@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo    處理 Excel 生成 words.json
echo ========================================
echo.

REM Try Python first
where python >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] 找到 Python
    echo.
    
    REM Check if pandas is installed
    python -c "import pandas" >nul 2>&1
    if %errorlevel% neq 0 (
        echo [INFO] 正在安裝 pandas 和 openpyxl...
        pip install pandas openpyxl
        echo.
    )
    
    echo [INFO] 使用 Python 處理 Excel...
    python process_excel.py
    if %errorlevel% equ 0 (
        echo.
        echo [OK] 處理完成！
        goto :end
    )
    echo.
    echo [WARN] Python 處理失敗，嘗試其他方法...
    echo.
)

REM Try PowerShell with COM object
echo [INFO] 嘗試使用 PowerShell...
powershell -ExecutionPolicy Bypass -File "process_excel_simple.ps1"
if %errorlevel% equ 0 (
    echo.
    echo [OK] 處理完成！
    goto :end
)

echo.
echo [ERROR] 所有方法都失敗了
echo.
echo 請確認：
echo 1. Excel 文件在 C:\Users\zheng\Downloads\ 目錄中
echo 2. 文件名包含 "6000" 或 "學測"
echo 3. 已安裝 Python 或 Excel

:end
pause

