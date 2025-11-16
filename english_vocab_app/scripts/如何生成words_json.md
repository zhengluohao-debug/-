# 如何生成 words.json

## 問題
目前應用程式只顯示 5 個單字，因為 `assets/data/words.json` 文件不存在。

## 解決方法

### 方法 1：使用 Excel 文件（推薦）

1. **確認 Excel 文件位置**
   - 文件應該在：`C:\Users\zheng\Downloads\學測6000字.xlsx`

2. **將 Excel 另存為 CSV**
   - 打開 Excel 文件
   - 點擊「檔案」→「另存新檔」
   - 選擇「CSV (逗號分隔) (*.csv)」
   - 保存為 `C:\AI\english_vocab_app\scripts\vocab_data.csv`

3. **運行處理腳本**
   - 打開 PowerShell 或命令提示字元
   - 執行：
     ```powershell
     cd C:\AI\english_vocab_app\scripts
     python process_csv.py
     ```

### 方法 2：直接使用 Python 處理 Excel

如果已安裝 Python 和 pandas：

```powershell
cd C:\AI\english_vocab_app\scripts
pip install pandas openpyxl
python process_excel.py
```

### 方法 3：手動創建（不推薦，因為單字太多）

如果以上方法都無法使用，可以手動編輯 `assets/data/words.json`，但這會非常耗時。

## 檢查結果

處理完成後，檢查文件是否生成：

```powershell
cd C:\AI\english_vocab_app\assets\data
if (Test-Path words.json) {
    Write-Host "成功！words.json 已生成"
} else {
    Write-Host "失敗：words.json 未生成"
}
```

## 重新運行應用程式

生成 `words.json` 後，重新運行 Flutter 應用程式：

```bash
cd C:\AI\english_vocab_app
flutter run
```

應用程式應該會顯示所有單字，而不只是 5 個。

