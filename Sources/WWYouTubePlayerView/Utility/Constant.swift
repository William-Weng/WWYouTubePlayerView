//
//  Constant.swift
//  WWYouTubePlayerView
//
//  Created by William.Weng on 2026/11/4.
//

import Foundation

/// YouTube 播放器的播放狀態
public enum PlayerState: Int, Sendable {
    
    case unstarted = -1                             // 尚未開始播放
    case ended = 0                                  // 影片已播放結束
    case playing = 1                                // 正在播放
    case paused = 2                                 // 播放已暫停
    case buffering = 3                              // 正在緩衝影片資料
    case cued = 5                                   // 影片已備妥，等待播放
    case unknown = -999                             // 無法識別的播放狀態
}

/// YouTube 播放器的初始化參數名稱 (playerVars)
public enum PlayerParameter: String, CaseIterable, Sendable {
    
    case autoplay                                   // 是否在播放器載入後嘗試自動播放 (值為 `0` 或 `1`，預設為 `0`)
    case captionLanguage = "cc_lang_pref"           // 偏好的字幕語言 (使用語言代碼，例如 `"en"` 或 `"zh-TW"`；若希望預設顯示字幕，可搭配 `captionLoadPolicy: 1`)
    case captionLoadPolicy = "cc_load_policy"       // 是否預設顯示字幕 (設為 `1` 時要求預設顯示字幕；未設定時，依使用者偏好處理)
    case color                                      // 播放進度列的顏色 (值為 `"red"` 或 `"white"`，預設為 `"red"`)
    case controls                                   // 是否顯示播放器控制介面 (`0` 表示隱藏，`1` 表示顯示，預設為 `1`)
    case disableKeyboard = "disablekb"              // 是否停用播放器的鍵盤控制 (`0` 表示啟用，`1` 表示停用，預設為 `0`)
    case enableJavaScriptAPI = "enablejsapi"        // 是否啟用 JavaScript IFrame API 控制 (值為 `0` 或 `1`)
    case end                                        // 停止播放的位置，以影片起點為基準，單位為秒 (使用正整數；不是相對於 `start` 的播放長度)
    case fullscreenButton = "fs"                    // 是否顯示 YouTube 播放器內建的全螢幕按鈕 (`0` 表示隱藏，`1` 表示顯示，預設為 `1`；不影響 App 自己建立的全螢幕按鈕)
    case interfaceLanguage = "hl"                   // 播放器介面的語言 (例如 `"en"` 或 `"zh-TW"`)
    case annotationLoadPolicy = "iv_load_policy"    // 影片註解的顯示設定 (`1` 表示預設顯示，`3` 表示預設不顯示)
    case list                                       // 要載入的內容識別碼 (與 `listType` 搭配使用，例如播放清單 ID)
    case listType                                   // 要載入的內容類型 (官方列出的值為 `"playlist"` 與 `"user_uploads"`；`"search"` 已不再支援
    case loop                                       // 是否循環播放 (值為 `0` 或 `1`，預設為 `0`；單支影片循環需搭配 `playlist`，並指定同一個影片 ID)
    case origin                                     // 播放器外層頁面的來源識別 (此套件會使用 App 的來源 URL 覆蓋此值，呼叫端通常不需要自行設定)
    case playlist                                   // 接續播放的影片 ID 清單 (使用逗號分隔的字串，例如 `"videoID1,videoID2"`)
    case playsInline = "playsinline"                // 是否在 iOS 上使用內嵌播放 (`0` 表示全螢幕播放，`1` 表示內嵌播放；內嵌播放須搭配 WebView 的 `allowsInlineMediaPlayback`
    case relatedVideos = "rel"                      // 播放結束後，相關影片的來源範圍 (`0` 表示限制為同一頻道的相關影片；`1` 表示使用一般相關影片。此參數無法完全關閉相關影片)
    case start                                      // 起始播放位置，單位為秒 (使用整數秒數；實際位置可能受影片關鍵影格影響)
    case widgetReferrer = "widget_referrer"         // 嵌入 widget 所在頁面的 URL (主要供 YouTube Analytics 辨識實際流量來源，不可用來取代 `origin`)
}


