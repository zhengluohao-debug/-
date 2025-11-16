# 快速生成 words.json

## 問題
應用程式只顯示 5 個單字，因為 `words.json` 文件不存在。

## 最簡單的解決方法

### 方法 1：使用 Excel 另存為 CSV（推薦，最簡單）

1. **打開 Excel 文件**
   - 文件位置：`C:\Users\zheng\Downloads\學測6000字.xlsx`
   - 雙擊打開

2. **另存為 CSV**
   - 點擊「檔案」→「另存新檔」
   - 選擇「CSV (逗號分隔) (*.csv)」
   - 文件名：`vocab_data.csv`
   - 保存位置：`C:\AI\english_vocab_app\scripts\vocab_data.csv`
   - 點擊「儲存」

3. **安裝 Python**（如果還沒安裝）
   - 下載：https://www.python.org/downloads/
   - 安裝時**務必勾選**「Add Python to PATH」
   - 安裝完成後，重新開啟命令提示字元

4. **運行處理腳本**
   - 打開命令提示字元（cmd）或 PowerShell
   - 執行：
     ```bash
     cd C:\AI\english_vocab_app\scripts
     python process_csv.py
     ```

5. **完成！**
   - 腳本會自動生成 `C:\AI\english_vocab_app\assets\data\words.json`
   - 重新運行 Flutter 應用程式即可看到所有單字

---

### 方法 2：直接處理 Excel（需要 Python + pandas）

1. **安裝 Python**
   - 下載：https://www.python.org/downloads/
   - 安裝時**務必勾選**「Add Python to PATH」

2. **安裝 pandas**
   - 打開命令提示字元
   - 執行：
     ```bash
     pip install pandas openpyxl
     ```

3. **運行處理腳本**
   ```bash
     cd C:\AI\english_vocab_app\scripts
     python process_excel.py
     ```

---

### 方法 3：使用在線工具

如果無法安裝 Python，可以使用在線工具：

1. 將 Excel 文件上傳到：https://convertio.co/zh/xlsx-csv/
2. 轉換為 CSV
3. 下載 CSV 文件
4. 將 CSV 文件保存到：`C:\AI\english_vocab_app\scripts\vocab_data.csv`
5. 然後按照方法 1 的步驟 4 運行腳本

---

## 檢查結果

處理完成後，檢查文件是否生成：

```powershell
cd C:\AI\english_vocab_app\assets\data
if (Test-Path words.json) {
    Write-Host "成功！words.json 已生成"
    $json = Get-Content words.json | ConvertFrom-Json
    Write-Host "共 $($json.Count) 個單字"
} else {
    Write-Host "失敗：words.json 未生成"
}
```

---

## 重新運行應用程式

生成 `words.json` 後，重新運行 Flutter 應用程式：

```bash
cd C:\AI\english_vocab_app
flutter run
```

應用程式應該會顯示所有單字，而不只是 5 個。

---

## 遇到問題？

如果遇到任何問題，請檢查：

1. ✅ Python 是否已安裝？
   - 運行 `python --version` 應該顯示版本號

2. ✅ Python 是否在 PATH 中？
   - 如果 `python` 命令找不到，需要重新安裝 Python 並勾選「Add Python to PATH」

3. ✅ pandas 是否已安裝？
   - 運行 `pip list | findstr pandas` 應該顯示 pandas

4. ✅ CSV 文件是否在正確位置？
   - 應該是：`C:\AI\english_vocab_app\scripts\vocab_data.csv`

5. ✅ Excel 文件是否存在？
   - 應該是：`C:\Users\zheng\Downloads\學測6000字.xlsx`

