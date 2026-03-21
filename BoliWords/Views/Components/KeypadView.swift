//
//  KeypadView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/17/26.
//

import SwiftUI
import SwiftData

struct KeyItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let character: Character
}

struct KeypadView: View {
    let currentInput: String
    let validationColor: Color
    var isValidating: Bool = false
    let keys: [KeyItem]
    let disabledKeys: Set<UUID>
    var isClearDisabled: Bool = true
    var isValidateDisabled: Bool = true
    var onKeyTap: ((KeyItem) -> Void)? = nil
    var onClearTap: (() -> Void)? = nil
    var onValidateTap: (() -> Void)? = nil
    var onShuffleTap: (() -> Void)? = nil
    var onBackspaceTap: (() -> Void)? = nil
    
    
    // Dynamic layout for the grid. Adjusts based on number of keys.
    private var columns: [GridItem] {
        let count: Int
        if keys.count >= 9 || keys.count == 5 {
            count = 5
        } else if keys.count == 3 {
            count = 3
        } else {
            count = 4
        }
        return Array(repeating: GridItem(.flexible(), spacing: 6), count: count)
    }
    
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
                .background {
                    ZStack {
                        validationColor
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
//                        RoundedRectangle(cornerRadius: 20)
//                            .glassModifier(in: RoundedRectangle(cornerRadius: 20))
                    }
                    .opacity(isValidating ? 1 : 0)
                }
                .padding(.bottom, 5)
                .animation(.default, value: isValidating)
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
                .buttonStyle(PopButtonStyle())
                
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
                .buttonStyle(PopButtonStyle())
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
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .glassModifier(in: RoundedRectangle(cornerRadius: 20))

                }
                .buttonStyle(PopButtonStyle())
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
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .glassModifier(in: RoundedRectangle(cornerRadius: 20))

                }
                .buttonStyle(PopButtonStyle())
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

struct PopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.4, blendDuration: 0), value: configuration.isPressed)
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
                .glassModifier(in: RoundedRectangle(cornerRadius: 20))
                .contentShape(RoundedRectangle(cornerRadius: 20))
                .background(Color.white.opacity(0.001)) // Ensure it's hit-testable even if glass fails
        }
        .buttonStyle(PopButtonStyle())
        .opacity(isDisabled ? 0.2 : 1.0)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

#Preview("10 Keys Layout") {
    let sampleKeys = Array("abcdefghij").map { KeyItem(id: UUID(), character: $0) }
    return KeypadView(
        currentInput: "ABC",
        validationColor: Color(UIColor.secondarySystemBackground),
        keys: sampleKeys,
        disabledKeys: Set([])
    )
}
#Preview {
    GameView()
        .modelContainer(PreviewHelper.container)
}
