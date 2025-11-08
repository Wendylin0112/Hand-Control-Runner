# 👋 Hand-Control Runner — 用手勢玩遊戲的 MATLAB 小專案

把你的手變成控制器！這個專案示範如何在 **MATLAB** 裡用 **Python Mediapipe** 偵測手部關鍵點，並把手勢即時轉換成方向鍵輸出，讓你能夠直接在電腦上用手勢控制遊戲。非常適合課堂 Demo、社團活動、校園迎新派對～

> 歡迎大家下載體驗，享受影像處理與人機互動的樂趣！

---

## 📖 目錄
1. [專案介紹](#-專案介紹)
2. [下載教學](#-下載教學)
   - [專案結構](#-專案結構)
   - [MATLAB 與環境需求](#-matlab-與環境需求)
   - [Python Mediapipe 環境設定](#-python-mediapipe-環境設定)
   - [常見問題](#-常見問題)
3. [開始遊玩](#-開始遊玩)
   - [測試是否正常運作](#-測試是否正常運作)
   - [推薦的遊戲](#-推薦的遊戲)
4. [Demo](#-demo)
4. [程式碼介紹與說明](#-程式碼介紹與說明)
   - [參考來源](#-參考來源)
   - [程式架構說明](#-程式架構說明)
   - [主要參數設定](#-主要參數設定)
5. [授權與聲明](#-授權與聲明)

---

## 💡 專案介紹

**Hand-Control Runner** 是一個結合 **MATLAB** 影像處理 與 **Python Mediapipe** 深度學習手部關鍵點模型 的互動式專案。
它讓使用者可以透過電腦鏡頭即時辨識手部姿勢，並將手勢自動轉換為電腦的「方向鍵輸入」，達成「用手勢玩遊戲」的效果 🎮。

這個專案的初衷是讓沒有程式背景的使用者，也能輕鬆體驗影像處理的樂趣。
只要一台筆電、一個鏡頭、幾行 MATLAB 程式，就能感受到「AI 感知」與「人機互動」結合的魅力。

在技術層面上，本專案：

- 使用 Mediapipe Hands 模型來偵測 21 個手部關鍵點（包含手指節與手掌中心）；

- 以 MATLAB 負責攝影機擷取、視覺化顯示與 GUI 更新；

- 並以 控制鍵模組 (controlkeys) 模擬方向鍵輸出，讓使用者可以用手勢操作遊戲。

這個專案特別適合：

- 🎓 學生與初學者 — 想了解 AI 影像辨識與 MATLAB 整合；

- 🧠 教學展示 — 可作為影像處理、Python 整合或人機互動的實驗範例；

- 🎉 校園活動 / 社團互動 — 讓參加者用自己的手來「操控遊戲角色」；

- 💻 AI / Vision 入門者 — 快速體驗 Mediapipe 模型與 MATLAB 影像處理的實作流程。

在實際使用時，你可以將此系統應用於任何以方向鍵控制的遊戲，例如 Poki 網站上的 Subway Surfers 或 Hill Climb Racing Lite，甚至也可以下載本機遊戲（如 Hill Climb Racing）進行體驗。

簡單來說，這是一個能讓你「揮揮手就能玩遊戲」的 MATLAB 小專案 — 讓你同時感受到 AI、影像處理與互動科技的結合 🚀

---

## 💾 下載教學

### 📁 專案結構

```
project/
├─ main.m                     % 主程式
└─ README.md
```

### ⚙ MATLAB 與環境需求

- **MATLAB**：R2022b 或以上（建議 R2023b/R2024a）  
- **Toolboxes / Support Packages**
  - Image Processing Toolbox（`insertShape`, `imresize`, `imshow`）
  - *MATLAB Support Package for USB Webcams*（相機驅動）
  - （可選）Computer Vision Toolbox（非必須）
- **作業系統**：Windows / macOS（Windows 測試最完整）
- **相機**：USB/內建鏡頭

### 🐍 Python Mediapipe 環境設定

1️⃣ 在 MATLAB 指令列輸入：
```matlab
pyenv
```
記下 `Version:` 顯示的 Python 路徑，例如：  
`C:\Users\USER\AppData\Local\Programs\Python\Python310\python.exe`

2️⃣ 在該 Python 環境中安裝依賴：
```bash
"C:\Users\USER\AppData\Local\Programs\Python\Python310\python.exe" -m pip install mediapipe==0.10.21 opencv-python numpy protobuf==4.25.8
```

> 📌 必須安裝到 MATLAB 正在使用的 Python！  
> 若不確定，請執行 `pyenv` 再確認。  

### ❓ 常見問題

**Q1. `ModuleNotFoundError: No module named 'mediapipe'`**  
→ 請確認你把套件安裝到 MATLAB 正在使用的 Python。

**Q2. 相機畫面卡住或 FPS 過低**  
→ 降低解析度、設定 `model_complexity=0`、保持良好照明。

**Q3. 手勢偵測靈敏度太高/太低**  
→ 調整 `deltaY`, `deltaX_strict` 或手勢門檻。

**Q4. 左右顛倒**  
→ 設定 `SELFIE_FLIP = true` 或 `SWAP_LR = true`。

**Q5. 關閉攝影機**  
→ 關閉視窗或輸入：  
```matlab
clear cam; close all;
```

---

## 🎮 開始遊玩

### 🧪 測試是否正常運作

1. 開啟 MATLAB，允許相機權限。  
2. 執行：
   ```matlab
   main
   ```
3. 若看到相機畫面與 21 個青色關節點，表示已成功啟動 Mediapipe。  
4. 對鏡頭做以下動作進行測試，螢幕框中應顯示目前偵測到的方向：
右手打開（顯示RIGH）、左手打開（顯示LEFT）、伸出食指比1（顯示UP）、握拳（顯示DOWN）
5. 同時開啟任何使用方向鍵的遊戲進行測試。  

### 🎮 推薦的遊戲

因為專案會輸出方向鍵訊號，你可以玩任何用方向鍵控制的遊戲。  
這裡推薦幾個好玩又容易上手的 Poki 網頁遊戲👇

| 平台 | 遊戲名稱 | 連結 |
|------|-----------|------|
| 🌐 **Poki 網站** | Subway Surfers | https://poki.com/en/g/subway-surfers |
| 🌐 **Poki 網站** | Hill Climb Racing Lite | https://poki.com/zh/g/hill-climb-racing-lite |

> 這兩款遊戲都能在瀏覽器中直接玩、使用方向鍵操作角色。  
> 你也可以上 [https://poki.com](https://poki.com) 找其他有趣的遊戲來測試。  

如果希望有更順暢的體驗，也可以前往 **Microsoft Store** 搜尋並下載遊戲版本。  
> 我自己是下載 *Hill Climb Racing* 來測試的喔 🚗💨

---

## 🎥 Demo（暫時無法）
以下為本專案的實際操作與遊玩示範影片：

抱歉由於一些技術上的問題目前無法將放影片上來
🎬 [點此觀看 Demo 影片](Demo%20game.mp4)

---

## 🧠 程式碼介紹與說明

### 📚 參考來源
本專案的手勢邏輯與程式設計概念部分參考自：  
**GestureKeyboardController** by Ojas Mittal  
🔗 https://github.com/OjasMittal/GestureKeyboardController  

感謝原作者的開源分享與啟發 🙏

### 🧩 程式架構說明

主要程式 `main.m` 負責：
1. 初始化相機、Mediapipe Python 環境  
2. 即時擷取影像 → 傳給 Mediapipe  
3. 解析 landmarks → 判斷手勢  
4. 轉換為方向鍵控制（透過 `controlkeys` 模組）  
5. 即時在 MATLAB 圖窗上顯示畫面與偵測結果  

手勢判斷邏輯（簡化版本）：
- 伸出 1 指 → UP  
- 沒有伸出手指 → DOWN  
- 張開手（4–5 指）→  
  - 右手 → RIGHT  
  - 左手 → LEFT

### ⚙ 主要參數設定

| 參數名稱 | 說明 | 預設值 |
|-----------|------|---------|
| `USE_PY_MEDIAPIPE` | 是否啟用 Python Mediapipe | `true` |
| `cam.Resolution` | 攝影機解析度 | `'640x480'` |
| `max_num_hands` | 偵測手數量 | `1` |
| `model_complexity` | 模型複雜度（0 最快） | `0` |
| `SELFIE_FLIP` | 是否鏡像反轉畫面 | `true` |
| `SWAP_LR` | 左右手顛倒修正 | `false` |
| `DOWNSCALE` | 影像縮放比例（加速推論） | `0.6` |
| `targetFPS` | GUI 更新幀率 | `30` |

---

## ⚖ 授權與聲明

- 本專案僅供學術、教學與個人研究用途。

---

## 🎉 一起玩影像處理吧！

歡迎大家下載體驗、二創擴充、甚至把它帶到你的課堂或社群活動中～
如果你玩得開心或做了更酷的延伸版本，也歡迎在 GitHub 上分享！

Have fun, and enjoy coding with MATLAB + Mediapipe 👋