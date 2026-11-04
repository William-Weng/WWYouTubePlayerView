//
//  Handler.swift
//  WWYouTubePlayerView
//
//  Created by William.Weng on 2026/11/4.
//

import WebKit

/// 用來包裝 `WKScriptMessageHandler` 的弱引用轉發器
///
/// `WKUserContentController` 會強引用透過 `add(_:name:)` 註冊的 message handler
/// 若直接將 `WWYouTubePlayerView` 註冊為 handler，可能形成：`WWYouTubePlayerView → WKWebView → WKUserContentController → WWYouTubePlayerView`的循環引用，導致播放器 View 無法被正常釋放
///
/// 此類別以 `weak` 持有真正的 handler（`target`），讓 `WKUserContentController` 持有的是 `WeakScriptMessageHandler`，而不是直接強持有播放器 View
@MainActor
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    
    weak var target: (any WKScriptMessageHandler)?  // 真正處理 JavaScript 訊息的物件。

    /// 建立弱引用轉發器
    ///
    /// - Parameter target: 真正要接收並處理 JavaScript 訊息的物件，在本套件中通常為 `WWYouTubePlayerView`
    init(target: any WKScriptMessageHandler) {
        self.target = target
        super.init()
    }

    /// 收到 WebView 內 JavaScript 傳來的訊息時呼叫
    ///
    /// 此方法只負責將訊息原封不動地轉發給 `target`；若 `target` 已被釋放，則使用 optional chaining 安全忽略該訊息
    ///
    /// - Parameters:
    ///   - userContentController: 收到訊息的 `WKUserContentController`
    ///   - message: JavaScript 透過 message handler 傳送的訊息內容
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
