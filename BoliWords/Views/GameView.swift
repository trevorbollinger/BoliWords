//
//  GameView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftUI

struct GameView: View {
    @State private var currentWord: String?
    @State private var frequency: [Character: Int] = [:]
    @State private var subWords: [String] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    Text("Loading...")
                } else if let word = currentWord {
                    Section("Current Word") {
                        Text(word).font(.title).bold()
                    }
                    
                    Section("Letter Frequency") {
                        ForEach(frequency.keys.sorted(), id: \.self) { char in
                            HStack {
                                Text(String(char).uppercased())
                                Spacer()
                                Text("\(frequency[char] ?? 0)")
                            }
                        }
                    }
                    
                    Section("\(subWords.count) Valid Sub-Words") {
                        ForEach(subWords, id: \.self) { subWord in
                            Text(subWord)
                        }
                    }
                }
            }
            .navigationTitle("Debug View")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await selectRandomWord() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await WordListLoader.shared.load()
                await selectRandomWord()
                isLoading = false
            }
        }
    }

    private func selectRandomWord() async {
        if let word = await WordListLoader.shared.getRandomWord() {
            currentWord = word
            let freq = await WordListLoader.shared.getFrequency(for: word) ?? [:]
            frequency = freq
            subWords = await WordListLoader.shared.findWords(from: freq)
        }
    }
}

#Preview {
    GameView()
}
