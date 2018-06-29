//
//  AudioManager.swift
//  wallabag
//
//  Created by Keith Moon on 26/06/2018.
//  Copyright © 2018 maxime marinel. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class AudioManager: UIResponder {
    
    enum State {
        case notPlaying
        case playing
        case paused
    }
    
    static var shared: AudioManager = AudioManager()
    
    lazy var speechSynthetizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    var nowPlaying: MPNowPlayingInfoCenter = .default()
    private(set) var state: State = .notPlaying
    
    var speechRate: Float {
        get {
            return Setting.getSpeechRate()
        }
        set {
            Setting.setSpeechRate(value: newValue)
        }
    }
    
    func speak(_ entry: Entry) {
        
        guard let title = entry.title, let content = entry.speakableContent else { return }
        
        let toSpeak = "\(title). \(content)"
        nowPlaying.nowPlayingInfo = nowPlayingAttributes(for: entry)
        addSpeakableContent(toSpeak)
    }
    
    func addSpeakableContent(_ content: String) {
        
        let utterance = AVSpeechUtterance(string: content)
        utterance.rate = speechRate
        utterance.voice = Setting.getSpeechVoice()
        speechSynthetizer.speak(utterance)
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        state = .playing
    }
    
    func pause() {
        guard state == .playing else { return }
        speechSynthetizer.pauseSpeaking(at: .word)
        
        state = .paused
    }
    
    func resume() {
        guard state == .paused else { return }
        speechSynthetizer.continueSpeaking()
        
        state = .playing
    }
    
    func stop() {
        guard state == .playing || state == .paused else { return }
        
        speechSynthetizer.stopSpeaking(at: .word)
        
        UIApplication.shared.endReceivingRemoteControlEvents()
        
        state = .notPlaying
    }
    
    private func nowPlayingAttributes(for entry: Entry) -> [String: Any] {
        
        var attributes = [String: Any]()
        attributes[MPNowPlayingInfoPropertyMediaType] = NSNumber(value: MPNowPlayingInfoMediaType.audio.rawValue)
        attributes[MPNowPlayingInfoCollectionIdentifier] = "\(entry.id)"
        attributes[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: speechRate)
        attributes[MPNowPlayingInfoPropertyIsLiveStream] = NSNumber(value: false)
        attributes[MPMediaItemPropertyAlbumTitle] = entry.title
        attributes[MPMediaItemPropertyAlbumArtist] = entry.domainName
        
        return attributes
    }
}

// Remote control events
extension AudioManager {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        
        guard let ev = event else { return }
        
        switch (ev.type, ev.subtype, speechSynthetizer.isSpeaking) {
            
        case (.remoteControl, .remoteControlTogglePlayPause, true):
            speechSynthetizer.pauseSpeaking(at: .word)
            
        case (.remoteControl, .remoteControlTogglePlayPause, false):
            speechSynthetizer.continueSpeaking()
            
        case (.remoteControl, .remoteControlPlay, _):
            speechSynthetizer.continueSpeaking()
            
        case (.remoteControl, .remoteControlPause, _):
            speechSynthetizer.pauseSpeaking(at: .word)
            
        case (.remoteControl, .remoteControlStop, _):
            speechSynthetizer.stopSpeaking(at: .word)
            
        default:
            break
        }
    }
}
