# Directly process Excel and generate JSON without converting to CSV
# Uses COM object to read Excel

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$downloadsPath = "C:\Users\zheng\Downloads"
$outputFile = Join-Path (Join-Path (Split-Path -Parent $scriptDir) "assets") "data\words.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Processing Excel to words.json" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find Excel file
$excelFiles = Get-ChildItem -Path $downloadsPath -Filter "*.xlsx" | Where-Object { $_.Name -like "*6000*" -or $_.Name -like "*學測*" }
if ($excelFiles.Count -eq 0) {
    Write-Host "[ERROR] Excel file not found in Downloads folder" -ForegroundColor Red
    exit 1
}

$excelFile = $excelFiles[0].FullName
Write-Host "[OK] Found Excel file: $($excelFiles[0].Name)" -ForegroundColor Green
Write-Host ""

# Check if Excel COM is available
try {
    $testExcel = New-Object -ComObject Excel.Application -ErrorAction Stop
    $testExcel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($testExcel) | Out-Null
} catch {
    Write-Host "[ERROR] Excel COM object not available" -ForegroundColor Red
    Write-Host "Please install Microsoft Excel or use alternative method" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Save Excel as CSV manually:" -ForegroundColor Yellow
    Write-Host "1. Open: $excelFile" -ForegroundColor Cyan
    Write-Host "2. File -> Save As -> CSV (Comma delimited)" -ForegroundColor Cyan
    Write-Host "3. Save to: C:\AI\english_vocab_app\scripts\vocab_data.csv" -ForegroundColor Cyan
    Write-Host "4. Then run: python process_csv.py" -ForegroundColor Cyan
    exit 1
}

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    
    Write-Host "Opening Excel file..." -ForegroundColor Cyan
    $workbook = $excel.Workbooks.Open($excelFile)
    $worksheet = $workbook.Worksheets.Item(1)
    
    $usedRange = $worksheet.UsedRange
    $rowCount = $usedRange.Rows.Count
    $colCount = $usedRange.Columns.Count
    
    Write-Host "[OK] Read Excel: $rowCount rows, $colCount columns" -ForegroundColor Green
    Write-Host ""
    
    # Get headers
    $headers = @()
    for ($col = 1; $col -le $colCount; $col++) {
        $header = $worksheet.Cells.Item(1, $col).Text
        $headers += $header
    }
    
    Write-Host "Columns found:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $headers.Count; $i++) {
        Write-Host "  Column $($i+1): $($headers[$i])" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Identify columns
    $levelCol = -1
    $wordCol = -1
    $posCol = -1
    $transCol = -1
    
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $header = $headers[$i].ToLower()
        if ($header -match '級|level') { $levelCol = $i + 1; Write-Host "  -> Level column: $($i+1)" -ForegroundColor Green }
        if ($header -match '單字|word') { $wordCol = $i + 1; Write-Host "  -> Word column: $($i+1)" -ForegroundColor Green }
        if ($header -match '屬性|詞性|pos|part') { $posCol = $i + 1; Write-Host "  -> POS column: $($i+1)" -ForegroundColor Green }
        if ($header -match '中文|翻譯|translation|chinese') { $transCol = $i + 1; Write-Host "  -> Translation column: $($i+1)" -ForegroundColor Green }
    }
    
    # Fallback to position
    if ($levelCol -eq -1 -and $colCount -ge 1) { $levelCol = 1; Write-Host "  -> Level column (fallback): 1" -ForegroundColor Yellow }
    if ($wordCol -eq -1 -and $colCount -ge 2) { $wordCol = 2; Write-Host "  -> Word column (fallback): 2" -ForegroundColor Yellow }
    if ($posCol -eq -1 -and $colCount -ge 3) { $posCol = 3; Write-Host "  -> POS column (fallback): 3" -ForegroundColor Yellow }
    if ($transCol -eq -1 -and $colCount -ge 5) { $transCol = 5; Write-Host "  -> Translation column (fallback): 5" -ForegroundColor Yellow }
    elseif ($transCol -eq -1 -and $colCount -ge 4) { $transCol = 4; Write-Host "  -> Translation column (fallback): 4" -ForegroundColor Yellow }
    
    Write-Host ""
    
    if ($wordCol -eq -1) {
        Write-Host "[ERROR] Cannot identify word column" -ForegroundColor Red
        $workbook.Close($false)
        $excel.Quit()
        exit 1
    }
    
    $words = @()
    $skipped = 0
    $currentLevel = 1
    
    Write-Host "Processing data..." -ForegroundColor Cyan
    
    for ($row = 2; $row -le $rowCount; $row++) {
        try {
            $levelVal = if ($levelCol -gt 0) { $worksheet.Cells.Item($row, $levelCol).Text.Trim() } else { "" }
            $wordVal = if ($wordCol -gt 0) { $worksheet.Cells.Item($row, $wordCol).Text.Trim() } else { "" }
            $posVal = if ($posCol -gt 0) { $worksheet.Cells.Item($row, $posCol).Text.Trim() } else { "" }
            $transVal = if ($transCol -gt 0) { $worksheet.Cells.Item($row, $transCol).Text.Trim() } else { "" }
            
            if ([string]::IsNullOrWhiteSpace($wordVal) -or $wordVal -match '^(單字|word|級別|level)$') {
                continue
            }
            
            # Parse level
            $level = 0
            if ($levelVal -match '^\d+$') {
                $level = [int]$levelVal
                if ($level -ge 1 -and $level -le 6) {
                    $currentLevel = $level
                }
            } elseif ($levelVal -match '[一1]') { $level = 1; $currentLevel = 1 }
            elseif ($levelVal -match '[二2]') { $level = 2; $currentLevel = 2 }
            elseif ($levelVal -match '[三3]') { $level = 3; $currentLevel = 3 }
            elseif ($levelVal -match '[四4]') { $level = 4; $currentLevel = 4 }
            elseif ($levelVal -match '[五5]') { $level = 5; $currentLevel = 5 }
            elseif ($levelVal -match '[六6]') { $level = 6; $currentLevel = 6 }
            
            if ($level -eq 0) { $level = $currentLevel }
            
            # Extract base word
            $baseWord = $wordVal -replace '\([^)]+\)', ''
            if ($baseWord -match '/') {
                $baseWord = ($baseWord -split '/')[0]
            }
            $baseWord = $baseWord.Trim().ToLower()
            
            if ([string]::IsNullOrWhiteSpace($baseWord)) {
                $skipped++
                continue
            }
            
            # If POS is in word field (e.g., "a/an art.")
            if ([string]::IsNullOrWhiteSpace($posVal) -and $wordVal -match '^(.+?)\s+([a-z\.\/\(\)]+)$') {
                $baseWord = $matches[1].Trim().ToLower()
                $posVal = $matches[2].Trim()
            }
            
            # Generate Cambridge URL
            $urlWord = $baseWord -replace '[^\w\-]', ''
            $cambridgeUrl = "https://dictionary.cambridge.org/dictionary/english-chinese-traditional/$urlWord"
            
            $wordObj = @{
                word = $baseWord
                translation = $transVal
                partOfSpeech = $posVal
                exampleEn = ""
                exampleZh = ""
                cambridgeUrl = $cambridgeUrl
                level = $level
                audioUrl = ""
            }
            
            $words += $wordObj
            
            if ($words.Count % 100 -eq 0) {
                Write-Host "  Processed $($words.Count) words..." -ForegroundColor DarkGray
            }
        } catch {
            $skipped++
        }
    }
    
    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    
    # Statistics
    $levelCounts = @{}
    foreach ($w in $words) {
        $lvl = $w.level
        if (-not $levelCounts.ContainsKey($lvl)) {
            $levelCounts[$lvl] = 0
        }
        $levelCounts[$lvl]++
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Total words: $($words.Count)" -ForegroundColor Green
    Write-Host "Skipped: $skipped" -ForegroundColor Yellow
    foreach ($lvl in ($levelCounts.Keys | Sort-Object)) {
        Write-Host "Level $lvl : $($levelCounts[$lvl]) words" -ForegroundColor Cyan
    }
    Write-Host "========================================" -ForegroundColor Green
    
    # Save JSON
    $json = $words | ConvertTo-Json -Depth 10
    
    $outputDir = Split-Path -Parent $outputFile
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($outputFile, $json, $utf8NoBom)
    
    Write-Host ""
    Write-Host "[OK] Saved to: $outputFile" -ForegroundColor Green
    $fileSize = (Get-Item $outputFile).Length / 1KB
    Write-Host "File size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please restart Flutter app to see all words!" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try:" -ForegroundColor Yellow
    Write-Host "1. Save Excel as CSV manually" -ForegroundColor Cyan
    Write-Host "2. Run: python process_csv.py" -ForegroundColor Cyan
    if ($excel) {
        try { $excel.Quit() } catch {}
    }
    exit 1
}

