//
//  Enum.swift
//  WWYouTubePlayerView
//
//  Created by William.Weng on 2026/11/4.
//

import Foundation

/// HTML 播放器透過 JavaScript bridge 傳送的事件類型
///
/// 原始值對應訊息內容中 `event` 欄位的字串，必須與 `player.html` 使用的事件名稱一致
enum ReceiveEvent: String {
    
    case ready              // 播放器已準備完成，可以接收操作指令
    case state              // 播放器的播放狀態已變更
    case youtubeError       // YouTube IFrame API 回報播放錯誤
    case time               // 播放器回報目前的播放時間
    case scriptError        // HTML 頁面回報 JavaScript 執行或 API 載入錯誤
}

/// 播放器支援的控制方法
///
/// 原始值對應 JavaScript 播放器的方法名稱，供內部指令流程組合呼叫內容
enum ControlMethod: String {
    
    case playVideo          // 開始或繼續播放
    case pauseVideo         // 暫停播放
    case stopVideo          // 停止播放
    case seekTo             // 跳轉至指定的播放時間
    case loadVideoById      // 載入指定影片並嘗試開始播放
    case cueVideoById       // 備妥指定影片，等待後續播放指令
    case mute               // 開啟靜音
    case unMute             // 關閉靜音
    case setVolume          // 設定播放器音量
    case setPlaybackRate    // 設定播放速率
}

/// 播放器支援的數值查詢方法
///
/// 原始值對應 JavaScript 播放器的方法名稱，供內部查詢流程組合呼叫指令
enum QueryMethod: String {
    
    case getCurrentTime     // 查詢目前的播放時間，單位為秒
    case getDuration        // 查詢影片總長度，單位為秒
    case getPlayerState     // 查詢目前的播放狀態碼
}
