//
//  Entry+SpeakableContent.swift
//  wallabag
//
//  Created by Keith Moon on 25/06/2018.
//  Copyright © 2018 maxime marinel. All rights reserved.
//

import Foundation

extension Entry {
    
    var speakableContent: [String] {
        
        guard let content = content else { return [] }
        
        let paragraphs = content
            .replacingOccurrences(of: "<p[^>]+>", with: "<p>", options: .regularExpression, range: nil)
            .components(separatedBy: "<p>").filter { $0.count > 0 }
        let processedParagraphs = paragraphs.map(processParagraph)
        
        return processedParagraphs
    }
    
    private func processParagraph(_ paragraph: String) -> String {
        
        let processedContent = paragraph.replacingOccurrences(of: "\'", with: "'")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "-", with: " ")
        
        return processedContent
    }
}
