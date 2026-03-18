//
//  SplashScreenView.swift
//  BoliWords
//
//  Created by Antigravity on 3/17/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale = 0.8
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Logo / Symbol
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .opacity(0.3)
                    
                    Image(systemName: "textformat.characters.dottedline")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                Text("BoliWords")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                
                ProgressView()
                    .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                self.opacity = 1.0
                self.scale = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
