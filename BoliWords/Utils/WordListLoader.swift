//
//  WordListLoader.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//


// MARK: - WordListLoader.swift

import Foundation

actor WordListLoader {
    static let shared = WordListLoader()

    private(set) var words: [String] = []

    // The pre-computed cache — built once, read many times
    private(set) var frequencyCache: [String: [Character: Int]] = [:]

    func load(from filename: String = "wordlist") async {
        guard words.isEmpty else { return }

        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt") else {
            assertionFailure("\(filename).txt not found in bundle")
            return
        }

        guard let raw = try? String(contentsOf: url, encoding: .utf8) else {
            assertionFailure("Failed to read word list")
            return
        }

        // Your list is already clean, so minimal filtering needed here
        let loaded = raw
            .components(separatedBy: .newlines)
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            
        // Build the cache in one pass at launch
        var cache: [String: [Character: Int]] = [:]
        cache.reserveCapacity(loaded.count)
        for word in loaded {
            cache[word] = letterFrequency(of: word)
        }

        self.words = loaded
        self.frequencyCache = cache
        print("WordListLoader: Loaded \(self.words.count) words.")
    }

    func getRandomWord() -> String? {
        words.randomElement()
    }

    func getFrequency(for word: String) -> [Character: Int]? {
        frequencyCache[word]
    }

    /// Finds all words in the wordlist that can be formed using the provided letter frequencies.
    func findWords(from available: [Character: Int]) -> [String] {
        words.filter { word in
            guard let wordFreq = frequencyCache[word] else { return false }
            return wordFreq.allSatisfy { (char, count) in
                (available[char] ?? 0) >= count
            }
        }.sorted { $0.count > $1.count || ($0.count == $1.count && $0 < $1) }
    }
}
