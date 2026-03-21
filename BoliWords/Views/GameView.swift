//
//  GameView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftData
import SwiftUI

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
    @State private var showCustomizationSheet = false
    @State private var showWordListSheet = false
    @State private var showTutorialSheet = false
    @State private var keyItems: [KeyItem] = []
    @State private var disabledKeys: Set<UUID> = []
    @State private var currentInput: String = ""
    @State private var foundWords: Set<String> = []
    @State private var validationColor: Color = .clear
    @State private var validationState: ValidationState = .idle
    @State private var tapCount: Int = 0
    @AppStorage("wordIndex") private var wordIndex: Int = 0
    @AppStorage("debugMode") private var debugMode: Bool = false
    @State private var totalWords: Int = 0
    @State private var selectionStack: [UUID] = []
    @State private var debugToggleCount: Int = 0
    @State private var lastDebugTap: Date = .distantPast
    @State private var bonusPoints: [BonusPoint] = []

    struct BonusPoint: Identifiable {
        let id: UUID
        var offset: CGSize
    }

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

    private var selectedThemeColor: ThemeColor? {
        ThemeColor(rawValue: userStats.first?.themeColor ?? ThemeColor.none.rawValue)
    }

    // Configurable Durations
    private let feedbackDuration: Double = 0.5

    enum ValidationState {
        case idle, success, error
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if let color = selectedThemeColor?.color {
                    color.opacity(0.2)
                        .ignoresSafeArea()
                }
                
                contentView
                    .padding(.horizontal)
                    .padding(.bottom)

                // Floating Points Overlay
                ForEach(bonusPoints) { point in
                    Text("+1")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                        .offset(point.offset)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .modifier(SheetModifier(
                showWordListSheet: $showWordListSheet,
                showDebugSheet: $showDebugSheet,
                showCustomizationSheet: $showCustomizationSheet,
                showTutorialSheet: $showTutorialSheet,
                wordIndex: $wordIndex,
                totalWords: $totalWords,
                currentWord: currentWord,
                frequency: frequency,
                subWords: subWords,
                loadWord: loadWord,
                resetGameState: resetGameState,
                markTutorialAsFinished: markTutorialAsFinished
            ))
            .modifier(FeedbackModifier(
                validationState: validationState,
                tapCount: tapCount,
                userStats: userStats,
                showTutorialSheet: $showTutorialSheet,
                loadWord: loadWord,
                totalWords: $totalWords
            ))
        }
        .tint(selectedThemeColor?.color)
    }

    @ViewBuilder
    private var contentView: some View {
        VStack {
            if currentWord != nil {
                levelDisplayWithBack

                Spacer()

                GameDisplayView(foundWords: foundWords, allWords: subWords, targetWord: currentWord)
                    .id(currentWord)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                navigationControls
                keypadSection
            }
        }
    }

    private var levelIndicator: some View {
        Text("Word \(wordIndex + 1) of \(totalWords)")
            .font(.subheadline)
//            .monospacedDigit()
            .foregroundStyle(.secondary)
            .onTapGesture {
                let now = Date()
                if now.timeIntervalSince(lastDebugTap) > 0.8 {
                    debugToggleCount = 1
                } else {
                    debugToggleCount += 1
                }
                lastDebugTap = now

                if debugToggleCount >= 8 {
                    debugMode.toggle()
                    debugToggleCount = 0
                }
            }
    }

    private var levelDisplayWithBack: some View {
        ZStack() {
            if wordIndex >= 0 {
                HStack {
                    Button {
                        goToPreviousWord()
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.title)
                    }
                    Spacer()
                }
            }
            levelIndicator
        }
        .padding(.vertical, 4)
    }

    private var pointsDisplay: some View {
        HStack {
            Text("\(totalPoints) Points")
                .font(.headline)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
        }
        .animation(.spring(), value: totalPoints)
    }

    private var navigationControls: some View {
        Button {
            goToNextWord()
        } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 20))
        .padding(.horizontal, 5)
        .opacity(wordIndex < totalWords - 1 && isTargetWordFound ? 1 : 0)
        .disabled(!(wordIndex < totalWords - 1 && isTargetWordFound))
        .animation(.spring(), value: isTargetWordFound)
    }

    private var keypadSection: some View {
        KeypadView(
            currentInput: currentInput,
            validationColor: validationColor,
            isValidating: validationState != .idle,
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
            pointsDisplay
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
                showCustomizationSheet = true
            } label: {
                Image(systemName: "paintbrush.fill")
            }
        }
        if debugMode {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showDebugSheet = true
                } label: {
                    Image(systemName: "ladybug")
                }
            }
        }
    }

    private func loadWord() async {
        let maxUnlocked = await WordListLoader.shared.findMaxUnlockedIndex(
            completedWords: completedTargetWords
        )
        if !debugMode && wordIndex > maxUnlocked {
            wordIndex = maxUnlocked
        }

        if let word = await WordListLoader.shared.getWord(at: wordIndex) {
            let freq = await WordListLoader.shared.getFrequency(for: word) ?? [:]
            let newSubWords = await WordListLoader.shared.findWords(from: freq)
            let newKeyItems = word.shuffled().map {
                KeyItem(id: UUID(), character: $0)
            }
            
            // Load saved progress
            let descriptor = FetchDescriptor<WordProgress>(
                predicate: #Predicate<WordProgress> { $0.mainWord == word }
            )
            let progress = (try? modelContext.fetch(descriptor))?.first
            let newFoundWords = Set(progress?.foundWords ?? [])
            
            // Now update everything in one go to minimize UI updates
            await MainActor.run {
                currentWord = word
                frequency = freq
                subWords = newSubWords
                keyItems = newKeyItems
                foundWords = newFoundWords
                disabledKeys = []
                currentInput = ""
                validationColor = .clear
                validationState = .idle
                tapCount = 0
                selectionStack = []
            }
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
                
                // Trigger floating point
                let pointId = UUID()
                let newPoint = BonusPoint(id: pointId, offset: CGSize(width: Double.random(in: -50...50), height: 100))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    bonusPoints.append(newPoint)
                }
                
                // Animate it up and remove
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        if let index = bonusPoints.firstIndex(where: { $0.id == pointId }) {
                            bonusPoints[index].offset = CGSize(width: bonusPoints[index].offset.width, height: -300)
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    bonusPoints.removeAll(where: { $0.id == pointId })
                }
            } else {
                let stats = UserStats(totalPoints: 1)
                modelContext.insert(stats)
            }
            try? modelContext.save()

            // Reset input display after feedbackDuration so user can start typing
            DispatchQueue.main.asyncAfter(deadline: .now() + feedbackDuration) {
                clearInput()
                withAnimation {
                    validationColor = .clear
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
                validationColor = .clear
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

    private func markTutorialAsFinished() {
        if let stats = userStats.first {
            stats.hasCompletedTutorial = true
        } else {
            let stats = UserStats(hasCompletedTutorial: true)
            modelContext.insert(stats)
        }
        try? modelContext.save()
    }
}

// MARK: - View Modifiers

private struct SheetModifier: ViewModifier {
    @Binding var showWordListSheet: Bool
    @Binding var showDebugSheet: Bool
    @Binding var showCustomizationSheet: Bool
    @Binding var showTutorialSheet: Bool
    @Binding var wordIndex: Int
    @Binding var totalWords: Int
    
    let currentWord: String?
    let frequency: [Character: Int]
    let subWords: [String]
    let loadWord: () async -> Void
    let resetGameState: () -> Void
    let markTutorialAsFinished: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showWordListSheet) {
                WordListView(onSelectWord: { index in
                    wordIndex = index
                    Task { await loadWord() }
                })
                #if os(iOS)
                .presentationDetents([.fraction(0.95)])
                .presentationDragIndicator(.hidden)
                #endif
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
                #if os(iOS)
                .presentationDetents([.fraction(0.95)])
                .presentationDragIndicator(.hidden)
                #endif
            }
            .sheet(isPresented: $showCustomizationSheet) {
                CustomizationView()
                #if os(iOS)
                .presentationDetents([.fraction(0.60)])
                .presentationDragIndicator(.hidden)
                #endif
            }
            .sheet(isPresented: $showTutorialSheet) {
                TutorialView {
                    markTutorialAsFinished()
                }
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                #endif
            }
    }
}

private struct FeedbackModifier: ViewModifier {
    let validationState: GameView.ValidationState
    let tapCount: Int
    let userStats: [UserStats]
    @Binding var showTutorialSheet: Bool
    let loadWord: () async -> Void
    @Binding var totalWords: Int

    func body(content: Content) -> some View {
        content
            .task {
                totalWords = await WordListLoader.shared.wordCount()
                await loadWord()
                
                // Show tutorial if not finished - wait a bit for user stats to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !(userStats.first?.hasCompletedTutorial ?? false) {
                        showTutorialSheet = true
                    }
                }
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

#Preview {
    GameView()
        .modelContainer(PreviewHelper.container)
}
