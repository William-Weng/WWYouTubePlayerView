//
//  Handler.swift
//  WWYouTubePlayerView
//
//  Created by William.Weng on 2026/11/4.
//

import WebKit

@MainActor
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    
    weak var target: (any WKScriptMessageHandler)?

    init(target: any WKScriptMessageHandler) {
        self.target = target
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
