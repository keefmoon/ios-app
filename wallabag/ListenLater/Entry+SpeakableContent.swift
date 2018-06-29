//
//  Entry+SpeakableContent.swift
//  wallabag
//
//  Created by Keith Moon on 25/06/2018.
//  Copyright © 2018 maxime marinel. All rights reserved.
//

import Foundation

extension Entry {
    
    var speakableContent: String? {
        
        guard let content = content else { return nil }
        
        let processedContent = content.replacingOccurrences(of: "<p>", with: ". ")
            .replacingOccurrences(of: "\'", with: "'")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "-", with: " ")
        
        return processedContent
    }
}
