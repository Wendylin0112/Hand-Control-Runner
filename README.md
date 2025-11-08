# 👋 Hand-Control Runner — 用手勢玩遊戲的 MATLAB 小專案

把你的手變成控制器！這個專案示範如何在 **MATLAB** 裡用 **Python Mediapipe** 偵測手部關鍵點，並把手勢即時轉換成方向鍵輸出，讓你能夠直接在電腦上用手勢控制遊戲。非常適合課堂 Demo、社團活動、校園迎新派對～

> 歡迎大家下載體驗，享受影像處理與人機互動的樂趣！

---

## ✨ 功能亮點

- 即時相機畫面 + 21 點手部關節疊圖  
- Mediapipe Hands（Python）整合 MATLAB  
- 手勢 → 鍵盤方向鍵控制（可用於任何支援方向鍵的遊戲）  
- 低延遲優化：縮圖推論、GUI 限速刷新、穩定視覺化  
- 可切換自拍鏡像、自動判別左右手、手勢門檻可調

---

## 🗂 專案結構

```
project/
├─ main.m                     % 主程式
├─ +controlkeys/              % 鍵盤輸出模組（方向鍵模擬）
│   └─ controlkeys.m / *.m
└─ README.md
```

---

## ✅ 系統需求

- **MATLAB**：R2022b 或以上（建議 R2023b/R2024a+）  
- **Toolboxes / Support Packages**
  - Image Processing Toolbox（`insertShape`, `imresize`, `imshow`）
  - *MATLAB Support Package for USB Webcams*（相機驅動）
  - （可選）Computer Vision Toolbox（非必須）
- **作業系統**：Windows / macOS（Windows 測試最完整）
- **相機**：USB/內建鏡頭

---

## 🐍 Python 環境設定（Mediapipe）

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

---

## 🕹 使用方式

1. 開啟 MATLAB，允許相機權限。  
2. 執行：
   ```matlab
   main
   ```
3. 手勢對應：
   - **1 指**：UP  
   - **≤1 指**：DOWN  
   - **張手（4–5 指）**：  
     - 右手 → RIGHT  
     - 左手 → LEFT
4. `Q` 離開程式。

---

## 🎮 遊戲推薦與玩法

這個專案會將偵測到的手勢直接轉換為方向鍵輸出，因此你可以玩任何「只需要使用方向鍵操作」的遊戲！  
我推薦以下網站與遊戲給大家體驗：

| 平台 | 推薦遊戲 | 連結 |
|------|-----------|------|
| 🌐 **Poki 網站** | Subway Surfers | https://poki.com/en/g/subway-surfers |
| 🌐 **Poki 網站** | Hill Climb Racing Lite | https://poki.com/zh/g/hill-climb-racing-lite |

> 這兩款遊戲都能在瀏覽器中直接遊玩，使用方向鍵即可操作角色。  
> 你也可以上 [https://poki.com](https://poki.com) 找任何其他有趣、以方向鍵操作的遊戲進行測試。  

如果希望有更流暢的遊戲體驗，也可以前往 **Microsoft Store** 搜尋並下載遊戲版本（我自己是下載 *Hill Climb Racing* 來測試的喔！）。

---

## ⚙ 可調參數（main.m）

- `USE_PY_MEDIAPIPE = true`：開啟/關閉 Python Mediapipe。  
- 相機解析度：`cam.Resolution = '640x480';` 提升 FPS。  
- Mediapipe 參數：
  - `max_num_hands`（預設 1，可改 2）
  - `model_complexity`（0 最快）
- 手勢門檻與判定區間（可微調靈敏度）。  
- 鏡像選項：`SELFIE_FLIP`、`SWAP_LR`（左右反轉修正）。

---

## 🧪 快速測試清單

- 執行 `py.importlib.import_module('mediapipe')` 無錯誤。  
- 執行 `main`，看到相機畫面與 21 個青色點。  
- 揮手或張手 → 螢幕右下方白框中會顯示目前偵測到的方向（UP/LEFT/RIGHT/DOWN）。  
- 開啟 Poki 遊戲頁面，試著用手勢操控角色。  

---

## ⚠️ 常見問題

**Q1. 出現 `ModuleNotFoundError: No module named 'mediapipe'`**  
→ 你可能安裝到不同的 Python。請重新確認 `pyenv` 顯示的 Python 路徑再安裝。

**Q2. 相機畫面卡住或 FPS 過低**  
→ 降低解析度、設定 `model_complexity=0`、確保環境光充足。

**Q3. 手勢偵測靈敏度太高或太低**  
→ 調整 `deltaY`、`deltaX_strict` 或手勢對應區間。

**Q4. 左右顛倒**  
→ 設定 `SELFIE_FLIP = true` 或 `SWAP_LR = true`。

**Q5. 關閉攝影機**  
→ 關閉程式視窗或執行：  
```matlab
clear cam; close all;
```

---

## 📚 參考資料

本專案手勢邏輯與程式設計概念部分參考自：  
**GestureKeyboardController** by Ojas Mittal  
🔗 https://github.com/OjasMittal/GestureKeyboardController

感謝原作者的開源分享與啟發 🙏

---

## 📝 授權與聲明

- 僅供學術、教學與個人研究使用。  
- 請勿用於商業應用或未經授權的隱私蒐集。  
- 若您分享本專案或修改版本，請保留原作者與參考來源說明。

---

## 🎉 一起玩影像處理吧！

歡迎大家下載體驗、二創擴充、甚至把它帶到你的課堂或社群活動中～  
如果你玩得開心或做了更酷的延伸版本，也歡迎在 GitHub 上分享！  
Have fun, and enjoy coding with MATLAB + Mediapipe 👋