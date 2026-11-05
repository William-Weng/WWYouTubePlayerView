//
//  WWYouTubePlayerView.swift
//  WWYouTubePlayerView
//
//  Created by William.Weng on 2026/11/4.
//

import UIKit
import WebKit

@MainActor
public final class WWYouTubePlayerView: UIView {

    private static var configurationPlaceholder: String { "__PLAYER_CONFIGURATION_JSON__" }
    
    public weak var delegate: (any PlayerViewDelegate)?

    public private(set) var isReady = false
    public private(set) var currentVideoId: String?

    public var debugLoggingEnabled = false

    private var webView: WKWebView?

    private static let messageHandlerName = "youtubePlayer"

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
    }
}

// MARK: - Delegate
extension WWYouTubePlayerView: WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {}

// MARK: - WKScriptMessageHandler
public extension WWYouTubePlayerView {
        
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handleScriptMessage(message)
    }
}

// MARK: - WKNavigationDelegate
public extension WWYouTubePlayerView {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        handleNavigationPolicy(for: navigationAction, decisionHandler: decisionHandler)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        isReady = false
        report(NSError(domain: "WWYouTubePlayerView.WebKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "WebView content process terminated. Reload the player."]))
    }
}

// MARK: - WKUIDelegate
public extension WWYouTubePlayerView {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return handleNewWindowRequest(for: navigationAction)
    }
}

// MARK: - 公開函式
public extension WWYouTubePlayerView {
    
    /// 從完整的 YouTube 網址中解析並提取出 11 碼的 Video ID
    ///
    /// - Parameter url: 要解析的 YouTube 網址字串（允許帶有前後空格或額外的追蹤參數）
    /// - Returns: 成功提取則回傳 11 碼的影片 ID 字串（String）；若網址格式不符或解析失敗則回傳 `nil`
    static func parseVideoId(url: String) -> String? {
        url.extractYouTubeVideoId()
    }
}

// MARK: - 公開函式
public extension WWYouTubePlayerView {
    
    /// 重新建立 WebView，並載入指定的 YouTube 影片
    ///
    /// 先建立來源識別 URL 與 HTML 內容，成功後才移除既有播放器，再建立並加入新的 WebView
    ///
    /// 此方法會重新建立播放器；若只需要在已就緒的播放器中切換影片，可使用 `loadVideo(videoID:startSeconds:)`
    ///
    /// 載入完成後，仍須等待播放器的就緒通知，才能執行播放控制或資訊查詢
    ///
    /// 發生錯誤時，會交由 `report(_:)` 統一記錄並通知 delegate
    ///
    /// - Parameters:
    ///   - videoId: 要載入的 YouTube 影片 ID
    ///   - playerVars: 播放器參數，預設為空字典；由 `makeHTML` 合併預設設定，並指定 App 的來源識別
    func load(videoId: String, playerVars: [PlayerParameter: Any] = [:]) {
        
        do {
            
            let rawPlayerVars: [String: Any] = Dictionary(uniqueKeysWithValues: playerVars.map { parameter, value in(parameter.rawValue, value)})
            let origin = try makeOriginURL()
            let html = try Self.makeHTML(videoId: videoId, playerVars: rawPlayerVars, origin: origin)

            removePlayer()

            let configuration = webViewConfigurationMaker()
            let newWebView = WKWebView.maker(target: self, with: bounds, configuration: configuration)
            
            webView = newWebView
            currentVideoId = videoId
            
            addSubview(newWebView)

            log("Bundle ID: \(Bundle.main.bundleIdentifier ?? "(nil)")")
            log("Origin: \(origin.absoluteString)")
            log("Loading video: \(videoId)")

            newWebView.loadHTMLString(html, baseURL: origin)
        } catch {
            report(error)
        }
    }

    /// 移除目前的 YouTube 播放器，並清理相關狀態與 WebView 資源
    ///
    /// 此方法會重設播放器的就緒狀態與目前影片 ID，移除 JavaScript 訊息處理器、停止載入、解除 delegate 參考，並將 WebView 從視圖階層移除
    func removePlayer() {
        
        isReady = false
        currentVideoId = nil
        
        guard let webView else { return }
        
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Self.messageHandlerName)
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.removeFromSuperview()
        
        self.webView = nil
    }
}

// MARK: Playback Controls
public extension WWYouTubePlayerView {
    
    /// 要求播放器開始或繼續播放目前的影片
    func play() { command(.playVideo) }
    
    /// 要求播放器暫停目前的影片
    func pause() { command(.pauseVideo) }
    
    /// 要求播放器停止播放
    func stop() { command(.stopVideo) }
    
    /// 要求播放器開啟靜音
    func mute() { command(.mute) }
    
    /// 要求播放器關閉靜音
    func unmute() { command(.unMute) }

    /// 要求播放器跳轉至指定的播放時間
    ///
    /// 此方法會直接傳送指定的秒數，不在本地限制其範圍
    ///
    /// - Parameters:
    ///   - seconds: 目標播放位置，單位為秒
    ///   - allowSeekAhead: 當目標位置尚未緩衝時，是否允許播放器向前取得該位置所需的影片資料
    func seek(to seconds: Double, allowSeekAhead: Bool = true) {
        let arguments: [Any] = [seconds, allowSeekAhead]
        command(.seekTo, arguments: arguments)
    }
    
    /// 在目前已就緒的播放器中載入指定影片，並嘗試開始播放
    ///
    /// 不會重新建立 WebView 或重新載入 HTML 模板；JavaScript 指令執行成功後，會更新 `currentVideoID`
    ///
    /// - Important: 更新影片 ID 不代表影片已成功載入或開始播放；後續結果仍須透過播放器的狀態與錯誤通知確認
    ///
    /// - Parameters:
    ///   - videoID: 要載入的 YouTube 影片 ID
    ///   - startSeconds: 起始播放位置，單位為秒，預設為 `0`
    func loadVideo(videoID: String, startSeconds: Double = 0) {
        
        let argument: [String: Any] = ["videoId": videoID, "startSeconds": startSeconds]
        
        command(.loadVideoById, arguments: [argument]) { [weak self] in
            guard let self else { return }
            self.currentVideoId = videoID
        }
    }

    /// 在目前已就緒的播放器中備妥指定影片，不主動開始播放，不會重新建立 WebView 或重新載入 HTML 模板
    ///
    /// JavaScript 指令執行成功後，會更新 `currentVideoID`；後續可呼叫 `play()` 要求播放
    ///
    /// - Important: 指令執行成功不代表影片已完成備妥；實際狀態仍須透過播放器的狀態與錯誤通知確認
    ///
    /// - Parameters:
    ///   - videoID: 要備妥的 YouTube 影片 ID
    ///   - startSeconds: 後續開始播放時的起始位置，單位為秒，預設為 `0`
    func cueVideo(videoID: String, startSeconds: Double = 0) {
        
        let argument: [String: Any] = ["videoId": videoID, "startSeconds": startSeconds]
        
        command(.cueVideoById, arguments: [argument]) { [weak self] in
            guard let self else { return }
            self.currentVideoId = videoID
        }
    }

    /// 要求播放器設定音量
    ///
    /// 傳入值會先限制於 `0...100`，再送出指令；此方法不會修改裝置的系統音量
    ///
    /// - Parameter volume: 目標播放器音量，範圍為 `0...100`
    func setVolume(_ volume: Int) {
        let arguments: [Any] = [min(max(volume, 0), 100)]
        command(.setVolume, arguments: arguments)
    }

    /// 要求播放器設定播放速率
    ///
    /// 此方法會直接傳送指定值，不在本地驗證可用的播放速率；指令執行成功不代表播放器一定採用該速率
    ///
    /// - Parameter rate: 目標播放倍率，例如 `1.0` 表示正常速度
    func setPlaybackRate(_ rate: Double) {
        command(.setPlaybackRate, arguments: [rate])
    }
}

// MARK: Player Information
public extension WWYouTubePlayerView {
    
    /// 查詢目前的播放時間
    ///
    /// 播放器須已準備完成，才能執行查詢；查詢錯誤會透過 completion 回傳，由呼叫端處理
    ///
    /// - Parameter completion: 查詢完成後的回呼。成功時回傳目前播放位置，單位為秒；失敗時回傳播放器未就緒、執行或結果驗證錯誤
    func currentTime(completion: @escaping (Result<Double, Error>) -> Void) {
        queryNumber(.getCurrentTime, completion: completion)
    }

    /// 查詢影片的總長度
    ///
    /// 播放器須已準備完成，才能執行查詢；此方法會直接回傳播放器提供的數值，不額外判斷其是否大於零
    ///
    /// - Parameter completion: 查詢完成後的回呼。成功時回傳影片長度，單位為秒；失敗時回傳播放器未就緒、執行或結果驗證錯誤
    func duration(completion: @escaping (Result<Double, Error>) -> Void) {
        queryNumber(.getDuration, completion: completion)
    }
    
    /// 查詢目前的播放狀態
    ///
    /// 將播放器回傳的數值狀態碼轉換為 `PlayerState`；若狀態碼無法對應已定義的狀態，則以成功結果回傳 `.unknown`，而不是視為查詢失敗
    ///
    /// - Parameter completion: 查詢完成後的回呼。成功時回傳目前的播放狀態；失敗時保留並回傳底層查詢錯誤
    func playerState(completion: @escaping (Result<PlayerState, Error>) -> Void) {
        
        queryNumber(.getPlayerState) { result in
            completion(result.map { value in PlayerState(rawValue: Int(value)) ?? .unknown })
        }
    }
}

// MARK: - 代入HTML模板
private extension WWYouTubePlayerView {

    /// 建立包含指定影片與播放器設定的完整 HTML (此方法會讀取 `player.html`，並將設定 JSON 代入模板)
    ///
    /// - Parameters:
    ///   - videoId: 要載入的 YouTube 影片 ID
    ///   - inputPlayerVars: 呼叫端指定的播放器參數，會覆蓋預設值
    ///   - origin: App 的來源識別 URL，不允許由播放器參數覆蓋
    /// - Returns: 已代入設定、可供 WebView 載入的 HTML 字串
    /// - Throws: JSON 序列化、模板讀取或佔位符驗證錯誤
    static func makeHTML(videoId: String, playerVars inputPlayerVars: [String: Any], origin: URL) throws -> String {

        var playerVars: [String: Any] = ["playsinline": 1, "controls": 1, "autoplay": 0, "rel": 0]

        playerVars.merge(inputPlayerVars) { _, newValue in newValue }
        playerVars["origin"] = origin.absoluteString

        let configuration: [String: Any] = ["width": "100%", "height": "100%", "videoId": videoId, "playerVars": playerVars ]
        let configurationJSON = try JSONSerialization.configurationJSON(configuration)
        let template = try Bundle.module.loadHTMLTemplate(forResource: "player", withExtension: "html")
        let placeholder = configurationPlaceholder

        guard template.contains(placeholder) else { throw PlayerViewError.configurationPlaceholderNotFound }
        return template.replacingOccurrences(of: placeholder, with: configurationJSON)
    }
}

// MARK: - 輔助用函數
private extension WWYouTubePlayerView {
    
    /// 驗證並處理 HTML 播放器傳送的 JavaScript 訊息
    ///
    /// 僅接受目前使用中的 WebView 主 frame，透過指定 message handler 傳送的訊息
    ///
    /// 訊息內容預期為以下結構：
    /// ```json
    /// {
    ///     "event": "state",
    ///     "data": 1
    /// }
    /// ```
    ///
    /// 驗證成功後，依事件類型更新播放器狀態、通知 delegate，或回報腳本錯誤；不符合格式或無法識別的事件會直接忽略
    ///
    /// - Parameter message: 從 JavaScript bridge 收到的訊息。
    func handleScriptMessage(_ message: WKScriptMessage) {
        
        guard let activeWebView = webView,
              message.webView === activeWebView,
              message.frameInfo.isMainFrame,
              message.name == Self.messageHandlerName,
              let body = message.body as? [String: Any],
              let eventValue = body["event"] as? String,
              let event = ReceiveEvent(rawValue: eventValue)
        else {
            return
        }
        
        switch event {
        case .ready:
            isReady = true
            log("Ready")
            delegate?.playerViewDidBecomeReady(self)
            
        case .state:
            let rawValue = (body["data"] as? NSNumber)?.intValue ?? -999
            let state = PlayerState(rawValue: rawValue) ?? .unknown
            log("State: \(state), raw: \(rawValue)")
            delegate?.playerView(self, didChangeTo: state)
            
        case .time:
            guard let number = body["data"] as? NSNumber else { return }
            delegate?.playerView(self, didChangeCurrentTime: number.doubleValue)
            
        case .youtubeError:
            let code = (body["data"] as? NSNumber)?.intValue ?? -1
            log("Raw onError: \(code)")
            delegate?.playerView(self, didFailWith: .youTube(code))
            
        case .scriptError:
            let message = body["data"] as? String ?? "Unknown JavaScript error"
            let error = NSError(domain: "WWYouTubePlayerView.JavaScript", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            report(error)
        }
    }
    
    /// 判斷導覽請求應由 WebView 載入、交由系統開啟，或直接取消
    ///
    /// 處理規則：
    /// - 缺少 URL 時，取消導覽
    /// - 使用者點擊、且目標為主 frame 或沒有目標 frame 的連結
    ///   取消 WebView 導覽，並僅將 HTTP 或 HTTPS URL 交由系統開啟
    /// - 其餘請求僅允許 HTTP、HTTPS 與 about scheme
    ///
    /// 子 frame 內的連結不會因為使用者點擊而直接交由系統開啟，但仍會經過 scheme 檢查
    ///
    /// - Parameters:
    ///   - navigationAction: 等待決定處理方式的導覽動作
    ///   - decisionHandler: 回傳導覽決策的 closure；每條執行路徑皆會呼叫一次
    func handleNavigationPolicy(for navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        
        let scheme = url.scheme?.lowercased()
        let shouldOpenExternally = navigationAction.navigationType == .linkActivated && navigationAction.targetFrame?.isMainFrame != false
        
        if shouldOpenExternally {
            decisionHandler(.cancel)
            if scheme == "https" || scheme == "http" { UIApplication.shared.open(url, options: [:], completionHandler: nil) }; return
        }
        
        if scheme == "https" || scheme == "http" || scheme == "about" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    /// 處理開啟新視窗的導覽請求
    ///
    /// 僅將使用者點擊、且沒有目標 frame 的 HTTP 或 HTTPS 連結交由系統開啟；其餘請求不進行處理
    ///
    /// - Parameter navigationAction: 觸發新視窗請求的導覽動作
    /// - Returns: 固定回傳 `nil`，不建立新的 WebView
    func handleNewWindowRequest(for navigationAction: WKNavigationAction) -> WKWebView? {

        guard navigationAction.targetFrame == nil,
              navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http"
        else {
            return nil
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return nil
    }
    
    /// 處理 WebView 的導覽錯誤
    ///
    /// 忽略 `NSURLErrorDomain` 中的 `NSURLErrorCancelled` 錯誤，其餘錯誤則交由 `report(_:)` 統一回報
    ///
    /// - Parameter error: WebView 導覽過程中收到的錯誤
    func handleNavigationError(_ error: Error) {
        
        let nsError = error as NSError
        guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }

        report(error)
    }
}

// MARK: - 工具函數
private extension WWYouTubePlayerView {
    
    /// 使用主 App 的 Bundle Identifier 建立播放器的來源識別 URL
    ///
    /// 將 Bundle Identifier 轉為小寫，並加上 `https://` 前綴
    /// 例如：`com.example.MyApp` 會轉換為 `https://com.example.myapp`。
    ///
    /// 此 URL 用於播放器的來源設定；本方法僅建立 URL，不會發送網路請求或確認對應的網站是否存在
    ///
    /// - Returns: 可供播放器作為來源識別使用的 HTTPS URL
    /// - Throws:
    ///   - `PlayerViewError.missingBundleIdentifier`：主 App 的 Bundle Identifier 不存在或為空字串
    ///   - `PlayerViewError.invalidOrigin`：無法建立 URL，或建立的 URL 缺少 host
    func makeOriginURL() throws -> URL {
        
        guard let bundleID = Bundle.main.bundleIdentifier,
              !bundleID.isEmpty
        else {
            throw PlayerViewError.missingBundleIdentifier
        }
        
        guard let url = URL(string: "https://\(bundleID.lowercased())"),
              url.host != nil
        else {
            throw PlayerViewError.invalidOrigin
        }
        
        return url
    }
    
    /// 記錄錯誤，並透過 delegate 通知呼叫端
    ///
    /// 使用錯誤的 `localizedDescription` 產生除錯訊息，再將原始錯誤交由 delegate 處理
    ///
    /// 即使關閉除錯記錄，仍會發送 delegate 錯誤通知
    ///
    /// - Parameter error: 要記錄並回報的原始錯誤
    func report(_ error: Error) {
        log("Error: \(error.localizedDescription)")
        delegate?.playerView(self, didFailWith: .script(error))
    }
    
    /// 在啟用除錯記錄時，將訊息輸出至 Console
    ///
    /// 訊息會加上 `[YouTubePlayerView]` 前綴，方便辨識來源；若 `debugLoggingEnabled` 為 `false`，則不輸出任何內容
    ///
    /// - Parameter message: 要輸出的除錯訊息
    func log(_ message: String) {
        guard debugLoggingEnabled else { return }
        print("[WWYouTubePlayerView] \(message)")
    }
}

// MARK: - 工具函數
private extension WWYouTubePlayerView {
    
    /// 建立播放器使用的 JavaScript 訊息管理器
    ///
    /// 使用 `Self.messageHandlerName` 註冊訊息處理器，讓 HTML 播放器能透過 JavaScript bridge 傳送事件
    ///
    /// 透過 `WeakScriptMessageHandler` 間接轉送訊息，避免訊息管理器直接強持有播放器實例
    ///
    /// - Returns: 已註冊播放器訊息處理器的管理器
    func userContentControllerMaker() -> WKUserContentController {
        
        let controller = WKUserContentController()
        controller.add(WeakScriptMessageHandler(target: self), name: Self.messageHandlerName)
        
        return controller
    }
    
    /// 建立播放器使用的 WebView 設定
    ///
    /// 設定內容包含：
    /// - 使用已註冊 JavaScript bridge 的訊息管理器
    /// - 允許影片在網頁內嵌播放
    /// - 不要求媒體播放必須由使用者手勢觸發
    ///
    /// - Returns: 已完成播放器基本設定的 WebView configuration
    func webViewConfigurationMaker() -> WKWebViewConfiguration {
        
        let controller = userContentControllerMaker()
        let configuration = WKWebViewConfiguration()
        
        configuration.userContentController = controller
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        return configuration
    }
    
    /// 執行不需要取得回傳值的播放器指令
    ///
    /// 透過 `evaluate(method:arguments:completion:)` 呼叫 JavaScript 方法：
    /// - 執行成功時，忽略回傳值，並呼叫選用的 `onSuccess`
    /// - 執行失敗時，若播放器實例仍存在，則透過 `report(_:)` 回報錯誤
    ///
    /// - Important: 執行成功僅表示 JavaScript 呼叫未回報錯誤，不代表播放器已完成播放、跳轉或其他非同步狀態變更
    ///
    /// - Parameters:
    ///   - method: 要呼叫的播放器方法名稱，例如 `"playVideo"`；應使用套件內部定義的方法名稱，不包含 `player.` 前綴或括號
    ///   - arguments: 依方法參數順序排列的引數，預設為空陣列；所有內容皆須符合 `JSONSerialization` 支援的 JSON 格式
    ///   - onSuccess: JavaScript 呼叫成功後執行的回呼，預設為 `nil`
    func command(_ method: ControlMethod, arguments: [Any] = [], onSuccess: (() -> Void)? = nil) {
        
        evaluate(method: method.rawValue, arguments: arguments) { [weak self] result in
            switch result {
            case .success:onSuccess?()
            case .failure(let error): self?.report(error)
            }
        }
    }
    
    /// 呼叫不帶參數的播放器查詢方法，並將數值結果轉換為 `Double`
    ///
    /// 適用於查詢目前播放時間、影片長度等數值資訊
    ///
    /// 若回傳值無法轉換為 `NSNumber`，則回傳 `PlayerViewError.invalidResult`
    ///
    /// - Parameters:
    ///   - method: 要呼叫的播放器方法名稱，例如 `"getCurrentTime"`；應使用套件內部定義的方法名稱，不包含 `player.` 前綴或括號
    ///   - completion: 查詢完成後的回呼；成功時回傳 `Double`；失敗時回傳執行或結果驗證錯誤
    func queryNumber(_ method: QueryMethod, completion: @escaping (Result<Double, Error>) -> Void) {
        
        evaluate(method: method.rawValue) { result in
            switch result {
            case .success(let value):
                guard let number = value as? NSNumber else { completion(.failure(PlayerViewError.invalidResult)); return }
                completion(.success(number.doubleValue))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 呼叫 JavaScript 播放器的方法，並回傳執行結果
    ///
    /// 執行前會確認播放器已準備完成，且 WebView 仍存在；參數陣列會先序列化為 JSON，再透過 JavaScript 的 `apply` 將各參數依序傳入指定方法，並以 `player` 作為方法的 `this`
    ///
    /// - Important: `method` 會直接插入 JavaScript 程式碼，
    ///   應僅使用套件內部定義的方法名稱，不應直接接受外部未驗證的輸入。
    ///
    /// - Parameters:
    ///   - method: 要呼叫的播放器方法名稱，例如 `"playVideo"` 或 `"seekTo"`；不包含 `player.` 前綴、括號或參數
    ///   - arguments: 依方法參數順序排列的引數，預設為空陣列；所有內容皆須符合 `JSONSerialization` 支援的 JSON 格式
    ///   - completion: 操作完成後的回呼；成功時回傳 JavaScript 的執行結果；失敗時回傳播放器未就緒、JSON 序列化或 JavaScript 執行所產生的錯誤
    func evaluate(method: String, arguments: [Any] = [], completion: @escaping (Result<Any?, Error>) -> Void) {
        
        guard isReady,
              let webView
        else {
            completion(.failure(PlayerViewError.notReady)); return
        }
        
        do {
            
            let data = try JSONSerialization.data(withJSONObject: arguments, options: [])
            let argumentsJSON = String(decoding: data, as: UTF8.self)
            let script = """
            player.\(method).apply(player, \(argumentsJSON));
            """
            
            webView.evaluateJavaScript(script) { value, error in
                if let error { completion(.failure(error)); return }
                completion(.success(value))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
