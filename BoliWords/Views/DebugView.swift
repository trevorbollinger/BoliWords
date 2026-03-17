//
//  DebugView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftUI

struct DebugView: View {
    let word: String?
    let frequency: [Character: Int]
    let subWords: [String]
    let onRefresh: () -> Void
    
    @Environment(\.dismiss) private var dismiss

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
                    Button {
                        onRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}
