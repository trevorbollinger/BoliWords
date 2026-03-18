//
//  UserStats.swift
//  BoliWords
//
//  Created by Antigravity on 3/18/26.
//

import Foundation
import SwiftData

@Model
final class UserStats {
    var totalPoints: Int = 0
    
    init(totalPoints: Int = 0) {
        self.totalPoints = totalPoints
    }
}
