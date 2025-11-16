# PowerShell 腳本：直接生成 words.json
# 支持從文件或直接輸入處理數據

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputFile = Join-Path (Join-Path (Split-Path -Parent $scriptDir) "assets") "data\words.json"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    生成 words.json 文件" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 檢查可能的輸入文件
$inputFiles = @(
    (Join-Path $scriptDir "vocab_data.txt"),
    (Join-Path $scriptDir "words_input.txt")
)

$inputFile = $null
foreach ($file in $inputFiles) {
    if (Test-Path $file) {
        $inputFile = $file
        Write-Host "[√] 找到數據文件: $file" -ForegroundColor Green
        break
    }
}

if (-not $inputFile) {
    Write-Host "[×] 未找到數據文件" -ForegroundColor Red
    Write-Host ""
    Write-Host "請將您的單字數據保存到以下文件之一:" -ForegroundColor Yellow
    foreach ($file in $inputFiles) {
        Write-Host "  - $file" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "數據格式: 級別`t單字`t屬性`t輸出`t中文" -ForegroundColor Yellow
    Write-Host "例如: 1`ta/an`tart.`ta/an (art.)`t一個/一個" -ForegroundColor Yellow
    exit 1
}

Write-Host "正在讀取數據..." -ForegroundColor Cyan
$lines = Get-Content $inputFile -Encoding UTF8

$words = @()
$skipped = 0

Write-Host "正在處理數據..." -ForegroundColor Cyan
foreach ($line in $lines) {
    $line = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('級別')) {
        continue
    }
    
    # 嘗試 tab 分隔
    $parts = $line -split "`t"
    
    # 如果沒有 tab，嘗試多個空格
    if ($parts.Length -lt 5) {
        $parts = $line -split '\s{2,}'
    }
    
    # 如果還是沒有足夠的部分，嘗試用單個空格分隔（前4個空格）
    if ($parts.Length -lt 5) {
        $parts = $line -split ' ', 5
    }
    
    if ($parts.Length -lt 5) {
        $skipped++
        continue
    }
    
    try {
        $levelStr = $parts[0].Trim()
        $word = $parts[1].Trim()
        $pos = $parts[2].Trim()
        $translation = $parts[4].Trim()
        
        # 解析級別
        $level = 0
        if ($levelStr -match '^\d+$') {
            $level = [int]$levelStr
        } elseif ($levelStr -match '[一1]') {
            $level = 1
        } elseif ($levelStr -match '[二2]') {
            $level = 2
        } elseif ($levelStr -match '[三3]') {
            $level = 3
        } elseif ($levelStr -match '[四4]') {
            $level = 4
        } elseif ($levelStr -match '[五5]') {
            $level = 5
        } elseif ($levelStr -match '[六6]') {
            $level = 6
        }
        
        if ($level -eq 0 -or [string]::IsNullOrWhiteSpace($word) -or [string]::IsNullOrWhiteSpace($translation)) {
            $skipped++
            continue
        }
        
        # 提取基本單字
        $baseWord = $word
        $baseWord = $baseWord -replace '\([^)]+\)', ''
        if ($baseWord -match '/') {
            $baseWord = ($baseWord -split '/')[0]
        }
        $baseWord = $baseWord.Trim().ToLower()
        
        if ([string]::IsNullOrWhiteSpace($baseWord)) {
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
    }
}

if ($words.Count -eq 0) {
    Write-Host ""
    Write-Host "[×] 沒有解析到任何單字" -ForegroundColor Red
    Write-Host "請檢查數據文件格式是否正確" -ForegroundColor Yellow
    exit 1
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
Write-Host "請重新運行 Flutter 應用程序以查看所有單字" -ForegroundColor Yellow
Write-Host ""



