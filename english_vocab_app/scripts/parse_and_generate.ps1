# PowerShell 腳本來解析單字列表並生成 JSON
# 由於 Python 可能未安裝，使用 PowerShell 處理

$inputFile = "words_input.txt"
$outputFile = "../assets/data/words.json"

if (-not (Test-Path $inputFile)) {
    Write-Host "錯誤: 找不到 $inputFile"
    exit 1
}

$content = Get-Content $inputFile -Raw -Encoding UTF8
$lines = $content -split "`n"
$words = @()
$currentLevel = 0

foreach ($line in $lines) {
    $line = $line.Trim()
    
    if ($line -match "第一級|第1級") {
        $currentLevel = 1
        continue
    }
    elseif ($line -match "第二級|第2級") {
        $currentLevel = 2
        continue
    }
    elseif ($line -match "第三級|第3級") {
        $currentLevel = 3
        continue
    }
    elseif ($line -match "第四級|第4級") {
        $currentLevel = 4
        continue
    }
    elseif ($line -match "第五級|第5級") {
        $currentLevel = 5
        continue
    }
    elseif ($line -match "第六級|第6級") {
        $currentLevel = 6
        continue
    }
    
    if ([string]::IsNullOrWhiteSpace($line) -or $line -match "級") {
        continue
    }
    
    if ($currentLevel -gt 0 -and $line -match "^([a-zA-Z\-\'\/\s\(\)]+?)\s+([a-z\.\/\(\)]+)$") {
        $wordPart = $matches[1].Trim()
        $posPart = $matches[2].Trim()
        
        # 提取基本單字
        if ($wordPart -match "/") {
            $wordPart = $wordPart.Split("/")[0]
        }
        $wordPart = $wordPart -replace "\([^)]+\)", ""
        $baseWord = $wordPart.Trim().ToLower()
        
        if ($baseWord.Length -gt 0) {
            $cambridgeUrl = "https://dictionary.cambridge.org/dictionary/english-chinese-traditional/$baseWord"
            
            $wordObj = @{
                word = $baseWord
                translation = ""
                partOfSpeech = $posPart
                exampleEn = ""
                exampleZh = ""
                cambridgeUrl = $cambridgeUrl
                level = $currentLevel
                audioUrl = ""
            }
            $words += $wordObj
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

Write-Host "共 $($words.Count) 個單字"
foreach ($level in ($levelCounts.Keys | Sort-Object)) {
    Write-Host "第$level 級: $($levelCounts[$level]) 個"
}

# 轉換為 JSON
$json = $words | ConvertTo-Json -Depth 10 -Compress:$false

# 保存文件
$json | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline

Write-Host "已保存到 $outputFile"

