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

/// 播放器統一回報的錯誤
public enum PlayerError: Error, Sendable {

    case youTube(_ code: Int)               // YouTube IFrame API 的 `onError` 事件回傳的播放錯誤碼
    case script(_ error: Error)             // APP手機端的 `JavaScript` 執行錯誤
}

