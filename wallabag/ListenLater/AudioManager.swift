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

class AudioManager {
    
    enum State {
        case notPlaying
        case playing
        case paused
    }
    
    static var shared: AudioManager = AudioManager()
    
    lazy var speechSynthetizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    var remoteCommandCenter: MPRemoteCommandCenter = .shared()
    var nowPlaying: MPNowPlayingInfoCenter = .default()
    private(set) var state: State = .notPlaying {
        didSet {
            switch state {
            case .notPlaying:
                nowPlaying.playbackState = .stopped
                
            case .paused:
                nowPlaying.playbackState = .paused
                
            case .playing:
                nowPlaying.playbackState = .playing
            }
        }
    }
    
    init() {
        
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            
            guard let strongSelf = self else { return .commandFailed }
            
            switch strongSelf.state {
            case .playing:
                strongSelf.pause()
                return .success
            case .paused:
                strongSelf.resume()
                return .success
            case .notPlaying:
                return .noSuchContent
            }
        }
        
        remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            
            guard let strongSelf = self else { return .commandFailed }
            
            switch strongSelf.state {
            case .playing:
                return .success
            case .paused:
                strongSelf.resume()
                return .success
            case .notPlaying:
                return .noSuchContent
            }
        }
        
        remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            
            guard let strongSelf = self else { return .commandFailed }
            
            switch strongSelf.state {
            case .playing:
                strongSelf.pause()
                return .success
            case .paused:
                return .success
            case .notPlaying:
                return .noSuchContent
            }
        }
        
        remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = nowPlayingSupportedSpeechRates()
        remoteCommandCenter.changePlaybackRateCommand.addTarget { event -> MPRemoteCommandHandlerStatus in
            guard let changeRateEvent = event as? MPChangePlaybackRateCommandEvent else {
                return .commandFailed
            }
            Setting.setSpeechRate(value: changeRateEvent.playbackRate)
            // TODO: Pause and add new partial utterance with new speech rate.
            return .success
        }
    }
    
    var speechRate: Float {
        get {
            return Setting.getSpeechRate()
        }
        set {
            Setting.setSpeechRate(value: newValue)
        }
    }
    
    func speak(_ entry: Entry) {
        
        guard let title = entry.title else { return }
        
        var content = entry.speakableContent
        content.insert(title, at: 0)
        nowPlaying.nowPlayingInfo = nowPlayingAttributes(for: entry)
        addSpeakableContent(content)
    }
    
    func addSpeakableContent(_ content: [String]) {
        
        for paragraph in content {
            
            let utterance = AVSpeechUtterance(string: paragraph)
            utterance.rate = speechRate
            utterance.voice = Setting.getSpeechVoice()
            speechSynthetizer.speak(utterance)
        }
        
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
    
    private func nowPlayingSupportedSpeechRates() -> [NSNumber] {
    
        var rates = [NSNumber]()
        let increment: Float = 0.5
        var speechRate: Float = AVSpeechUtteranceMinimumSpeechRate
        
        while speechRate < AVSpeechUtteranceDefaultSpeechRate {
            
            rates.append(NSNumber(value: speechRate))
            speechRate += increment
        }
        
        speechRate = AVSpeechUtteranceDefaultSpeechRate
        
        while speechRate < AVSpeechUtteranceMaximumSpeechRate {
            
            rates.append(NSNumber(value: speechRate))
            speechRate += increment
        }
        
        speechRate = AVSpeechUtteranceMaximumSpeechRate
        rates.append(NSNumber(value: speechRate))
        
        return rates
    }
}
