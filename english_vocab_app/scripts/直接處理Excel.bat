@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo    直接處理 Excel 生成 words.json
echo ========================================
echo.

REM 嘗試多個可能的 Python 路徑
set PYTHON_PATHS[0]=python
set PYTHON_PATHS[1]=py
set PYTHON_PATHS[2]=python3
set PYTHON_PATHS[3]=C:\Users\zheng\AppData\Local\Programs\Python\Python*\python.exe
set PYTHON_PATHS[4]=C:\Python*\python.exe
set PYTHON_PATHS[5]=C:\Program Files\Python*\python.exe

set PYTHON_CMD=
for /L %%i in (0,1,5) do (
    call set "test_path=%%PYTHON_PATHS[%%i]%%"
    where "!test_path!" >nul 2>&1
    if !errorlevel! equ 0 (
        set PYTHON_CMD=!test_path!
        goto :found_python
    )
)

:found_python
if "%PYTHON_CMD%"=="" (
    echo [ERROR] 找不到 Python
    echo.
    echo 請安裝 Python 或將 Python 添加到 PATH
    echo 下載: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [OK] 找到 Python: %PYTHON_CMD%
echo.

REM 檢查並安裝 pandas
echo [INFO] 檢查 pandas...
%PYTHON_CMD% -c "import pandas" >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] 正在安裝 pandas 和 openpyxl...
    %PYTHON_CMD% -m pip install pandas openpyxl --quiet
    if %errorlevel% neq 0 (
        echo [ERROR] 安裝 pandas 失敗
        pause
        exit /b 1
    )
    echo [OK] 安裝完成
    echo.
)

REM 運行處理腳本
echo [INFO] 正在處理 Excel 文件...
echo.
%PYTHON_CMD% process_excel.py

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [OK] 處理完成！
    echo ========================================
    echo.
    echo 請重新運行 Flutter 應用程式查看所有單字
) else (
    echo.
    echo [ERROR] 處理失敗
)

echo.
pause

