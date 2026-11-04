//
//  Protocol.swift
//  WWYouTubePlayerView
//
//  Created by William.Weng on 2026/11/4.
//

import Foundation

/// 接收 YouTube 播放器的就緒、播放狀態、錯誤及播放時間通知
@MainActor
public protocol PlayerViewDelegate: AnyObject {

    /// 播放器已準備完成，可以接收播放控制與資訊查詢指令
    ///
    /// 此通知對應播放器的 `onReady` 事件，不代表影片已開始播放，也不等同於影片的 `.cued` 狀態
    ///
    /// - Parameter playerView: 已準備完成的播放器視圖
    func playerViewDidBecomeReady(_ playerView: WWYouTubePlayerView)

    /// 播放器的播放狀態已變更
    ///
    /// - Parameters:
    ///   - playerView: 發出通知的播放器視圖
    ///   - state: 目前的播放狀態，例如播放中、暫停或緩衝中
    func playerView(_ playerView: WWYouTubePlayerView, didChangeTo state: PlayerState)

    /// 播放器收到 YouTube IFrame API 回傳的播放錯誤
    ///
    /// 保留原始錯誤碼，讓呼叫端自行記錄或判斷處理方式；此錯誤碼不一定與播放器畫面上顯示的完整錯誤代碼相同
    ///
    /// - Parameters:
    ///   - playerView: 發出通知的播放器視圖
    ///   - code: YouTube IFrame API 的 `onError` 事件回傳的原始錯誤碼
    func playerView(_ playerView: WWYouTubePlayerView, didReceiveYouTubeError code: Int)

    /// 播放器發生載入、腳本執行或本地操作錯誤
    ///
    /// 例如來源設定無效、播放器尚未就緒、JavaScript 執行失敗，或 WebView 載入失敗
    ///
    /// YouTube IFrame API 的播放錯誤碼會透過 `playerView(_:didReceiveYouTubeError:)` 另外回報
    ///
    /// - Parameters:
    ///   - playerView: 發出通知的播放器視圖
    ///   - error: 發生的錯誤，可透過 `localizedDescription` 取得文字說明
    func playerView(_ playerView: WWYouTubePlayerView, didFailWith error: Error)
    
    /// 播放器回報目前的播放時間
    ///
    /// 可用於更新播放進度、時間標籤或同步其他介面；回報頻率由播放器封裝的實作決定。
    ///
    /// - Parameters:
    ///   - playerView: 發出通知的播放器視圖
    ///   - seconds: 目前播放位置，以秒為單位
    func playerView(_ playerView: WWYouTubePlayerView, didChangeCurrentTime seconds: Double)
}

// MARK: - 提供預設空實作，讓採用者只需處理關心的播放器事件
public extension PlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: WWYouTubePlayerView) {}
    func playerView(_ playerView: WWYouTubePlayerView, didChangeTo state: PlayerState) {}
    func playerView(_ playerView: WWYouTubePlayerView, didReceiveYouTubeError code: Int) {}
    func playerView(_ playerView: WWYouTubePlayerView, didFailWith error: Error) {}
    func playerView(_ playerView: WWYouTubePlayerView, didChangeCurrentTime seconds: Double) {}
}
