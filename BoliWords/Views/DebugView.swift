//
//  DebugView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftUI
import SwiftData

struct DebugView: View {
    let word: String?
    let frequency: [Character: Int]
    let subWords: [String]
    let onWipeComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("wordIndex") private var wordIndex: Int = 0
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if let word = word {
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
                } else {
                    Text("No word loaded")
                }
            }
            .navigationTitle("Debug Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        showingConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .alert("Wipe Progress?", isPresented: $showingConfirmation) {
                Button("Wipe Everything", role: .destructive) {
                    wipeProgress()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all local and iCloud game progress. This action cannot be undone.")
            }
        }
    }
    
    private func wipeProgress() {
        // Delete all WordProgress records
        try? modelContext.delete(model: WordProgress.self)
        try? modelContext.delete(model: UserStats.self)
        try? modelContext.save()
        
        // Reset AppStorage
        wordIndex = 0
        
        // Notify GameView to clear UI state and reload
        onWipeComplete()
        dismiss()
    }
}
