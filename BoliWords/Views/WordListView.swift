//
//  WordListView.swift
//  BoliWords
//
//  Created by Antigravity on 3/17/26.
//

import SwiftUI
import SwiftData

struct WordListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let onSelectWord: (Int) -> Void
    
    @Query(sort: \WordProgress.lastPlayed, order: .reverse) private var progresses: [WordProgress]
    @State private var allWords: [String] = []
    @State private var isLoading = true
    
    private var progressDict: [String: WordProgress] {
        Dictionary(uniqueKeysWithValues: progresses.map { ($0.mainWord, $0) })
    }
    
    private var maxUnlockedIndex: Int {
        let dict = progressDict
        for (index, word) in allWords.enumerated() {
            let progress = dict[word]
            let isCompleted = progress?.foundWords.contains(word.lowercased()) ?? false
            if !isCompleted {
                return index
            }
        }
        return allWords.count > 0 ? allWords.count - 1 : 0
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading word list...")
                } else {
                    List {
                        let dict = progressDict
                        let maxUnlocked = maxUnlockedIndex
                        
                        ForEach(allWords.indices, id: \.self) { index in
                            let word = allWords[index]
                            let progress = dict[word]
                            let isLocked = index > maxUnlocked
                            
                            Button {
                                if !isLocked {
                                    onSelectWord(index)
                                    dismiss()
                                }
                            } label: {
                                WordRow(word: word, progress: progress, index: index + 1, isLocked: isLocked)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLocked)
                        }
                    }
                }
            }
            .navigationTitle("Word List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                allWords = await WordListLoader.shared.allTargetWords()
                isLoading = false
            }
        }
    }
}

struct WordRow: View {
    let word: String
    let progress: WordProgress?
    let index: Int
    let isLocked: Bool
    
    private func percentageColor(for fraction: Double) -> Color {
        if fraction < 0.5 {
            let t = fraction / 0.5
            return Color(red: 1.0, green: t, blue: 0.0)
        } else {
            let t = (fraction - 0.5) / 0.5
            return Color(red: 1.0 - t, green: 1.0, blue: 0.0)
        }
    }
    
    var body: some View {
        HStack {
            Text("\(index).")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 45, alignment: .leading)
            
            let isDiscovered = progress?.foundWords.contains(word.lowercased()) ?? false
            
            if isLocked {
                Text(String(repeating: "?", count: word.count))
                    .font(.body.monospaced())
                    .foregroundColor(.secondary.opacity(0.3))
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            } else if isDiscovered {
                Text(word.uppercased())
                    .font(.body.monospaced())
                    .fontWeight(.medium)
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Spacer()
            } else {
                Text(String(repeating: "?", count: word.count))
                    .font(.body.monospaced())
                    .foregroundColor(.secondary.opacity(0.6))
                
                Spacer()
            }
            
            if let progress = progress, progress.totalSubWords > 0 && progress.foundWords.count > 0 {
                let fraction = Double(progress.foundWords.count) / Double(progress.totalSubWords)
                let color = percentageColor(for: fraction)
                
                Text("\(Int(fraction * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    WordRow(word: "HELLO", progress: nil, index: 1, isLocked: false)
        .padding()
}
