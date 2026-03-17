//
//  LetterFrequency.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//


import Foundation

// Build a frequency map for a single word
nonisolated func letterFrequency(of word: String) -> [Character: Int] {
    word.reduce(into: [:]) { counts, letter in
        counts[letter, default: 0] += 1
    }
}

// Check if a word can be formed from the letters in a frequency map
nonisolated func canForm(_ word: String, from available: [Character: Int]) -> Bool {
    let wordFreq = letterFrequency(of: word)
    return wordFreq.allSatisfy { letter, count in
        (available[letter] ?? 0) >= count
    }
}