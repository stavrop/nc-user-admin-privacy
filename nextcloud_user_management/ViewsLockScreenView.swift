//
//  LockScreenView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import SwiftUI

struct LockScreenView: View {
    @Binding var isUnlocked: Bool
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    let biometricType = BiometricAuthHelper.biometricType()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon/Logo Area
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    
                    Text("NC User Admin")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Auth Button
                VStack(spacing: 20) {
                    if isAuthenticating {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    } else {
                        Button {
                            authenticate()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: biometricType.icon)
                                    .font(.title2)
                                Text("Unlock with \(biometricType.displayName)")
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.5), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(isAuthenticating)
                        
                        if showError, let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.9))
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Auto-trigger authentication when view appears
            authenticate()
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        showError = false
        errorMessage = nil
        
        Task {
            do {
                try await BiometricAuthHelper.authenticateWithPasscodeFallback(
                    reason: "Unlock NC User Admin"
                )
                
                // Success
                await MainActor.run {
                    withAnimation(.spring()) {
                        isUnlocked = true
                    }
                }
            } catch {
                // Failed
                await MainActor.run {
                    isAuthenticating = false
                    
                    // Don't show error for user cancel
                    if let biometricError = error as? BiometricAuthHelper.BiometricError,
                       case .userCancel = biometricError {
                        return
                    }
                    
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    LockScreenView(isUnlocked: .constant(false))
}
