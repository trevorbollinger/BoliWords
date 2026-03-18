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
    let currentInput: String
    let validationColor: Color
    let keys: [KeyItem]
    let disabledKeys: Set<UUID>
    var isClearDisabled: Bool = true
    var isValidateDisabled: Bool = true
    var onKeyTap: ((KeyItem) -> Void)? = nil
    var onClearTap: (() -> Void)? = nil
    var onValidateTap: (() -> Void)? = nil
    var onShuffleTap: (() -> Void)? = nil
    var onBackspaceTap: (() -> Void)? = nil
    
    
    // Layout for the grid. 4 columns and 5-6 space between.
    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Input display
            Text(currentInput.isEmpty ? " " : currentInput)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .tracking(4)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(validationColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .glassModifier(in: RoundedRectangle(cornerRadius: 20))
                .padding(.bottom, 5)
                .animation(.default, value: validationColor)
            
            // Control Buttons (Shuffle & Backspace)
            HStack(spacing: 12) {
                Button {
                    onShuffleTap?()
                } label: {
                    HStack {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .glassModifier(in: Capsule())
                }
                
                Spacer()
                
                Button {
                    onBackspaceTap?()
                } label: {
                    Image(systemName: "delete.backward.fill")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .glassModifier(in: Capsule())
                }
                .disabled(currentInput.isEmpty)
                .opacity(currentInput.isEmpty ? 0.3 : 1.0)
            }
            .padding(.bottom, 4)
            
            // Letter keys
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(keys) { item in
                    KeyButton(text: String(item.character).uppercased(), isDisabled: disabledKeys.contains(item.id)) {
                        onKeyTap?(item)
                    }
                }
            }
            
            // Clear and Validate buttons
            HStack(spacing: 12) {
                Button {
                    onClearTap?()
                } label: {
                    Label("Clear", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glassModifier(in: RoundedRectangle(cornerRadius: 20))

                }
                .disabled(isClearDisabled)
                .opacity(isClearDisabled ? 0.3 : 1.0)
                
                Button {
                    onValidateTap?()
                } label: {
                    Label("Check", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isValidateDisabled ? Color.gray.opacity(0.2) : Color.green)
                        .foregroundColor(isValidateDisabled ? .gray : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glassModifier(in: RoundedRectangle(cornerRadius: 20))

                }
                .disabled(isValidateDisabled)
            }
            .padding(.top, 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isClearDisabled)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isValidateDisabled)
        }
        .padding(12)
        .glassModifier(in: RoundedRectangle(cornerRadius: 20))
 
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
                .glassModifier(in: RoundedRectangle(cornerRadius: 15))

        }
        .opacity(isDisabled ? 0.2 : 1.0)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

#Preview {
    let sampleKeys = Array("alphabe").map { KeyItem(id: UUID(), character: $0) }
    return KeypadView(
        currentInput: "ALPHA",
        validationColor: Color(UIColor.secondarySystemBackground),
        keys: sampleKeys,
        disabledKeys: Set([sampleKeys[0].id, sampleKeys[2].id])
    )
}
