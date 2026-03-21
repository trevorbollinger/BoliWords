//
//  TutorialView.swift
//  BoliWords
//
//  Created by Trevor Bollinger on 3/20/26.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    var onFinish: () -> Void
    
    @State private var currentPage = 0
    private let totalPages = 3
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onFinish()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    TutorialPage(
                        title: "BoliWords",
                        subtitle: "Find the Target",
                        description: "Form words with the letters you have available. Find the target word to move on to the next level.",
                        systemImage: "keyboard.fill",
                        color: .blue
                    )
                    .tag(0)
              
                    
                    // Page 2: Strategy
                    TutorialPage(
                        title: "Your Strategy",
                        subtitle: "Points or Progression",
                        description: "Clear as many levels as you can, or find as many words as possible to earn points.",
                        systemImage: "star.fill",
                        color: .red
                    )
                    .tag(1)
                    
                    // Page 3: Customization
                    TutorialPage(
                        title: "Your Style",
                        subtitle: "Unlock Themes",
                        description: "Use your points to unlock new themes and customization options.",
                        systemImage: "paintbrush.fill",
                        color: .purple
                    )
                    .tag(2)
                }
                .tabViewStyle(.page)
                #if os(iOS)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                #endif
                
                Spacer()
                
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        onFinish()
                        dismiss()
                    }
                } label: {
                    Text(currentPage == totalPages - 1 ? "Start Playing" : "Next")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(20)
                        .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
}

struct TutorialPage: View {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 220, height: 220)
                
//                Circle()
//                    .stroke(color.opacity(0.2), lineWidth: 2)
//                    .frame(width: 250, height: 250)
                
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, options: .repeat(2), value: title)
            }
//            .padding(.top, 40)
            
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    
                    Text(subtitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                        .textCase(.uppercase)
                        .kerning(1.5)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                    .lineSpacing(4)
            }
        }
        .padding(.bottom, 65)
    }
}

#Preview {
    TutorialView(onFinish: {})
}
