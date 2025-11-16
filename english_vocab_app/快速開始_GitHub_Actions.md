# 🚀 快速開始：使用 GitHub Actions 構建 iOS IPA

## 第一步：準備 Git 倉庫

如果還沒有將代碼推送到 GitHub：

```bash
# 1. 進入項目目錄
cd C:\AI\english_vocab_app

# 2. 初始化 Git（如果還沒有）
git init

# 3. 添加所有文件
git add .

# 4. 提交
git commit -m "Add iOS build workflow"

# 5. 添加遠程倉庫（替換為您的 GitHub 倉庫 URL）
git remote add origin https://github.com/您的用戶名/english_vocab_app.git

# 6. 推送到 GitHub
git push -u origin main
```

## 第二步：觸發構建

### 選項 A：自動觸發（已推送代碼）

如果您已經推送了代碼，workflow 會自動運行。

### 選項 B：手動觸發

1. 打開瀏覽器，訪問您的 GitHub 倉庫
2. 點擊頂部的 **"Actions"** 標籤
3. 在左側選擇 **"Build iOS IPA (Simple - No Code Signing)"**
4. 點擊右側的 **"Run workflow"** 按鈕
5. 選擇分支（通常是 `main`）
6. 點擊綠色的 **"Run workflow"** 按鈕

## 第三步：查看構建進度

1. 在 Actions 頁面，您會看到構建任務
2. 點擊任務查看詳細進度
3. 等待構建完成（通常 10-20 分鐘）

## 第四步：下載 IPA

構建成功後：

1. 點擊構建任務（綠色 ✓ 標記）
2. 滾動到頁面底部
3. 在 **"Artifacts"** 區域找到 **"ios-ipa-unsigned"**
4. 點擊下載 ZIP 文件
5. 解壓後即可得到 `.ipa` 文件

## 📸 視覺化步驟

### 1. 找到 Actions 頁面
```
GitHub 倉庫首頁
    ↓
點擊 "Actions" 標籤
```

### 2. 選擇 Workflow
```
Actions 頁面
    ↓
左側：選擇 "Build iOS IPA (Simple - No Code Signing)"
    ↓
右側：點擊 "Run workflow"
```

### 3. 查看構建
```
構建任務列表
    ↓
點擊正在運行的任務
    ↓
查看每個步驟的進度
```

### 4. 下載 IPA
```
構建完成（綠色 ✓）
    ↓
滾動到底部
    ↓
Artifacts → ios-ipa-unsigned
    ↓
下載 ZIP 文件
```

## ⚡ 快速檢查清單

在開始之前，確認：

- [ ] 代碼已推送到 GitHub
- [ ] `.github/workflows/ios-build-simple.yml` 文件存在
- [ ] 有 GitHub 帳號並可以訪問倉庫
- [ ] 有耐心等待 10-20 分鐘構建完成

## 🆘 遇到問題？

### 問題：找不到 "Actions" 標籤
**解決**：確認您有倉庫的訪問權限

### 問題：找不到 workflow
**解決**：確認 `.github/workflows/ios-build-simple.yml` 文件已提交

### 問題：構建失敗
**解決**：
1. 點擊構建任務查看錯誤
2. 檢查日誌中的紅色錯誤信息
3. 根據錯誤信息修復問題

### 問題：找不到 Artifacts
**解決**：
1. 確認構建確實成功（綠色標記）
2. 等待幾分鐘，Artifacts 可能需要時間生成
3. 刷新頁面

## 📞 需要幫助？

如果遇到問題，可以：
1. 查看構建日誌中的錯誤信息
2. 參考 `.github/workflows/使用說明.md`
3. 檢查 GitHub Actions 文檔



