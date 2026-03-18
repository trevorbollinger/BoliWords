//
//  GameDisplayView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftUI

struct GameDisplayView: View {
    let foundWords: Set<String>
    let allWords: [String]
    
    private var sortedWords: [String] {
        allWords.sorted { a, b in
            if a.count != b.count {
                return a.count < b.count
            }
            return a < b
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Found: \(foundWords.count)")
                    .bold()
                Text("/")
                    .foregroundStyle(.secondary)
                Text("\(allWords.count)")
                    .bold()
                
                if foundWords.count == allWords.count && allWords.count > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .font(.subheadline)
            
            FlowLayout(spacing: 8) {
                ForEach(sortedWords, id: \.self) { word in
                    WordCapsule(word: word, isFound: foundWords.contains(word))
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassModifier(in: RoundedRectangle(cornerRadius: 20))
    }
}

struct WordCapsule: View {
    let word: String
    let isFound: Bool
    @State private var justFound = false
    
    var body: some View {
        Text(isFound ? word : String(repeating: "?", count: word.count))
            .font(.system(.subheadline, design: .monospaced).bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isRevealedColor.opacity(0.15))
            )
            .foregroundColor(isRevealedColor)
            .overlay(
                Capsule()
                    .stroke(isRevealedColor.opacity(justFound ? 0.5 : 0.2), lineWidth: 1)
            )
            .scaleEffect(justFound ? 1.1 : 1.0)
            .onChange(of: isFound) { oldValue, newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        justFound = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation { justFound = false }
                    }
                }
            }
            .transition(.scale.combined(with: .opacity))
    }
    
    private var isRevealedColor: Color {
        if isFound {
            return justFound ? .green : .primary
        } else {
            return .secondary
        }
    }
}


#Preview {
    GameDisplayView(foundWords: ["eat"], allWords: ["eat", "tea", "at", "ate"])
}
