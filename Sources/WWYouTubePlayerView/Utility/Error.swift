//
//  Error.swift
//  WWYouTubeWebViewPlayer
//
//  Created by William.Weng on 2026/11/4.
//

import Foundation

/// YouTube 播放器封裝內部定義的錯誤
public enum PlayerViewError: LocalizedError {
    
    case resourceNotFound                   // 找不到播放器的 HTML 資源
    case configurationPlaceholderNotFound   // 模板缺少必要的設定參數佔位符
    case missingBundleIdentifier            // 無法取得 App 的 Bundle Identifier，或其內容為空 (播放器需要使用 Bundle Identifier 建立來源識別 URL)
    case invalidOrigin                      // 無法由 App 的 Bundle Identifier 建立有效的來源識別 URL (預期格式為 `https://<bundle-id>`)
    case notReady                           // 播放器尚未準備完成，無法執行目前的操作 (請等待播放器觸發就緒通知後，再呼叫播放控制或資訊查詢方法)
    case invalidResult                      // 播放器回傳的資料不符合目前操作預期的格式或型別 (例如：查詢播放時間時，未取得可轉換為數值的結果)
}

// MARK: - LocalizedError
public extension PlayerViewError {
    
    /// 錯誤的可讀文字說明。
    ///
    /// 提供各錯誤情況對應的描述，供錯誤顯示或除錯記錄使用。
    var errorDescription: String? {
        
        switch self {
        case .resourceNotFound: return "找不到播放器的 player.html 資源。"
        case .configurationPlaceholderNotFound: return "player.html 缺少播放器設定的佔位符。"
        case .missingBundleIdentifier: return "App 沒有 Bundle Identifier。"
        case .invalidOrigin: return "無法由 Bundle Identifier 建立 origin URL。"
        case .notReady: return "YouTube 播放器尚未準備完成。"
        case .invalidResult: return "YouTube 播放器回傳了非預期的資料。"
        }
    }
}
