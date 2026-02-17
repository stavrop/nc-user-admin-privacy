//
//  DebugSettingsView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
import SwiftUI

/// A debug view to verify settings persistence - remove in production
struct DebugSettingsView: View {
    @State private var savedServerURL: String = "Not set"
    @State private var savedUsername: String = "Not set"
    @State private var savedPassword: String = "Not set"
    
    var body: some View {
        List {
            Section("Saved in UserDefaults") {
                LabeledContent("Server URL", value: savedServerURL)
                LabeledContent("Username", value: savedUsername)
                LabeledContent("Password", value: savedPassword)
            }
            
            Section {
                Button("Refresh") {
                    loadSettings()
                }
                
                Button("Clear All", role: .destructive) {
                    clearSettings()
                }
            }
        }
        .navigationTitle("Debug Settings")
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        savedServerURL = UserDefaults.standard.string(forKey: "nextcloud_server_url") ?? "Not set"
        savedUsername = UserDefaults.standard.string(forKey: "nextcloud_username") ?? "Not set"
        
        if let password = UserDefaults.standard.string(forKey: "nextcloud_password") {
            savedPassword = String(repeating: "*", count: password.count) + " (\(password.count) chars)"
        } else {
            savedPassword = "Not set"
        }
    }
    
    private func clearSettings() {
        UserDefaults.standard.removeObject(forKey: "nextcloud_server_url")
        UserDefaults.standard.removeObject(forKey: "nextcloud_username")
        UserDefaults.standard.removeObject(forKey: "nextcloud_password")
        loadSettings()
    }
}

#Preview {
    NavigationStack {
        DebugSettingsView()
    }
}
