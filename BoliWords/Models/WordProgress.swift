//
//  WordProgress.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import Foundation
import SwiftData

@Model
final class WordProgress {
    var mainWord: String = ""
    var foundWords: [String] = []
    var foundAll: Bool = false
    var totalSubWords: Int = 0
    var lastPlayed: Date = Date()
    
    init(mainWord: String, foundWords: [String] = [], foundAll: Bool = false, totalSubWords: Int = 0) {
        self.mainWord = mainWord
        self.foundWords = foundWords
        self.foundAll = foundAll
        self.totalSubWords = totalSubWords
        self.lastPlayed = Date()
    }
}
