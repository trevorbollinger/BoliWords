//
//  UserStats.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/18/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class UserStats {
    var totalPoints: Int = 0
    var themeColor: String = ThemeColor.none.rawValue
    var unlockedThemeColors: [String] = [ThemeColor.none.rawValue]
    var hasCompletedTutorial: Bool = false
    
    init(totalPoints: Int = 0, themeColor: String = ThemeColor.none.rawValue, unlockedThemeColors: [String] = [ThemeColor.none.rawValue], hasCompletedTutorial: Bool = false) {
        self.totalPoints = totalPoints
        self.themeColor = themeColor
        self.unlockedThemeColors = unlockedThemeColors
        self.hasCompletedTutorial = hasCompletedTutorial
    }
}

enum ThemeColor: String, CaseIterable, Codable {
    case none, red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray, black
    
    var color: SwiftUI.Color? {
        if self == .none { return nil }
        return SwiftUI.Color("ThemeColor\(rawValue.capitalized)")
    }
}
