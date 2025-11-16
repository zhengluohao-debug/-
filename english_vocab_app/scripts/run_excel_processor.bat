@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo    Processing Excel to generate words.json
echo ========================================
echo.

REM Check if Python is available
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found in PATH. Trying PowerShell method...
    echo.
    powershell -ExecutionPolicy Bypass -File "process_excel.ps1"
    goto :end
)

echo Using Python to process Excel...
echo.

REM Check if pandas is installed
python -c "import pandas" >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing required packages (pandas, openpyxl)...
    pip install pandas openpyxl
    echo.
)

echo Running Python script...
python process_excel.py

:end
pause

