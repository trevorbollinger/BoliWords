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
    
    private final class BundleToken {}

    private(set) var words: [String] = []
    private(set) var targetWords: [String] = []
    
    private struct WordInfo {
        let word: String
        let mask: UInt32
        let counts: [UInt8]
        let length: Int
        
        init(_ word: String) {
            self.word = word
            self.length = word.count
            var m: UInt32 = 0
            var c = [UInt8](repeating: 0, count: 26)
            for char in word.lowercased() {
                if let scalar = char.unicodeScalars.first, scalar.value >= 97 && scalar.value <= 122 {
                    let index = Int(scalar.value - 97)
                    m |= (1 << index)
                    c[index] += 1
                }
            }
            self.mask = m
            self.counts = c
        }
        
        @inline(__always)
        func canForm(_ other: WordInfo) -> Bool {
            // Mask and length checks should be done before calling this for speed
            for i in 0..<26 {
                if other.counts[i] > self.counts[i] {
                    return false
                }
            }
            return true
        }
    }

    private var wordInfos: [WordInfo] = []

    private static func resourceURL(named filename: String) -> URL? {
        let bundles = [Bundle.main, Bundle(for: BundleToken.self)] + Bundle.allBundles + Bundle.allFrameworks
        let uniqueBundles = Array(Set(bundles))
        
        for bundle in uniqueBundles {
            if let url = bundle.url(forResource: filename, withExtension: "txt") {
                return url
            }
        }
        
        return nil
    }
    
    #if DEBUG
    private static func debugResourceURL(named filename: String, filePath: StaticString = #filePath) -> URL? {
        let sourceFileURL = URL(fileURLWithPath: "\(filePath)")
        let resourcesURL = sourceFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources", isDirectory: true)
        let fileURL = resourcesURL.appendingPathComponent("\(filename).txt")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    #endif

    private static func loadWordList(named filename: String) -> [String] {
        let resolvedURL = resourceURL(named: filename)
        #if DEBUG
        let url = resolvedURL ?? debugResourceURL(named: filename)
        #else
        let url = resolvedURL
        #endif
        
        guard let url else {
            let searchedBundles = ([Bundle.main, Bundle(for: BundleToken.self)] + Bundle.allBundles + Bundle.allFrameworks)
                .map(\.bundlePath)
                .joined(separator: "\n")
            print("WordListLoader: \(filename).txt not found. Searched bundles:\n\(searchedBundles)")
            return []
        }

        guard let raw = try? String(contentsOf: url, encoding: .utf8) else {
            print("WordListLoader: Failed to read \(filename).txt at \(url.path)")
            return []
        }

        return raw
            .components(separatedBy: .newlines)
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func load() async {
        guard words.isEmpty || targetWords.isEmpty || wordInfos.isEmpty else { return }

        let loadedWords = Self.loadWordList(named: "wordlist")
        let loadedTargetWords = Self.loadWordList(named: "targetwords")
        
        guard !loadedWords.isEmpty, !loadedTargetWords.isEmpty else {
            print("WordListLoader: Skipping load because one or more word lists are empty.")
            return
        }

        let infos = loadedWords.map { WordInfo($0) }

        self.words = loadedWords
        self.targetWords = loadedTargetWords
        self.wordInfos = infos
        print("WordListLoader: Loaded \(self.words.count) words. Loaded \(self.targetWords.count) target words.")
    }

    func wordCount() async -> Int {
        await load()
        return targetWords.count
    }

    func allTargetWords() async -> [String] {
        await load()
        return targetWords
    }

    func getWord(at index: Int) async -> String? {
        await load()
        guard index >= 0 && index < targetWords.count else { return nil }
        return targetWords[index]
    }

    /// Finds the highest level index a user is allowed to access.
    /// A level is unlocked if all previous levels have their target words found.
    func findMaxUnlockedIndex(completedWords: Set<String>) async -> Int {
        await load()
        for (index, word) in targetWords.enumerated() {
            if !completedWords.contains(word.lowercased()) {
                return index
            }
        }
        return Swift.max(0, targetWords.count - 1)
    }

    func getFrequency(for word: String) async -> [Character: Int]? {
        await load()
        // Only called once per level load, so on-the-fly conversion is fine
        return WordInfo(word).counts.enumerated().reduce(into: [:]) { dict, pair in
            if pair.element > 0 {
                let char = Character(UnicodeScalar(UInt8(97 + pair.offset)))
                dict[char] = Int(pair.element)
            }
        }
    }

    /// Finds all words in the wordlist that can be formed using the provided letter frequencies.
    func findWords(from available: [Character: Int]) async -> [String] {
        await load()
        // Convert input frequencies to optimized WordInfo for fast search
        let availableInfo = WordInfo(available.reduce("") { $0 + String(repeating: $1.key, count: $1.value) })
        let targetMask = availableInfo.mask
        
        return wordInfos.filter { info in
            if info.length > availableInfo.length { return false }
            if (info.mask & ~targetMask) != 0 { return false }
            return availableInfo.canForm(info)
        }.map { $0.word }
        .sorted { $0.count > $1.count || ($0.count == $1.count && $0 < $1) }
    }
}
