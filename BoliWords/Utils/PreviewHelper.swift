//
//  PreviewHelper.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/20/26.
//

import SwiftData
import SwiftUI

@MainActor
struct PreviewHelper {
    static let container: ModelContainer = {
        let schema = Schema([WordProgress.self, UserStats.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        let stats = UserStats(
            totalPoints: 10000,
            themeColor: ThemeColor.purple.rawValue,
            unlockedThemeColors: [ThemeColor.none.rawValue, ThemeColor.purple.rawValue]
        )
        container.mainContext.insert(stats)
        
        return container
    }()
}
