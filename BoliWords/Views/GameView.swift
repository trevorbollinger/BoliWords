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
    @State private var showDebugSheet = false
    @State private var keyItems: [KeyItem] = []
    @State private var disabledKeys: Set<UUID> = []
    @State private var currentInput: String = ""
    @State private var foundWords: Set<String> = []
    @State private var validationColor: Color = Color(UIColor.secondarySystemBackground)
    
    enum ValidationState {
        case idle, success, error
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading word list...")
                } else if let word = currentWord {
                    Spacer()
                
                    
                    HStack {
                        Text("Found: \(foundWords.count)")
                            .bold()
                        Text("/")
                            .foregroundStyle(.tertiary)
                        Text("\(subWords.count) possible")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(foundWords.sorted(), id: \.self) { word in
                                Text(word)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 50)
                    .padding(.vertical, 5)
                    
                    Spacer()
                    
                    Text(currentInput.isEmpty ? " " : currentInput)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(4)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(validationColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .animation(.default, value: validationColor)
                    
                    HStack(spacing: 20) {
                        Button {
                            clearInput()
                        } label: {
                            Text("Clear")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(currentInput.isEmpty)
                        
                        Button {
                            validateInput()
                        } label: {
                            Text("Validate")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(currentInput.isEmpty ? Color.gray.opacity(0.3) : Color.green)
                                .foregroundColor(currentInput.isEmpty ? .gray : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(currentInput.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    KeypadView(keys: keyItems, disabledKeys: disabledKeys) { item in
                        print("Tapped \(item.character)")
                        currentInput.append(item.character)
                        disabledKeys.insert(item.id)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDebugSheet = true
                    } label: {
                        Image(systemName: "ladybug")
                    }
                }
            }
            .sheet(isPresented: $showDebugSheet) {
                DebugView(
                    word: currentWord,
                    frequency: frequency,
                    subWords: subWords,
                    onRefresh: {
                        Task { await selectRandomWord() }
                    }
                )
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
            keyItems = word.map { KeyItem(id: UUID(), character: $0) }
            disabledKeys = []
            currentInput = ""
            foundWords = []
            validationColor = Color(UIColor.secondarySystemBackground)
        }
    }

    private func clearInput() {
        currentInput = ""
        disabledKeys.removeAll()
    }

    private func validateInput() {
        let input = currentInput.lowercased()
        
        if subWords.contains(input) && !foundWords.contains(input) {
            // Success
            withAnimation {
                validationColor = .green.opacity(0.3)
            }
            foundWords.insert(input)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                clearInput()
                validationColor = Color(UIColor.secondarySystemBackground)
            }
        } else {
            // Error
            withAnimation {
                validationColor = .red.opacity(0.3)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                clearInput()
                validationColor = Color(UIColor.secondarySystemBackground)
            }
        }
    }
}

#Preview {
    GameView()
}
