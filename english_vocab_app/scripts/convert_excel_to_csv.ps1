# Convert Excel to CSV using COM object
$ErrorActionPreference = "Continue"

$downloadsPath = "C:\Users\zheng\Downloads"
$excelFiles = Get-ChildItem -Path $downloadsPath -Filter "*.xlsx" | Where-Object { $_.Name -like "*6000*" -or $_.Name -like "*學測*" }

if ($excelFiles.Count -eq 0) {
    Write-Host "[ERROR] Excel file not found" -ForegroundColor Red
    exit 1
}

$excelFile = $excelFiles[0].FullName
$csvFile = "C:\AI\english_vocab_app\scripts\vocab_data.csv"

Write-Host "Converting Excel to CSV..." -ForegroundColor Cyan
Write-Host "Source: $($excelFiles[0].Name)" -ForegroundColor Gray
Write-Host "Target: vocab_data.csv" -ForegroundColor Gray
Write-Host ""

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    
    $workbook = $excel.Workbooks.Open($excelFile)
    $worksheet = $workbook.Worksheets.Item(1)
    
    # Save as CSV
    $csvPath = (Resolve-Path "C:\AI\english_vocab_app\scripts").Path + "\vocab_data.csv"
    $worksheet.SaveAs($csvPath, 6)  # 6 = xlCSV
    
    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    
    Write-Host "[OK] CSV file created: vocab_data.csv" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now processing CSV..." -ForegroundColor Cyan
    
    # Now process the CSV
    python "C:\AI\english_vocab_app\scripts\process_csv.py"
    
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Please manually save Excel as CSV:" -ForegroundColor Yellow
    Write-Host "1. Open Excel file" -ForegroundColor Yellow
    Write-Host "2. File -> Save As -> CSV (Comma delimited)" -ForegroundColor Yellow
    Write-Host "3. Save to: C:\AI\english_vocab_app\scripts\vocab_data.csv" -ForegroundColor Yellow
    Write-Host "4. Then run: python process_csv.py" -ForegroundColor Yellow
    if ($excel) {
        try { $excel.Quit() } catch {}
    }
    exit 1
}

