//
//  SettingsView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
import SwiftUI

struct SettingsView: View {
    @ObservedObject var apiService: NextcloudAPIService
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempServerURL: String = ""
    @State private var tempUsername: String = ""
    @State private var tempPassword: String = ""
    @State private var showingPassword = false
    @State private var showingSaveConfirmation = false
    @State private var biometricEnabled = AppConfiguration.isBiometricEnabled()
    @State private var showingAbout = false
    
    let biometricType = BiometricAuthHelper.biometricType()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Server URL", text: $tempServerURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    
                    Text("Example: https://cloud.example.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Nextcloud Server")
                }
                
                Section {
                    TextField("Username", text: $tempUsername)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                    
                    HStack {
                        if showingPassword {
                            TextField("Password", text: $tempPassword)
                                .textContentType(.password)
                                .autocapitalization(.none)
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Password", text: $tempPassword)
                                .textContentType(.password)
                        }
                        
                        Button {
                            showingPassword.toggle()
                        } label: {
                            Image(systemName: showingPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Credentials")
                } footer: {
                    Text("Use an app password for better security. Create one in your Nextcloud security settings.")
                }
                
                // Security Section
                Section {
                    if BiometricAuthHelper.isAvailable() {
                        Toggle(isOn: $biometricEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: biometricType.icon)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Require \(biometricType.displayName)")
                                    Text("Lock app when closed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onChange(of: biometricEnabled) { _, newValue in
                            AppConfiguration.setBiometricEnabled(newValue)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Biometric Auth Unavailable")
                                    .foregroundStyle(.secondary)
                                Text("Set up Face ID or Touch ID in Settings")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Security")
                } footer: {
                    if BiometricAuthHelper.isAvailable() {
                        Text("When enabled, you'll need to authenticate with \(biometricType.displayName) each time you open the app.")
                    }
                }
                
                // About Section
                Section {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Label("About", systemImage: "info.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                Section {
                    Button(role: .destructive) {
                        clearCredentials()
                    } label: {
                        Label("Clear All Credentials", systemImage: "trash")
                    }
                    
                    Button {
                        clearCache()
                    } label: {
                        Label("Clear Cache", systemImage: "arrow.clockwise.circle")
                    }
                } footer: {
                    Text("Clear Credentials removes all saved server and login information. Clear Cache removes cached users and groups data.")
                }
                
                #if DEBUG
                Section {
                    NavigationLink {
                        DebugSettingsView()
                    } label: {
                        Label("Debug: View Saved Settings", systemImage: "ladybug")
                    }
                } header: {
                    Text("Developer")
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                        showingSaveConfirmation = true
                        // Dismiss after a short delay to show confirmation
                        Task {
                            try? await Task.sleep(for: .milliseconds(500))
                            dismiss()
                        }
                    }
                    .disabled(tempServerURL.isEmpty || tempUsername.isEmpty || tempPassword.isEmpty)
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
        }
        .overlay {
            if showingSaveConfirmation {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        Text("Settings Saved")
                            .foregroundStyle(.white)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(.green, in: Capsule())
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showingSaveConfirmation)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func loadCurrentSettings() {
        tempServerURL = apiService.serverURL
        tempUsername = apiService.username
        tempPassword = apiService.password
    }
    
    private func saveSettings() {
        apiService.serverURL = tempServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        apiService.username = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        apiService.password = tempPassword
        
        // Save to secure storage
        AppConfiguration.saveServerURL(apiService.serverURL)
        AppConfiguration.saveUsername(apiService.username)
        AppConfiguration.savePassword(apiService.password)
        
        // Verify password was saved
        if let savedPassword = AppConfiguration.loadPassword() {
            print("✅ Settings saved successfully:")
            print("   Server: \(apiService.serverURL)")
            print("   Username: \(apiService.username)")
            print("   Password: \(String(repeating: "*", count: apiService.password.count))")
            print("   Password verified in Keychain: \(String(repeating: "*", count: savedPassword.count))")
        } else {
            print("⚠️ WARNING: Password may not have saved to Keychain!")
        }
    }
    
    private func clearCredentials() {
        AppConfiguration.clearAllCredentials()
        
        // Clear from API service
        apiService.serverURL = ""
        apiService.username = ""
        apiService.password = ""
        
        // Clear temp fields
        tempServerURL = ""
        tempUsername = ""
        tempPassword = ""
        
        print("🗑️ All credentials cleared")
    }
    
    private func clearCache() {
        Task {
            await DataCacheManager.shared.clearAllCache()
            print("🗑️ Cache cleared")
        }
    }
}

#Preview {
    SettingsView(apiService: NextcloudAPIService())
}
