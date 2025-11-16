# PowerShell script to parse vocabulary data and generate words.json
# Format: level`tword`tpart_of_speech`toutput`tchinese_translation

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputFile = Join-Path $scriptDir "vocab_data.txt"
$outputFile = Join-Path (Join-Path (Split-Path -Parent $scriptDir) "assets") "data\words.json"

if (-not (Test-Path $inputFile)) {
    Write-Host "錯誤: 找不到文件 $inputFile" -ForegroundColor Red
    Write-Host "請將單字數據保存到 vocab_data.txt 文件中" -ForegroundColor Yellow
    Write-Host "格式: 級別`t單字`t屬性`t輸出`t中文" -ForegroundColor Yellow
    exit 1
}

Write-Host "讀取數據文件..." -ForegroundColor Green
$lines = Get-Content $inputFile -Encoding UTF8

$words = @()
$skipped = 0

foreach ($line in $lines) {
    $line = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    
    # 嘗試用 tab 分隔
    $parts = $line -split "`t"
    
    # 如果沒有 tab，嘗試用多個空格分隔
    if ($parts.Length -lt 5) {
        $parts = $line -split '\s{2,}'
    }
    
    # 如果還是沒有足夠的部分，嘗試用單個空格分隔（前4個空格）
    if ($parts.Length -lt 5) {
        $parts = $line -split ' ', 5
    }
    
    if ($parts.Length -lt 5) {
        $skipped++
        if ($skipped -le 10) {
            Write-Host "跳過行: $($line.Substring(0, [Math]::Min(60, $line.Length)))..." -ForegroundColor Yellow
        }
        continue
    }
    
    try {
        $levelStr = $parts[0].Trim()
        $word = $parts[1].Trim()
        $partOfSpeech = $parts[2].Trim()
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
        
        # 提取基本單字（去除括號和斜線）
        $baseWord = $word
        $baseWord = $baseWord -replace '\([^)]+\)', ''
        if ($baseWord -match '/') {
            $baseWord = ($baseWord -split '/')[0]
        }
        $baseWord = $baseWord.Trim().ToLower()
        
        # 生成 Cambridge URL
        $urlWord = $baseWord -replace '[^\w\-]', ''
        $cambridgeUrl = "https://dictionary.cambridge.org/dictionary/english-chinese-traditional/$urlWord"
        
        $wordObj = @{
            word = $baseWord
            translation = $translation
            partOfSpeech = $partOfSpeech
            exampleEn = ""
            exampleZh = ""
            cambridgeUrl = $cambridgeUrl
            level = $level
            audioUrl = ""
        }
        
        $words += $wordObj
    } catch {
        $skipped++
        if ($skipped -le 10) {
            Write-Host "解析錯誤: $($_.Exception.Message)" -ForegroundColor Yellow
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

Write-Host "`n共解析 $($words.Count) 個單字" -ForegroundColor Green
foreach ($level in ($levelCounts.Keys | Sort-Object)) {
    Write-Host "第$level 級: $($levelCounts[$level]) 個" -ForegroundColor Cyan
}

# 轉換為 JSON
$json = $words | ConvertTo-Json -Depth 10

# 確保輸出目錄存在
$outputDir = Split-Path -Parent $outputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 保存 JSON（使用 UTF-8 編碼）
[System.IO.File]::WriteAllText($outputFile, $json, [System.Text.Encoding]::UTF8)

Write-Host "`n已保存到 $outputFile" -ForegroundColor Green

