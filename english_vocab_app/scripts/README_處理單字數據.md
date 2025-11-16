# 如何處理完整的單字列表

## 步驟

1. **將您提供的單字數據保存到文件**
   - 文件路徑：`english_vocab_app/scripts/vocab_data.txt`
   - 格式：級別\t單字\t屬性\t輸出\t中文
   - 例如：
     ```
     1	a/an	art.	a/an (art.)	一個/一個
     1	ability	n.	ability (n.)	能力
     ```

2. **運行處理腳本**

   **方法 A：使用 PowerShell（推薦）**
   ```powershell
   cd C:\AI\english_vocab_app\scripts
   .\process_vocab_data.ps1
   ```

   **方法 B：使用 Python（如果已安裝）**
   ```bash
   cd C:\AI\english_vocab_app\scripts
   python parse_complete_vocab.py
   ```

3. **檢查結果**
   - 生成的 JSON 文件：`english_vocab_app/assets/data/words.json`
   - 應該包含所有 6 個級別的單字

## 注意事項

- 確保數據格式正確（tab 分隔）
- 如果遇到編碼問題，請使用 UTF-8 編碼保存文件
- 處理完成後，重新運行 Flutter 應用程序

