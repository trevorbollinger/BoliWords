//
//  CustomizationView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/20/26.
//

import SwiftData
import SwiftUI

struct CustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userStats: [UserStats]

    private var totalPoints: Int {
        userStats.first?.totalPoints ?? 0
    }

    @State private var unlockSuccessTrigger = false
    @State private var selectionTapCount = 0

    //Theme Colors
    private let themeColorUnlockCost = 10

    private var currentThemeColor: String {
        userStats.first?.themeColor ?? ThemeColor.none.rawValue
    }

    private var selectedThemeColor: ThemeColor? {
        ThemeColor(rawValue: currentThemeColor)
    }

    private var unlockedThemeColors: [String] {
        userStats.first?.unlockedThemeColors ?? [ThemeColor.none.rawValue]
    }

    @State private var showingUnlockAlert = false
    @State private var themeColorToUnlock: ThemeColor?

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .lastTextBaseline) {
                                Text("Theme Color")
                                    .font(.title3.bold())
                                Text("(\(themeColorUnlockCost) points each)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)

                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(
                                        .flexible(),
                                        spacing: 12
                                    ),
                                    count: 5
                                ),
                                spacing: 12
                            ) {
                                ForEach(ThemeColor.allCases, id: \.self) {
                                    themeColor in
                                    let isSelected =
                                        currentThemeColor == themeColor.rawValue
                                    let isUnlocked =
                                        unlockedThemeColors.contains(
                                            themeColor.rawValue
                                        )

                                    Button {
                                        if isUnlocked {
                                            selectionTapCount += 1
                                            withAnimation(
                                                .spring(duration: 0.3)
                                            ) {
                                                if let stats = userStats.first {
                                                    stats.themeColor =
                                                        themeColor.rawValue
                                                } else {
                                                    let newStats = UserStats(
                                                        themeColor: themeColor
                                                            .rawValue
                                                    )
                                                    modelContext.insert(
                                                        newStats
                                                    )
                                                }
                                            }
                                        } else {
                                            themeColorToUnlock = themeColor
                                            showingUnlockAlert = true
                                        }
                                    } label: {
                                        ZStack {
                                            if let color = themeColor.color {
                                                Circle()
                                                    .fill(color.gradient)
                                                    .frame(height: 60)
                                                    .shadow(
                                                        color: color.opacity(
                                                            0.3
                                                        ),
                                                        radius: isSelected
                                                            ? 8 : 4,
                                                        x: 0,
                                                        y: isSelected ? 4 : 2
                                                    )
                                            } else {
                                                Circle()
                                                    .fill(
                                                        .secondary.opacity(0.2)
                                                    )
                                                    .frame(height: 60)
                                                    .overlay {
                                                        Image(
                                                            systemName: "nosign"
                                                        )
                                                        .font(.caption)
                                                        .foregroundStyle(
                                                            .secondary
                                                        )
                                                    }
                                                    .shadow(
                                                        color: .black.opacity(
                                                            0.1
                                                        ),
                                                        radius: isSelected
                                                            ? 8 : 4,
                                                        x: 0,
                                                        y: isSelected ? 4 : 2
                                                    )
                                            }

                                            if !isUnlocked {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.white)
                                                    .shadow(radius: 2)
                                            }

                                            if isSelected {
                                                Circle()
                                                    .stroke(
                                                        .primary,
                                                        lineWidth: 3
                                                    )
                                                    .frame(
                                                        width: 72,
                                                        height: 72
                                                    )
                                                    .transition(
                                                        .scale.combined(
                                                            with: .opacity
                                                        )
                                                    )
                                            }
                                        }
                                        .frame(width: 72, height: 72)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 60)
                    }
                }

                VStack {
                    HStack {
                        HStack {
                            Text("Points:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(totalPoints)")
                                .font(.headline)
                                .foregroundStyle(
                                    selectedThemeColor?.color ?? .primary
                                )
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .glassModifier(in: RoundedRectangle(cornerRadius: 20))


                      

                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }

            }
            .navigationTitle("Customization")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                "Unlock Color",
                isPresented: $showingUnlockAlert,
                presenting: themeColorToUnlock
            ) { themeColor in
                Button("Cancel", role: .cancel) {}
                Button("Unlock for \(themeColorUnlockCost) pts") {
                    unlockColor(themeColor)
                }
                .disabled(totalPoints < themeColorUnlockCost)
            } message: { themeColor in
                if totalPoints >= themeColorUnlockCost {
                    Text(
                        "Would you like to unlock the \(themeColor.rawValue) theme for \(themeColorUnlockCost) points?"
                    )
                } else {
                    Text(
                        "You need \(themeColorUnlockCost) points to unlock this theme. You currently have \(totalPoints) points."
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sensoryFeedback(.success, trigger: unlockSuccessTrigger)
            .sensoryFeedback(.selection, trigger: selectionTapCount)
            .tint(selectedThemeColor?.color)
        }
    }

    private func unlockColor(_ themeColor: ThemeColor) {
        if let stats = userStats.first {
            guard stats.totalPoints >= themeColorUnlockCost else { return }

            withAnimation(.spring(duration: 0.3)) {
                stats.totalPoints -= themeColorUnlockCost
                stats.unlockedThemeColors.append(themeColor.rawValue)
                stats.themeColor = themeColor.rawValue
                unlockSuccessTrigger.toggle()
            }
            try? modelContext.save()
        } else {
            // This should ideally not happen if points are > 10, but just in case
            guard 0 >= themeColorUnlockCost else { return }  // points are 0 if userStats.first is nil
        }
    }
}

#Preview {
    CustomizationView()
        .modelContainer(PreviewHelper.container)
}
