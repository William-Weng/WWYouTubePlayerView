//
//  Extension.swift
//  WWYouTubePlayerView
//
//  Created by William.Weng on 2026/11/4.
//

import WebKit

// MARK: - JSONSerialization
extension JSONSerialization {

    /// 將設定字典轉換成可直接嵌入 HTML `<script>` 區塊的 JSON 字串
    ///
    /// 序列化後會額外轉義下列字元：
    /// - `<`：避免設定內容中的 `</script>` 提早結束 HTML 的 script 區塊
    /// - U+2028（行分隔符）：以 Unicode 跳脫序列表示，提升 JavaScript 相容性
    /// - U+2029（段落分隔符）：以 Unicode 跳脫序列表示，提升 JavaScript 相容性
    ///
    /// 回傳值是 JSON 文字，可直接代入 JavaScript 的物件設定位置，不需要再於外層加上引號
    ///
    /// - Important: 此方法針對 HTML script 區塊中的 JSON 內容進行轉義，
    ///   不適用於 HTML 屬性、URL 或其他插值情境。
    ///
    /// - Parameter configuration: 要序列化的設定字典，其中的值必須符合 `JSONSerialization` 支援的 JSON 格式
    /// - Returns: 已完成序列化及 script 區塊轉義處理的 JSON 字串
    /// - Throws: 設定內容無法序列化為 JSON 時，拋出序列化錯誤
    static func configurationJSON(_ configuration: [String: Any]) throws -> String {

        let data = try data(withJSONObject: configuration, options: [])
        
        let json = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "<", with: "\\u003C")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")

        return json
    }
}

// MARK: - Bundle
extension Bundle {
    
    /// 從目前的 bundle 讀取 HTML 模板
    ///
    /// - Parameters:
    ///   - name: 資源檔案名稱，不包含副檔名，例如 `"player"`
    ///   - extension: 資源檔案的副檔名，不包含句點，例如 `"html"`
    /// - Returns: 尚未代入設定參數的 HTML 模板字串
    /// - Throws:
    ///   - `PlayerViewError.resourceNotFound`：找不到指定資源時拋出
    ///   - 檔案無法讀取或無法以 UTF-8 解碼時，拋出對應的讀取錯誤
    func loadHTMLTemplate(forResource name: String?, withExtension `extension`: String?) throws -> String {
        guard let url = url(forResource: name, withExtension: `extension`) else { throw PlayerViewError.resourceNotFound }
        return try String(contentsOf: url, encoding: .utf8)
    }
}

// MARK: - String
extension String {
    
    /// 從 YouTube 網址中解析出 Video ID
    ///
    /// - Returns: 成功解析則返回 11 碼的 Video ID 字串，失敗則返回 nil
    func extractYouTubeVideoID() -> String? {
        
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 針對標準網址 => https://www.youtube.com/watch?v=dQw4w9WgXcQ
        if let url = URL(string: trimmed), let queryItems = url.queryItems {
            if let videoID = queryItems.first(where: { $0.name == "v" })?.value { return videoID }
        }
        
        // 針對其他變體網址 => https://www.youtube.com/shorts/dQw4w9WgXcQ
        let pattern = #"(?:youtu\.be\/|youtube\.com\/(?:v\/|embed\/|watch\?v=|shorts\/))([a-zA-Z0-9_-]{11})"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        
        if let match = regex.firstMatch(in: trimmed, options: [], range: range) {
            if let videoIDRange = Range(match.range(at: 1), in: trimmed) { return String(trimmed[videoIDRange]) }
        }
        
        return nil
    }
}

// MARK: - URL
extension URL {
    
    /// 擴充 URL 屬性：方便直接從小寫的 URL 物件獲取 Query 參數陣列
    var queryItems: [URLQueryItem]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return [] }
        return components.queryItems
    }
}


// MARK: - 建立 WKWebView
extension WKWebView {
    
    /// 建立並設定供播放器使用的 WebView
    ///
    /// 預設使用黑色背景，停用捲動與彈性回彈，並透過 autoresizing mask 隨父視圖調整寬度與高度
    ///
    /// - Parameters:
    ///   - target: 同時遵循 `WKNavigationDelegate` 與 `WKUIDelegate` 的事件處理對象
    ///   - frame: WebView 的初始位置與尺寸
    ///   - configuration: 建立 WebView 時使用的設定
    /// - Returns: 已完成播放器基本設定的 WebView
    static func maker(target: WKNavigationDelegate & WKUIDelegate, with frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        
        let webView = WKWebView(frame: frame, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        webView.backgroundColor = .black
        webView.isOpaque = false

        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        webView.navigationDelegate = target
        webView.uiDelegate = target
        
        return webView
    }
}
