[English](./README.en.md) | [正體中文](./README.md)

# [WWYouTubePlayerView](https://swiftpackageindex.com/William-Weng)

[![Swift-5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://developer.apple.com/swift/)
[![iOS-17.0](https://img.shields.io/badge/iOS-17.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWYouTubePlayerView)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

`WWYouTubePlayerView` is a UIKit player view that wraps the YouTube IFrame Player API using `WKWebView`.

It provides video loading, playback controls, volume and playback-rate settings, playback information queries, and delegate events for player state, playback time, and errors through `PlayerViewDelegate`.

## 📦 Installation

### Swift Package Manager

In Xcode, select:

`File` → `Add Package Dependencies...`

Then enter the package repository URL, choose the version you want to use, and add the package to your app target.

If this is a local package, you can also use:

`File` → `Add Package Dependencies...` → `Add Local...`

After installation, import the package into your target:

```swift
import WWYouTubePlayerView
```

## 📚 API Overview

### Public Properties

| Property | Type | Description |
| --- | --- | --- |
| `delegate` | `(any PlayerViewDelegate)?` | The delegate object for player events; receives player-ready notifications, playback-state changes, current-time updates, YouTube errors, and general WebView / JavaScript errors. |
| `isReady` | `Bool` | Indicates whether the player has finished initialization and can accept commands. Playback controls and playback information queries are available only when this value is `true`. This property is `private(set)` and read-only. |
| `currentVideoID` | `String?` | The YouTube video ID that is currently loaded or cued. It is updated after calling `load(videoID:playerVars:)`, `loadVideo(videoID:startSeconds:)`, or `cueVideo(videoID:startSeconds:)`. This property is `private(set)` and read-only. |
| `debugLoggingEnabled` | `Bool` | Determines whether debug messages prefixed with `[WWYouTubePlayerView]` are printed to the Console. When set to `false`, debug logs are disabled, but errors are still reported through `delegate`. |

### Public Methods

| Method | Description |
|---|---|
| `load(videoID:playerVars:)` | Recreates the WebView and loads the specified video. |
| `loadVideo(videoID:startSeconds:)` | Loads a video in an already-ready player and attempts to play it. |
| `cueVideo(videoID:startSeconds:)` | Cues a video in an already-ready player without starting playback automatically. |
| `play()` | Requests that the player start or resume playing the current video. |
| `pause()` | Requests that the player pause the current video. |
| `stop()` | Requests that the player stop playback. |
| `mute()` | Requests that the player mute audio. |
| `unmute()` | Requests that the player unmute audio. |
| `seek(to:allowSeekAhead:)` | Requests that the player seek to the specified playback time. |
| `setVolume(_:)` | Requests that the player set its volume. |
| `setPlaybackRate(_:)` | Requests that the player set its playback rate. |
| `currentTime(completion:)` | Queries the current playback time. |
| `duration(completion:)` | Queries the total duration of the video. |
| `playerState(completion:)` | Queries the current playback state. |

## 📡 Delegate

`PlayerViewDelegate` receives events from the YouTube player, including player readiness, playback-state changes, current-time updates, and errors from YouTube or the WebView / JavaScript layer.

### Delegate Methods

| Method | Triggered When | Description |
|---|---|---|
| `playerViewDidBecomeReady(_:)` | The player finishes initialization and can accept commands | `isReady` becomes `true`; you can then call methods such as `play()`, `pause()`, `seek(to:allowSeekAhead:)`, and `currentTime(completion:)`. |
| `playerView(_:didChangeTo:)` | The playback state changes | Provides the current `PlayerState`, such as playing, paused, buffering, ended, or video cued. |
| `playerView(_:didChangeCurrentTime:)` | The current playback time updates | Provides the current playback position in seconds. |
| `playerView(_:didReceiveYouTubeError:)` | The YouTube IFrame Player reports an error | Provides the native YouTube error code (`code`), which can indicate an unplayable video, unsupported format, or another YouTube-side error. |
| `playerView(_:didFailWith:)` | The player encounters a general error | Provides an `Error`; possible sources include failure to load the HTML template, JSON serialization failure, invalid origin URL creation, WebView navigation errors, JavaScript execution errors, or termination of the WebView content process. |

- Use `load(videoID:playerVars:)` when creating the player for the first time, changing player settings, or completely resetting the player.
- Use `loadVideo(videoID:startSeconds:)` when the player is already ready and you only need to switch videos.
- Use `cueVideo(videoID:startSeconds:)` when the player is already ready, but you want to prepare a video first and wait for user interaction before playing it.

## 🧪 [Usage Example](https://developer.apple.com/videos/play/wwdc2017/812/)

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
        playerView.load(videoID: "dQw4w9WgXcQ", playerVars: [.autoplay: 0, .controls: 1, .playsInline: 0])
    }
}

extension ViewController: PlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: WWYouTubePlayerView) {
        playerView.play()
    }
    
    func playerView(_ playerView: WWYouTubePlayerView, didChangeTo state: PlayerState) {
        print("Player state: \(state)")
    }

    func playerView(_ playerView: WWYouTubePlayerView, didChangeCurrentTime currentTime: Double) {
        print("Current time: \(currentTime)")
    }

    func playerView(_ playerView: WWYouTubePlayerView, didReceiveYouTubeError code: Int) {
        print("YouTube error code: \(code)")
    }

    func playerView(_ playerView: WWYouTubePlayerView, didFailWith error: Error) {
        print("Player error: \(error.localizedDescription)")
    }
}
```

## ⚠️ Important Notes

- `WWYouTubePlayerView` is marked as `@MainActor`; use it on the main thread.
- `load(videoID:playerVars:)` recreates the WebView, so it resets the player state.
- `loadVideo(...)` and `cueVideo(...)` can be used only after the player is ready.
- Calling playback-control or query methods before the player is ready returns `PlayerViewError.notReady`.
- The package uses the main app’s Bundle Identifier to create the origin URL. For example, `com.example.MyApp` becomes `https://com.example.myapp`.
- When the user taps an HTTP / HTTPS link, the player cancels navigation inside the WebView and opens the link in the system browser instead.
