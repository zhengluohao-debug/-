# PowerShell 腳本：從 Excel 文件生成 words.json
# 需要安裝 ImportExcel 模組: Install-Module -Name ImportExcel

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$excelFile = "C:\Users\zheng\Downloads\學測6000字.xlsx"
$outputFile = Join-Path (Join-Path (Split-Path -Parent $scriptDir) "assets") "data\words.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    從 Excel 生成 words.json" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查 Excel 文件
if (-not (Test-Path $excelFile)) {
    Write-Host "[×] 找不到 Excel 文件: $excelFile" -ForegroundColor Red
    exit 1
}

Write-Host "[√] 找到 Excel 文件" -ForegroundColor Green

# 檢查是否安裝了 ImportExcel 模組
$importExcelInstalled = Get-Module -ListAvailable -Name ImportExcel
if (-not $importExcelInstalled) {
    Write-Host "[!] 需要安裝 ImportExcel 模組" -ForegroundColor Yellow
    Write-Host "正在安裝..." -ForegroundColor Cyan
    try {
        Install-Module -Name ImportExcel -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Host "[√] 安裝成功" -ForegroundColor Green
    } catch {
        Write-Host "[×] 安裝失敗: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "請手動運行: Install-Module -Name ImportExcel -Scope CurrentUser" -ForegroundColor Yellow
        exit 1
    }
}

Import-Module ImportExcel

Write-Host "正在讀取 Excel 文件..." -ForegroundColor Cyan
try {
    $data = Import-Excel -Path $excelFile -NoHeader:$false
    Write-Host "[√] 成功讀取，共 $($data.Count) 行" -ForegroundColor Green
    
    # 顯示前幾行和欄位
    Write-Host ""
    Write-Host "欄位名稱:" -ForegroundColor Cyan
    $data[0].PSObject.Properties.Name | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    Write-Host ""
    
    if ($data.Count -gt 0) {
        Write-Host "前 3 行數據:" -ForegroundColor Cyan
        for ($i = 0; $i -lt [Math]::Min(3, $data.Count); $i++) {
            Write-Host "  行 $($i+1):" -ForegroundColor Gray
            $data[$i].PSObject.Properties | ForEach-Object {
                Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host "[ERROR] Failed to read Excel: $errorMsg" -ForegroundColor Red
    exit 1
}

# 識別欄位
$columns = $data[0].PSObject.Properties.Name
$levelCol = $null
$wordCol = $null
$posCol = $null
$transCol = $null

foreach ($col in $columns) {
    $colLower = $col.ToLower()
    if ($col -match '級' -or $colLower -match 'level') {
        $levelCol = $col
    }
    if ($col -match '單字' -or $colLower -match '^word') {
        $wordCol = $col
    }
    if ($col -match '屬性|詞性' -or $colLower -match 'pos|part') {
        $posCol = $col
    }
    if ($col -match '中文|翻譯' -or $colLower -match 'translation|chinese') {
        $transCol = $col
    }
}

# 如果找不到，使用位置推測
if (-not $levelCol -and $columns.Count -ge 1) {
    $levelCol = $columns[0]
}
if (-not $wordCol -and $columns.Count -ge 2) {
    $wordCol = $columns[1]
}
if (-not $posCol -and $columns.Count -ge 3) {
    $posCol = $columns[2]
}
if (-not $transCol -and $columns.Count -ge 5) {
    $transCol = $columns[4]
} elseif (-not $transCol -and $columns.Count -ge 4) {
    $transCol = $columns[3]
}

Write-Host "識別的欄位:" -ForegroundColor Cyan
Write-Host "  級別: $levelCol" -ForegroundColor Gray
Write-Host "  單字: $wordCol" -ForegroundColor Gray
Write-Host "  詞性: $posCol" -ForegroundColor Gray
Write-Host "  翻譯: $transCol" -ForegroundColor Gray
Write-Host ""

if (-not $wordCol) {
    Write-Host "[×] 無法識別單字欄位" -ForegroundColor Red
    exit 1
}

Write-Host "正在處理數據..." -ForegroundColor Cyan

$words = @()
$skipped = 0
$currentLevel = 1

function Parse-Level {
    param([string]$levelStr)
    if ([string]::IsNullOrWhiteSpace($levelStr)) {
        return 0
    }
    if ($levelStr -match '^\d+$') {
        $level = [int]$levelStr
        if ($level -ge 1 -and $level -le 6) {
            return $level
        }
    }
    if ($levelStr -match '[一1]') { return 1 }
    if ($levelStr -match '[二2]') { return 2 }
    if ($levelStr -match '[三3]') { return 3 }
    if ($levelStr -match '[四4]') { return 4 }
    if ($levelStr -match '[五5]') { return 5 }
    if ($levelStr -match '[六6]') { return 6 }
    return 0
}

function Extract-BaseWord {
    param([string]$word)
    if ([string]::IsNullOrWhiteSpace($word)) {
        return ""
    }
    $word = $word -replace '\([^)]+\)', ''
    if ($word -match '/') {
        $word = ($word -split '/')[0]
    }
    return $word.Trim().ToLower()
}

foreach ($row in $data) {
    try {
        # 獲取級別
        $level = 0
        if ($levelCol) {
            $level = Parse-Level ([string]$row.$levelCol)
        }
        
        # 獲取單字
        $word = ""
        if ($wordCol) {
            $word = [string]$row.$wordCol
            if ([string]::IsNullOrWhiteSpace($word)) {
                continue
            }
            $word = $word.Trim()
        }
        
        # 跳過標題行
        if ($word -match '^(單字|word|級別|level)$' -or [string]::IsNullOrWhiteSpace($word)) {
            continue
        }
        
        # 如果單字包含級別信息
        if ($word -match '第[一二三四五六123456]級') {
            $level = Parse-Level $word
            continue
        }
        
        # 如果級別為 0，使用當前級別
        if ($level -eq 0) {
            $level = $currentLevel
        } else {
            $currentLevel = $level
        }
        
        # 獲取詞性
        $pos = ""
        if ($posCol) {
            $pos = [string]$row.$posCol
            if (-not [string]::IsNullOrWhiteSpace($pos)) {
                $pos = $pos.Trim()
            }
        }
        
        # 如果詞性在單字欄位中（如 "a/an art."）
        if ([string]::IsNullOrWhiteSpace($pos) -and $word -match '^(.+?)\s+([a-z\.\/\(\)]+)$') {
            $word = $matches[1].Trim()
            $pos = $matches[2].Trim()
        }
        
        # 獲取翻譯
        $translation = ""
        if ($transCol) {
            $translation = [string]$row.$transCol
            if (-not [string]::IsNullOrWhiteSpace($translation)) {
                $translation = $translation.Trim()
            }
        }
        
        # 提取基本單字
        $baseWord = Extract-BaseWord $word
        if ([string]::IsNullOrWhiteSpace($baseWord) -or $baseWord.Length -lt 1) {
            $skipped++
            continue
        }
        
        # 生成 Cambridge URL
        $urlWord = $baseWord -replace '[^\w\-]', ''
        $cambridgeUrl = "https://dictionary.cambridge.org/dictionary/english-chinese-traditional/$urlWord"
        
        $wordObj = @{
            word = $baseWord
            translation = $translation
            partOfSpeech = $pos
            exampleEn = ""
            exampleZh = ""
            cambridgeUrl = $cambridgeUrl
            level = $level
            audioUrl = ""
        }
        
        $words += $wordObj
    } catch {
        $skipped++
        if ($skipped -le 5) {
            Write-Host "  跳過行: $_" -ForegroundColor Yellow
        }
    }
}

# 統計
$levelCounts = @{}
foreach ($w in $words) {
    $level = $w.level
    if (-not $levelCounts.ContainsKey($level)) {
        $levelCounts[$level] = 0
    }
    $levelCounts[$level]++
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "共解析 $($words.Count) 個單字" -ForegroundColor Green
Write-Host "跳過 $skipped 行" -ForegroundColor Yellow
foreach ($level in ($levelCounts.Keys | Sort-Object)) {
    Write-Host "第$level 級: $($levelCounts[$level]) 個" -ForegroundColor Cyan
}
Write-Host "========================================" -ForegroundColor Green

# 轉換為 JSON
$json = $words | ConvertTo-Json -Depth 10

# 確保輸出目錄存在
$outputDir = Split-Path -Parent $outputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 保存 JSON（使用 UTF-8 編碼，無 BOM）
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($outputFile, $json, $utf8NoBom)

Write-Host ""
Write-Host "[√] 已保存到: $outputFile" -ForegroundColor Green
$fileSize = (Get-Item $outputFile).Length / 1KB
Write-Host "文件大小: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please restart Flutter app to see all words" -ForegroundColor Yellow
Write-Host ""

