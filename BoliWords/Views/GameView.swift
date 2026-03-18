//
//  GameView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftData
import SwiftUI

private let previewContainer: ModelContainer = {
    let schema = Schema([WordProgress.self, UserStats.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
}()

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progresses: [WordProgress]
    @Query private var userStats: [UserStats]
    
    // Total points calculated from the UserStats model
    private var totalPoints: Int {
        userStats.first?.totalPoints ?? 0
    }
    
    @State private var currentWord: String?
    @State private var frequency: [Character: Int] = [:]
    @State private var subWords: [String] = []
    @State private var showDebugSheet = false
    @State private var showWordListSheet = false
    @State private var keyItems: [KeyItem] = []
    @State private var disabledKeys: Set<UUID> = []
    @State private var currentInput: String = ""
    @State private var foundWords: Set<String> = []
    @State private var validationColor: Color = Color(UIColor.secondarySystemBackground)
    @State private var validationState: ValidationState = .idle
    @State private var tapCount: Int = 0
    @AppStorage("wordIndex") private var wordIndex: Int = 0
    @State private var totalWords: Int = 0
    @State private var selectionStack: [UUID] = []
    
    private var isTargetWordFound: Bool {
        guard let currentWord = currentWord else { return false }
        return foundWords.contains(currentWord.lowercased())
    }
    
    private var completedTargetWords: Set<String> {
        let completed = progresses.filter { progress in
            progress.foundWords.contains(progress.mainWord.lowercased())
        }.map { $0.mainWord.lowercased() }
        return Set(completed)
    }
    
    // Configurable Durations
    private let feedbackDuration: Double = 0.5
    
    
    enum ValidationState {
        case idle, success, error
    }

    var body: some View {
        NavigationStack {
            contentView
            .padding(.horizontal)
            .padding(.bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showWordListSheet) {
                WordListView(onSelectWord: { index in
                    wordIndex = index
                    Task { await loadWord() }
                })
            }
            .sheet(isPresented: $showDebugSheet) {
                DebugView(
                    word: currentWord,
                    frequency: frequency,
                    subWords: subWords,
                    onWipeComplete: {
                        resetGameState()
                    }
                )
            }
            .task {
                totalWords = await WordListLoader.shared.wordCount()
                await loadWord()
            }
            .sensoryFeedback(.success, trigger: validationState) { old, new in
                new == .success
            }
            .sensoryFeedback(.error, trigger: validationState) { old, new in
                new == .error
            }
            .sensoryFeedback(.selection, trigger: tapCount)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack {
            if currentWord != nil {
                pointsDisplay
                
                Spacer()
                
                GameDisplayView(foundWords: foundWords, allWords: subWords)
                
                Spacer()
                
                navigationControls
                keypadSection
            }
        }
    }
    
    private var levelIndicator: some View {
        Text("Word \(wordIndex + 1) of \(totalWords)")
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
    
    private var pointsDisplay: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text("\(totalPoints) Points")
                .font(.headline)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
        }
        .animation(.spring(), value: totalPoints)
    }
    
    private var navigationControls: some View {
        HStack(spacing: 12) {
            Button {
                goToPreviousWord()
            } label: {
                Text("Previous")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .disabled(wordIndex <= 0)
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 20))

            Button {
                goToNextWord()
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .disabled(wordIndex >= totalWords - 1 || !isTargetWordFound)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 20))
        }
        .padding(.horizontal, 5)
        
    }
    
    private var keypadSection: some View {
        KeypadView(
            currentInput: currentInput,
            validationColor: validationColor,
            keys: keyItems,
            disabledKeys: disabledKeys,
            isClearDisabled: currentInput.isEmpty,
            isValidateDisabled: currentInput.count < 3,
            onKeyTap: handleKeyTap(_:),
            onClearTap: handleClearTap,
            onValidateTap: validateInput,
            onShuffleTap: handleShuffleTap,
            onBackspaceTap: handleBackspaceTap
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            levelIndicator
        }
        
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showWordListSheet = true
            } label: {
                Image(systemName: "list.bullet")
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showDebugSheet = true
            } label: {
                Image(systemName: "ladybug")
            }
        }
    }

    private func loadWord() async {
        let maxUnlocked = await WordListLoader.shared.findMaxUnlockedIndex(completedWords: completedTargetWords)
        if wordIndex > maxUnlocked {
            wordIndex = maxUnlocked
        }
        
        if let word = await WordListLoader.shared.getWord(at: wordIndex) {
            currentWord = word
            let freq = await WordListLoader.shared.getFrequency(for: word) ?? [:]
            frequency = freq
            subWords = await WordListLoader.shared.findWords(from: freq)
            keyItems = word.shuffled().map { KeyItem(id: UUID(), character: $0) }
            disabledKeys = []
            currentInput = ""
            
            // Load saved progress
            let descriptor = FetchDescriptor<WordProgress>(
                predicate: #Predicate<WordProgress> { $0.mainWord == word }
            )
            let progress = (try? modelContext.fetch(descriptor))?.first
            foundWords = Set(progress?.foundWords ?? [])
            
            validationColor = Color(UIColor.secondarySystemBackground)
            validationState = .idle
            tapCount = 0
            selectionStack = []
        }
    }

    private func clearInput() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentInput = ""
            disabledKeys.removeAll()
            selectionStack.removeAll()
        }
    }

    private func backspaceInput() {
        guard !selectionStack.isEmpty else { return }
        let lastId = selectionStack.removeLast()
        disabledKeys.remove(lastId)
        if !currentInput.isEmpty {
            currentInput.removeLast()
        }
    }

    private func validateInput() {
        let input = currentInput.lowercased()
        
        if subWords.contains(input) && !foundWords.contains(input) {
            // Success
            validationState = .success
            withAnimation {
                validationColor = .green.opacity(0.3)
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                _ = foundWords.insert(input)
            }
            
            let allFound = foundWords.count == subWords.count
            
            // Save progress
            if let word = currentWord {
                let descriptor = FetchDescriptor<WordProgress>(
                    predicate: #Predicate<WordProgress> { $0.mainWord == word }
                )
                if let progress = (try? modelContext.fetch(descriptor))?.first {
                    progress.foundWords = Array(foundWords)
                    progress.foundAll = allFound
                    progress.totalSubWords = subWords.count
                    progress.lastPlayed = Date()
                } else {
                    let newProgress = WordProgress(
                        mainWord: word,
                        foundWords: Array(foundWords),
                        foundAll: allFound,
                        totalSubWords: subWords.count
                    )
                    modelContext.insert(newProgress)
                }
                try? modelContext.save()
            }
            
            // Increment Points
            if let stats = userStats.first {
                stats.totalPoints += 1
            } else {
                let stats = UserStats(totalPoints: 1)
                modelContext.insert(stats)
            }
            try? modelContext.save()
            
            // Reset input display after feedbackDuration so user can start typing
            DispatchQueue.main.asyncAfter(deadline: .now() + feedbackDuration) {
                clearInput()
                withAnimation {
                    validationColor = Color(UIColor.secondarySystemBackground)
                    validationState = .idle
                }
            }
        } else {
            // Error
            validationState = .error
            withAnimation {
                validationColor = .red.opacity(0.3)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + feedbackDuration) {
                clearInput()
                validationColor = Color(UIColor.secondarySystemBackground)
                validationState = .idle
            }
        }
    }
    
    private func goToPreviousWord() {
        guard wordIndex > 0 else { return }
        wordIndex -= 1
        Task { await loadWord() }
    }
    
    private func goToNextWord() {
        guard wordIndex < totalWords - 1 else { return }
        wordIndex += 1
        Task { await loadWord() }
    }
    
    private func handleKeyTap(_ item: KeyItem) {
        tapCount += 1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentInput.append(item.character)
            disabledKeys.insert(item.id)
            selectionStack.append(item.id)
        }
    }
    
    private func handleClearTap() {
        tapCount += 1
        clearInput()
    }
    
    private func handleShuffleTap() {
        tapCount += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            keyItems.shuffle()
        }
        clearInput()
    }
    
    private func handleBackspaceTap() {
        tapCount += 1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            backspaceInput()
        }
    }

    private func resetGameState() {
        // Refresh UI state
        foundWords = []
        currentInput = ""
        disabledKeys.removeAll()
        selectionStack.removeAll()
        
        // Reload the first word (wordIndex was reset in DebugView)
        Task {
            await loadWord()
        }
    }
}

#Preview {
    GameView()
        .modelContainer(previewContainer)
}
