//
//  ArticleViewController+RemoteControl.swift
//  wallabag
//
//  Created by Keith Moon on 28/06/2018.
//  Copyright © 2018 maxime marinel. All rights reserved.
//

import Foundation

// Remote control events
extension ArticleViewController {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        
        guard let ev = event else { return }
        
        switch (ev.type, ev.subtype, audioManager.state) {
            
        case (.remoteControl, .remoteControlTogglePlayPause, .playing):
            audioManager.pause()
            
        case (.remoteControl, .remoteControlTogglePlayPause, .paused):
            audioManager.resume()
            
        case (.remoteControl, .remoteControlPlay, _):
            audioManager.resume()
            
        case (.remoteControl, .remoteControlPause, _):
            audioManager.pause()
            
        case (.remoteControl, .remoteControlStop, _):
            audioManager.stop()
            
        default:
            break
        }
    }
}
