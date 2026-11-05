//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/11/4.
//

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
    
    func playerView(_ playerView: WWYouTubePlayerView, didFailWith error: PlayerError) {
        switch error {
        case .youTube(let code): print("YouTube error code: \(code)")
        case .script(let error): print("Player error: \(error.localizedDescription)")
        }
    }
}
