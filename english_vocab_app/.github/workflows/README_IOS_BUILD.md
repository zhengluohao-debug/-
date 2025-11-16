# iOS IPA 構建說明

本項目包含兩個 GitHub Actions workflow 用於構建 iOS IPA：

## 1. ios-build-simple.yml（簡單版本，無需證書）

**適用於**：測試構建、開發階段

**特點**：
- ✅ 無需配置證書和配置文件
- ✅ 構建未簽名的 IPA（可用於測試）
- ✅ 自動上傳構建產物

**使用方法**：
1. 推送代碼到 `main` 或 `master` 分支
2. 或在 GitHub Actions 頁面手動觸發 workflow
3. 構建完成後在 Artifacts 中下載 IPA

## 2. ios-build.yml（完整版本，需要證書）

**適用於**：正式發布、App Store 提交

**特點**：
- ✅ 需要配置證書和配置文件
- ✅ 構建已簽名的 IPA（可用於發布）
- ✅ 自動上傳到 GitHub Release（如果是 tag）

### 配置步驟

#### 1. 準備證書和配置文件

從 Apple Developer 下載：
- **證書**：`.p12` 格式的開發者證書
- **配置文件**：`.mobileprovision` 格式的配置文件

#### 2. 轉換為 Base64

在本地執行：

```bash
# 轉換證書
base64 -i YourCertificate.p12 | pbcopy

# 轉換配置文件
base64 -i YourProfile.mobileprovision | pbcopy
```

#### 3. 配置 GitHub Secrets

在 GitHub 倉庫設置中添加以下 Secrets：

- `APPLE_CERTIFICATE_BASE64`: 證書的 Base64 編碼（從步驟 2 複製）
- `APPLE_CERTIFICATE_PASSWORD`: 證書密碼
- `APPLE_PROVISIONING_PROFILE_BASE64`: 配置文件的 Base64 編碼（從步驟 2 複製）
- `KEYCHAIN_PASSWORD`: 臨時 keychain 密碼（可以隨意設置，如 "temp123"）

#### 4. 更新 ExportOptions.plist

編輯 `ios/ExportOptions.plist`：
- 將 `YOUR_TEAM_ID` 替換為您的 Apple Team ID
- 將 `com.example.englishVocabApp` 替換為您的 Bundle ID
- 將 `YOUR_PROVISIONING_PROFILE_NAME` 替換為配置文件的名稱

#### 5. 觸發構建

- 推送代碼到 `main` 或 `master` 分支
- 或創建一個 tag（如 `v1.0.0`）來自動發布到 Release

## 構建產物

構建完成後，IPA 文件會：
1. 上傳到 GitHub Actions Artifacts（可下載）
2. 如果是 tag，自動上傳到 GitHub Release

## 常見問題

### Q: 構建失敗，提示找不到證書？
A: 檢查 GitHub Secrets 是否正確配置，確保 Base64 編碼正確。

### Q: 構建成功但 IPA 無法安裝？
A: 未簽名的 IPA 無法直接安裝到設備。需要使用完整版本（ios-build.yml）或使用 Xcode 手動簽名。

### Q: 如何更新 Flutter 版本？
A: 編輯 workflow 文件中的 `flutter-version` 字段。

### Q: 構建時間太長？
A: 啟用了 `cache: true`，首次構建會較慢，後續構建會使用緩存。

## 本地構建

如果想在本地構建：

```bash
# 安裝依賴
flutter pub get
cd ios
pod install
cd ..

# 構建 IPA（無簽名）
flutter build ipa --release --no-codesign

# 構建 IPA（有簽名，需要配置 Xcode）
flutter build ipa --release
```

IPA 文件會在 `build/ios/ipa/` 目錄中。

