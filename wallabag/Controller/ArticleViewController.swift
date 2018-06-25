//
//  ArticleViewController.swift
//  wallabag
//
//  Created by maxime marinel on 23/10/2016.
//  Copyright © 2016 maxime marinel. All rights reserved.
//

import UIKit
import TUSafariActivity
import AVFoundation
import RealmSwift

final class ArticleViewController: UIViewController {

    lazy var speechSynthetizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    let analytics = AnalyticsManager()

    var entry: Entry! {
        didSet {
            updateUi()
        }
    }

    var deleteHandler: ((_ entry: Entry) -> Void)?
    var readHandler: ((_ entry: Entry) -> Void)?
    var starHandler: ((_ entry: Entry) -> Void)?
    var addHandler: (() -> Void)?

    @IBOutlet weak var contentWeb: UIWebView!
    @IBOutlet weak var readButton: UIBarButtonItem!
    @IBOutlet weak var starButton: UIBarButtonItem!
    @IBOutlet weak var speechButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!

    @IBAction func add(_ sender: Any) {
        addHandler?()
    }

    @IBAction func read(_ sender: Any) {
        readHandler?(entry)
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func star(_ sender: Any) {
        starHandler?(entry)
        updateUi()
    }

    @IBAction func speech(_ sender: Any) {
        if !speechSynthetizer.isSpeaking {
            let utterance = AVSpeechUtterance(string: entry.content!.withoutHTML)
            utterance.rate = Setting.getSpeechRate()
            utterance.voice = Setting.getSpeechVoice()
            speechSynthetizer.speak(utterance)
            speechButton.image = #imageLiteral(resourceName: "lipsfilled")
            analytics.send(.synthesis(state: true))
            
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
        } else {
            speechSynthetizer.stopSpeaking(at: .word)
            speechButton.image = #imageLiteral(resourceName: "lips")
            analytics.send(.synthesis(state: false))
            
            UIApplication.shared.endReceivingRemoteControlEvents()
        }
    }

    @IBAction func shareMenu(_ sender: UIBarButtonItem) {
        let shareController = UIActivityViewController(activityItems: [URL(string: entry.url!) as Any], applicationActivities: [TUSafariActivity()])
        shareController.excludedActivityTypes = [.airDrop, .addToReadingList, .copyToPasteboard]
        shareController.popoverPresentationController?.barButtonItem = sender

        analytics.send(.shareArticle)
        present(shareController, animated: true)
    }

    @IBAction func deleteArticle(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Delete".localized, message: "Are you sure?".localized, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete".localized, style: .destructive, handler: { _ in
            self.deleteHandler?(self.entry)
            _ = self.navigationController?.popToRootViewController(animated: true)
        })
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.popoverPresentationController?.barButtonItem = sender

        present(alert, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        analytics.sendScreenViewed(.articleView)
        navigationItem.title = entry.title
        updateUi()
        setupAccessibilityLabel()
        contentWeb.load(entry: entry)
        contentWeb.scrollView.delegate = self
        contentWeb.backgroundColor = ThemeManager.manager.getBackgroundColor()

        UIApplication.shared.isIdleTimerDisabled = true

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        speechSynthetizer.stopSpeaking(at: .immediate)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func updateUi() {
        readButton?.image = entry.isArchived ? #imageLiteral(resourceName: "readed") : #imageLiteral(resourceName: "unreaded")
        starButton?.image = entry.isStarred ? #imageLiteral(resourceName: "starred") : #imageLiteral(resourceName: "unstarred")
    }
}

extension ArticleViewController: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.scrollView.setContentOffset(CGPoint(x: 0.0, y: Double(self.entry.screenPosition)), animated: true)
    }
}

extension ArticleViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        try? Realm().write {
            entry.screenPosition = Float(scrollView.contentOffset.y)
        }
    }
}

extension ArticleViewController {
    private func setupAccessibilityLabel() {
        readButton.accessibilityLabel = "Read".localized
        starButton.accessibilityLabel = "Star".localized
        speechButton.accessibilityLabel = "Speech".localized
        deleteButton.accessibilityLabel = "Delete".localized
    }
}

// Remote control events
extension ArticleViewController {
    
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
