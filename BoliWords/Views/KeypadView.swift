//
//  KeypadView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftUI

struct KeyItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let character: Character
}

struct KeypadView: View {
    let keys: [KeyItem]
    let disabledKeys: Set<UUID>
    var onKeyTap: ((KeyItem) -> Void)? = nil
    
    // Sort letters alphabetically as requested
    private var sortedKeys: [KeyItem] {
        keys.sorted { String($0.character).uppercased() < String($1.character).uppercased() }
    }
    
    // Layout helper to split letters into rows (aiming for roughly 3 rows if enough letters)
    private var rows: [[KeyItem]] {
        let items = sortedKeys
        guard !items.isEmpty else { return [] }
        
        let rowCount = 3
        let perRow = Int(ceil(Double(items.count) / Double(rowCount)))
        
        var result: [[KeyItem]] = []
        for i in 0..<rowCount {
            let start = i * perRow
            let end = min(start + perRow, items.count)
            if start < end {
                result.append(Array(items[start..<end]))
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex]) { item in
                        KeyButton(text: String(item.character).uppercased(), isDisabled: disabledKeys.contains(item.id)) {
                            onKeyTap?(item)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color(UIColor.systemGray4).opacity(0.5))
    }
}

struct KeyButton: View {
    let text: String
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.title3.weight(.medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 0, x: 0, y: 1)
                )
        }
        .opacity(isDisabled ? 0.2 : 1.0)
        .disabled(isDisabled)
    }
}

#Preview {
    let sampleKeys = Array("alphabetical").map { KeyItem(id: UUID(), character: $0) }
    return KeypadView(keys: sampleKeys, disabledKeys: Set([sampleKeys[0].id, sampleKeys[2].id]))
        .frame(height: 200)
}
