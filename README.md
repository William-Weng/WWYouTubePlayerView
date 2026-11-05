[English](./README.en.md) | [正體中文](./README.md)

# [WWYouTubePlayerView](https://swiftpackageindex.com/William-Weng)

[![Swift-5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://developer.apple.com/swift/)
[![iOS-17.0](https://img.shields.io/badge/iOS-17.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWYouTubePlayerView)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

`WWYouTubePlayerView` 是一個以 `WKWebView` 封裝 [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference) 的 UIKit 播放器 View。

它提供影片載入、播放控制、音量與播放速率設定、播放資訊查詢，以及透過 `PlayerViewDelegate` 接收播放器狀態、時間與錯誤事件。

https://github.com/user-attachments/assets/86d92c3d-cd19-44c4-8c28-9f9451bc290d

## 📦 [安裝設定](https://github.com/youtube/youtube-ios-player-helper)

### 使用 Swift Package Manager

在 Xcode 中選擇：

`File` → `Add Package Dependencies...`

接著輸入套件 repository URL，選擇要使用的版本，並將套件加入 App target。

如果這是本地套件，也可以在 Xcode 中使用：

`File` → `Add Package Dependencies...` → `Add Local...`

安裝完成後，將該套件匯入目標後，就可以使用了：

```swift
import WWYouTubePlayerView
```

## 📚 [API 總覽](https://www.letswrite.tw/youtube-iframe-api/)

### 公開參數

| 屬性 | 型別 | 說明 |
| --- | --- | --- |
| `delegate` | `(any PlayerViewDelegate)?` | 播放器事件的委派物件；可接收播放器就緒、播放狀態改變、目前播放時間更新、YouTube 錯誤與 WebView / JavaScript 等一般錯誤通知。 |
| `isReady` | `Bool` | 播放器是否已完成初始化並可接受指令；只有其值為 `true` 時，才能執行播放控制或查詢播放資訊。此屬性為 `private(set)`，只能讀取。 |
| `currentvideoId` | `String?` | 目前載入或備妥的 YouTube 影片 ID；呼叫 `load(videoId:playerVars:)`、`loadVideo(videoId:startSeconds:)` 或 `cueVideo(videoId:startSeconds:)` 後會更新。此屬性為 `private(set)`，只能讀取。 |
| `debugLoggingEnabled` | `Bool` | 是否在 Console 輸出以 `[WWYouTubePlayerView]` 為前綴的除錯訊息；設為 `false` 時不輸出記錄，但錯誤仍會透過 `delegate` 回報。 |

### 公開函數

| 方法 | 用途 |
| --- | --- |
| `parsevideoId(url:)` | 從完整的 YouTube 網址中解析並提取出 11 碼的 Video ID。 |
| `load(videoId:playerVars:)` | 重新建立 WebView，並載入指定影片。 |
| `removePlayer()` | 移除目前的 YouTube 播放器，並清理相關狀態與 WebView 資源。 |
| `loadVideo(videoId:startSeconds:)` | 在已就緒的播放器中載入影片，並嘗試播放。 |
| `cueVideo(videoId:startSeconds:)` | 在已就緒的播放器中備妥影片，但不主動播放。 |
| `play()` | 要求播放器開始或繼續播放目前的影片。 |
| `pause()` | 要求播放器暫停目前的影片。 |
| `stop()` | 要求播放器停止播放。 |
| `mute()` | 要求播放器開啟靜音。 |
| `unmute()` | 要求播放器關閉靜音。 |
| `seek(to:allowSeekAhead:)` | 要求播放器跳轉至指定的播放時間。 |
| `loadVideo(videoId:startSeconds:)` | 在目前已就緒的播放器中載入指定影片，並嘗試開始播放。 |
| `cueVideo(videoId:startSeconds:)` | 在目前已就緒的播放器中備妥指定影片，不主動開始播放，不會重新建立 WebView 或重新載入 HTML 模板。 |
| `setVolume(_:)` | 要求播放器設定音量。 |
| `setPlaybackRate(_:)` | 要求播放器設定播放速率。 |
| `currentTime(completion:)` | 查詢目前的播放時間。 |
| `duration(completion:)` | 查詢影片的總長度。 |
| `playerState(completion:)` | 查詢目前的播放狀態。 |

## 📡 Delegate 說明

`WWYouTubePlayerViewDelegate` 用來接收 YouTube 播放器的事件，包括播放器就緒、播放狀態改變、目前播放時間更新，以及 YouTube 或 WebView / JavaScript 產生的錯誤。

### Delegate 方法

| 方法 | 觸發時機 | 說明 |
|---|---|---|
| `playerViewDidBecomeReady(_:)` | 播放器完成初始化並可接受指令時 | 此時 `isReady` 會變為 `true`，可以開始呼叫 `play()`、`pause()`、`seek(to:allowSeekAhead:)`、`currentTime(completion:)` 等方法。 |
| `playerView(_:didChangeTo:)` | 播放狀態改變時 | 回傳目前的 `PlayerState`，例如播放中、暫停、緩衝、結束或影片已備妥。 |
| `playerView(_:didChangeCurrentTime:)` | 目前播放時間更新時 | 回傳目前的播放位置，單位為秒。 |
| `playerView(_:didFailWith:)` | 播放器發生錯誤時 | 回傳 `WWYouTubePlayerView.PlayerError`。`.youTube(code:)` 為 YouTube IFrame Player 回報的原生錯誤代碼；`.local(_:)` 為播放器封裝的本地錯誤，例如 origin URL 建立失敗或播放器尚未就緒；`.underlying(_:)` 為 HTML 模板讀取、JSON 序列化、WebView 導覽、JavaScript 執行或 WebView content process 終止等底層錯誤。 |

- 需要第一次建立播放器、更換播放器設定，或希望完全重置播放器時，使用 `load(videoId:playerVars:)`。
- 播放器已就緒，只是要切換影片時，使用 `loadVideo(videoId:startSeconds:)`。
- 播放器已就緒，但希望先載入影片、等使用者操作後再播放時，使用 `cueVideo(videoId:startSeconds:)`。

## 🧪 [使用範例](https://developer.apple.com/videos/play/wwdc2017/812/)

```swift
import UIKit
import WWYouTubePlayerView

@MainActor
final class ViewController: UIViewController {
    
    @IBOutlet weak var playerView: WWYouTubePlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    func initSetting() {
        
        playerView.delegate = self
        playerView.debugLoggingEnabled = true
        
        if let videoId = WWYouTubePlayerView.parseVideoId(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ") {
            playerView.load(videoId: videoId, playerVars: [.autoplay: 0, .controls: 1, .playsInline: 0])
        }
    }
}

extension ViewController: WWYouTubePlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: WWYouTubePlayerView) {
        playerView.play()
    }
    
    func playerView(_ playerView: WWYouTubePlayerView, didChangeTo state: PlayerState) {
        print("Player state: \(state)")
    }

    func playerView(_ playerView: WWYouTubePlayerView, didChangeCurrentTime currentTime: Double) {
        print("Current time: \(currentTime)")
    }
    
    func playerView(_ playerView: WWYouTubePlayerView, didFailWith error: PlayerError) {
        switch error {
        case .youTube(let code): print("YouTube error code: \(code)")
        case .webView(let error): print("WebView error: \(error.localizedDescription)")
        case .script(let error): print("Player error: \(error.localizedDescription)")
        }
    }
}
```

## ⚠️ 注意事項

- `WWYouTubePlayerView` 標記為 `@MainActor`，請在主執行緒使用。
- `load(videoId:playerVars:)` 會重建 WebView，因此會重置播放器狀態。
- `loadVideo(...)` 與 `cueVideo(...)` 只能在播放器就緒後使用。
- 播放器就緒前呼叫播放控制或查詢方法，會得到 `PlayerViewError.notReady`。
- 套件會使用主 App 的 Bundle Identifier 建立 origin URL，例如 `com.example.MyApp` 會轉為 `https://com.example.myapp`。
- 使用者點擊 HTTP / HTTPS 連結時，播放器會取消 WebView 內部導覽，並交由系統開啟該連結。
