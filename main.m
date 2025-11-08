function main
    % === Toggle ===
    USE_PY_MEDIAPIPE = true;

    % === Webcam (降解析度以提高 FPS) ===
    cam = webcam;
    try
        cam.Resolution = '640x480';
    catch
        % 若不支援就用預設
    end
    pause(0.1);
    frame = snapshot(cam);
    [H, W, ~] = size(frame);

    % === Figure / Axes / Visuals ===
    hFig = figure('Name','Hand Control','NumberTitle','off');
    hAx  = axes('Parent',hFig);
    hIm  = imshow(frame, 'Parent', hAx); hold(hAx,'on');
    hPts = plot(hAx, nan, nan, '.', 'MarkerSize', 12, 'Color', 'c');  % 21點

    boxPos = [round(W*0.6) round(H*0.6) round(W*0.3) round(H*0.18)];
    hRect  = rectangle(hAx,'Position',boxPos,'EdgeColor','w','LineWidth',2,'Curvature',0.1);
    hText  = text(hAx, boxPos(1)+20, boxPos(2)+boxPos(4)/2, '', ...
        'Color','y','FontSize',24,'FontWeight','bold','VerticalAlignment','middle', ...
        'Interpreter','none','BackgroundColor','k','Margin',4,'Clipping','on');
    uistack(hText,'top');

    setappdata(hFig,'isClosing',false);
    set(hFig,'CloseRequestFcn',@(src,evt) setappdata(src,'isClosing',true));

    % === Python / MediaPipe init ===
    if USE_PY_MEDIAPIPE
        % 建議：用 InProcess 以降低 MATLAB↔Python IPC 開銷
        try
            pyenv("ExecutionMode","InProcess");
        catch
            % 若你的環境在 InProcess 不穩，註解掉，改回原本模式
        end
        pe = pyenv;
        if pe.Status == "NotLoaded"
            % 視需要：pyenv("Version","C:\Path\to\python.exe");
        end
        cv2 = py.importlib.import_module('cv2');
        mp  = py.importlib.import_module('mediapipe');
        mp_hands = mp.solutions.hands;
        hands = mp_hands.Hands(pyargs( ...
            'max_num_hands', int32(1), ...
            'model_complexity', int32(0), ...   % 0最快
            'min_detection_confidence', 0.6, ...
            'min_tracking_confidence', 0.5));
    else
        cv2 = [];
        hands = [];
    end

    % === 控制鍵狀態 ===
    currentDown = false(1,4);  % [LEFT RIGHT UP DOWN]
    cleanupObj = onCleanup(@()cleanup(cam, USE_PY_MEDIAPIPE, hands));
    disp('Camera started (press Q to quit).');

    % === 加速選項 ===
    SWAP_LR   = false;  % 若 SELFIE_FLIP=true 仍覺顛倒，改 true 快速校正
    DOWNSCALE = 0.6;    % Mediapipe 用縮圖跑，0.5~0.7 效果佳
    MP_EVERY_N = 1;     % 跳幀推論：1=每幀都跑；2=每2幀跑一次
    frameCount = 0;
    lastLm = []; lastLR = ""; lastFlip = false;

    % —— 顯示面板專為高 FPS 設定 ——
    set(hFig,'GraphicsSmoothing','off');                       % 確保用硬體 OpenGL
    set(hAx,'Visible','off');                                 % 關掉座標軸繪製
    set(hAx,'Units','pixels','Position',[1 1 W H]);           % 讓圖像=像素等比
    set(hIm,'Interruptible','off','BusyAction','cancel');     % 禁止排隊阻塞

    targetFPS = 30;
    minDt = 1/targetFPS;
    tDraw = tic;  % 計時器

    % === 安全模式：每幀都跑、放寬門檻、加偵錯文字 ===
    SWAP_LR   = false;   % 若左右仍顛倒，把它改 true
    DOWNSCALE = 0.6;     % 先保留縮圖
    while ishandle(hFig)
        if ~ishandle(hFig) || (isappdata(hFig,'isClosing') && getappdata(hFig,'isClosing'))
            break;
        end

        % —— 安全：figure/axes/image handle 健檢，避免被關掉時 set() 爆掉 ——
        if ~ishandle(hAx) || ~isgraphics(hAx)
            break;  % 或者在這裡重建 axes / image（見下方 C）
        end
        if ~ishandle(hIm) || ~isgraphics(hIm)
            % 影像物件不見了就重建一次（不想重建也可改成 break）
            hIm  = imshow(frame, 'Parent', hAx);
            if ~ishandle(hPts) || ~isgraphics(hPts)
                hPts = plot(hAx, nan, nan, '.', 'MarkerSize', 12, 'Color', 'c');
            end
        end

        frame = snapshot(cam);
    
        % 每幀都跑 Mediapipe（避免 lastLm 空值循環）
        [lmList, handLR, didFlip] = getHandLandmarks(frame, USE_PY_MEDIAPIPE, cv2, hands, H, W, DOWNSCALE);
    
        % 顯示端跟著翻轉，確保座標一致
        if didFlip
            frame = fliplr(frame);
        end
        if SWAP_LR && handLR~=""
            if handLR=="Left", handLR="Right"; else, handLR="Left"; end
        end
    
        % ===== 手勢判斷（放寬門檻）=====
        wantDown = false(1,4);   % [LEFT RIGHT UP DOWN]
        labelMsg = '';
        debugMsg = 'NO HAND';
    
        if ~isempty(lmList)
            % 放寬：容易命中
            deltaY = max(4, round(H * 0.03));          % 3% 高
            deltaX_strict = max(8, round(W * 0.06));   % 6% 寬
            tipIds = [4 8 12 16 20];
            fingers = zeros(1,5);
    
            % 拇指
            tt = lmList(4+1,2:3);  % tip
            ti = lmList(3+1,2:3);  % IP
            if handLR == "Right"
                if (tt(1) - ti(1)) > deltaX_strict, fingers(1) = 1; end
            elseif handLR == "Left"
                if (ti(1) - tt(1)) > deltaX_strict, fingers(1) = 1; end
            else
                if abs(tt(1) - ti(1)) > deltaX_strict, fingers(1) = 1; end
            end
    
            % 其餘四指：tip 高於 PIP
            for k = 2:5
                tip = tipIds(k);
                tip_y = lmList(tip+1,3);
                pip_y = lmList((tip-2)+1,3);
                if (pip_y - tip_y) > deltaY
                    fingers(k) = 1;
                end
            end
    
            % 張手補判拇指
            if sum(fingers(2:5)==1) == 4 && fingers(1)==0
                if handLR == "Right"
                    if (tt(1) - ti(1)) > round(0.5*deltaX_strict), fingers(1) = 1; end
                elseif handLR == "Left"
                    if (ti(1) - tt(1)) > round(0.5*deltaX_strict), fingers(1) = 1; end
                end
            end
    
            total = sum(fingers==1);
    
            % 手勢映射（先判 UP，再判 DOWN）
            if total == 1
                wantDown(3) = true;  labelMsg = 'UP';
            elseif total <= 1
                wantDown(4) = true;  labelMsg = 'DOWN';
            elseif total >= 4   % 4 或 5 都當作張手
                if handLR == "Right"
                    wantDown(2) = true;  labelMsg = 'RIGHT';
                elseif handLR == "Left"
                    wantDown(1) = true;  labelMsg = 'LEFT';
                else
                    labelMsg = 'OPEN';
                end
            else
                labelMsg = sprintf('F=%d (%s)', total, char(handLR)); % debug
            end
    
            debugMsg = sprintf('HAND(%s) • F=%d • 21pts', char(handLR), total);
        end
    
        % ===== 送鍵 =====
        VK = [controlkeys.VK_LEFT, controlkeys.VK_RIGHT, controlkeys.VK_UP, controlkeys.VK_DOWN];
        for i = 1:4
            if currentDown(i) && ~wantDown(i)
                controlkeys.KeyOff(VK(i)); currentDown(i) = false;
            end
        end
        if any(wantDown)
            firstIdx = find(wantDown, 1, 'first');
            for j = 1:4
                if j ~= firstIdx && currentDown(j)
                    controlkeys.KeyOff(VK(j)); currentDown(j) = false;
                end
            end
            if ~currentDown(firstIdx)
                controlkeys.KeyOn(VK(firstIdx)); currentDown(firstIdx) = true;
            end
        end
    
        % ===== 畫面更新 =====
        if isgraphics(hIm)
            set(hIm,'CData',frame);
        else
            % 影像物件失效時重建（保底）
            if isgraphics(hAx)
                hIm = imshow(frame,'Parent',hAx);
            else
                break;  % 連 axes 都沒了就離開
            end
        end
        if ~isempty(lmList)
            set(hPts, 'XData', lmList(:,2), 'YData', lmList(:,3));
        else
            set(hPts, 'XData', nan, 'YData', nan);
        end
    
        % 邊框與文字（用 text 物件，較快）
        if ~isempty(labelMsg)
            set(hRect,'EdgeColor','w'); set(hText,'String', char(labelMsg), 'Color','y');
        else
            set(hRect,'EdgeColor',[.3 .3 .3]); set(hText,'String','');
        end
    
        % 左上角偵錯字（用 title 省事；也可用另一個 text）
        title(hAx, debugMsg, 'Color','y');
    
        % 只在達到最低間隔才真的刷新 (降低GUI負擔，減少排隊)
        if toc(tDraw) >= minDt
            drawnow limitrate nocallbacks
            tDraw = tic;
        end
    
        % ===== 退出 =====
        if ~ishandle(hFig), break; end
        ch = get(hFig,'CurrentCharacter');
        if strcmpi(ch,'q'), break; end
        set(hFig,'CurrentCharacter',char(0));
    end
    if ishandle(hFig), delete(hFig); end

end

function [lmList, handLabel, didFlip, roiUsed] = getHandLandmarks(frame, usePy, cv2, hands, H, W, scale, roi, roiMin)
    if nargin < 7, scale = 1.0; end
    if nargin < 8, roi = []; end
    if nargin < 9, roiMin = 0; end

    lmList = []; handLabel = ""; didFlip = false; roiUsed = [];
    if ~usePy, return; end

    % ---------- persistent: 模組與 Python 小函數（只建立一次） ----------
    persistent np lms2px handed_label
    if isempty(np)
        np = py.importlib.import_module('numpy');
    end
    if isempty(lms2px)
        % lms2px(hand, w, h) -> numpy array shape (21,2) in pixel coords
        % 用 Python 端直接存取 hand.landmark，避免 MATLAB 端 protobuf 橋接成本
        lms2px = py.eval( ...
            ['lambda hand,w,h: __import__("numpy").ascontiguousarray([' ...
             '(int(round(lm.x*w)), int(round(lm.y*h))) for lm in hand.landmark' ...
             '], dtype=__import__("numpy").int32)'], py.dict);
    end
    if isempty(handed_label)
        % 取第一隻手的 "Left"/"Right"
        handed_label = py.eval( ...
            ['lambda results: (results.multi_handedness and ' ...
             'results.multi_handedness[0].classification[0].label) or ""'], py.dict);
    end

    % ---------- 從 ROI 或全圖取 source 影像 ----------
    if ~isempty(roi)
        x = max(1, round(roi(1))); y = max(1, round(roi(2)));
        w = min(W - x + 1, round(roi(3))); h = min(H - y + 1, round(roi(4)));
        if w < roiMin || h < roiMin
            x = max(1, round(W/2 - roiMin/2)); y = max(1, round(H/2 - roiMin/2));
            w = min(W - x + 1, roiMin); h = min(H - y + 1, roiMin);
        end
        roiUsed = double([x y w h]);
        src = frame(y:y+h-1, x:x+w-1, :);
    else
        roiUsed = double([1 1 W H]);
        src = frame;
        w = W; h = H; %#ok<NASGU>
    end

    % ---------- 縮圖（為 Mediapipe 加速） ----------
    if scale ~= 1.0
        src_small = imresize(src, scale, 'nearest');
    else
        src_small = src;
    end
    [hS, wS, ~] = size(src_small);

    % ---------- MATLAB → numpy（快路徑；失敗就直接 return） ----------
    try
        arr = np.array(src_small, pyargs('dtype', np.uint8, 'order','C', 'copy', true));
        img_rgb = np.ascontiguousarray(arr); % src_small 已經是 RGB
    catch
        % 快路徑失敗時，不走慢路徑（避免 3 秒卡頓），直接丟掉這幀
        return
    end

    % ---------- 自拍鏡像（前鏡頭建議 true） ----------
    SELFIE_FLIP = true;
    if SELFIE_FLIP
        img_rgb = cv2.flip(img_rgb, int32(1));
    end
    didFlip = SELFIE_FLIP;

    % ---------- Mediapipe ----------
    results = hands.process(img_rgb);
    if isequal(results, py.None)
        return
    end
    try
        nHands = double(py.len(results.multi_hand_landmarks));
    catch
        nHands = 0;
    end
    if nHands < 1
        return
    end

    % ---------- 直接在 Python 端把 21 點轉像素（單次跨橋） ----------
    plist = py.list(results.multi_hand_landmarks);  % ✅ 修正索引方式
    cells = cell(plist);
    hand0 = cells{1};
    
    pts_np = lms2px(hand0, int32(wS), int32(hS));  % numpy int32 (21,2)
    pts = double(pts_np);                          % 直接把 numpy ndarray 轉 MATLAB double
    if ndims(pts) ~= 2 || size(pts,2) ~= 2         % 保險：萬一維度被攤平成一維
        pts = reshape(pts, [], 2);
    end    

    % 映回原圖座標（縮放 + ROI 位移）
    if scale ~= 1.0
        pts = round(pts ./ scale);
    end
    pts(:,1) = pts(:,1) + (roiUsed(1) - 1);
    pts(:,2) = pts(:,2) + (roiUsed(2) - 1);

    ids = (0:size(pts,1)-1).';
    lmList = [ids, pts];

    % ---------- 取手別（一次呼叫） ----------
    try
        handLabel = string(handed_label(results));
    catch
        handLabel = "";
    end
end


function cleanup(cam, usePy, hands)
    try, clear cam; catch, end
    if usePy && ~isempty(hands)
        try, hands.close(); catch, end
    end
    try, close all; catch, end
end
