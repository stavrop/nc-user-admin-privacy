//
//  ContentView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var apiService: NextcloudAPIService
    @StateObject private var viewModel: UserManagementViewModel
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var isUnlocked = false
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let service = NextcloudAPIService()
        _apiService = StateObject(wrappedValue: service)
        _viewModel = StateObject(wrappedValue: UserManagementViewModel(apiService: service))
        
        // Check if biometric is enabled
        _isUnlocked = State(initialValue: !AppConfiguration.isBiometricEnabled())
    }
    
    var body: some View {
        ZStack {
            // Main app content
            mainContent
            
            // Lock screen overlay
            if !isUnlocked && AppConfiguration.isBiometricEnabled() {
                LockScreenView(isUnlocked: $isUnlocked)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Lock when app goes to background
            if newPhase == .background && AppConfiguration.isBiometricEnabled() {
                isUnlocked = false
            }
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                UsersListView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                Task {
                                    await viewModel.loadData(forceRefresh: true)
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(viewModel.isLoading)
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Users", systemImage: "person.2")
            }
            .tag(0)
            
            NavigationStack {
                GroupsListView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                Task {
                                    await viewModel.loadData(forceRefresh: true)
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(viewModel.isLoading)
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Groups", systemImage: "person.3")
            }
            .tag(1)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(apiService: apiService)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            loadSavedSettings()
            if !apiService.serverURL.isEmpty {
                await viewModel.loadData()
            }
        }
    }
    
    private func loadSavedSettings() {
        if let serverURL = AppConfiguration.loadServerURL() {
            apiService.serverURL = serverURL
        }
        if let username = AppConfiguration.loadUsername() {
            apiService.username = username
        }
        if let password = AppConfiguration.loadPassword() {
            apiService.password = password
        }
    }
}

#Preview {
    ContentView()
}
