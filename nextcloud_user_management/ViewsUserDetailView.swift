//
//  UserDetailView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import SwiftUI

struct UserDetailView: View {
    let userId: String
    @ObservedObject var viewModel: UserManagementViewModel
    @State private var showingAddGroupSheet = false
    
    // Compute the current user from the viewModel
    private var user: NextcloudUser? {
        viewModel.users.first(where: { $0.userid == userId })
    }
    
    var body: some View {
        Group {
            if let user = user {
                userDetailContent(for: user)
            } else {
                ContentUnavailableView(
                    "User Not Found",
                    systemImage: "person.slash",
                    description: Text("Could not find user '\(userId)'")
                )
            }
        }
        .navigationTitle(user?.displayname ?? userId)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddGroupSheet) {
            if let user = user {
                AddToGroupSheet(user: user, viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay(alignment: .bottom) {
            if let successMessage = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text(successMessage)
                        .foregroundStyle(.white)
                        .fontWeight(.medium)
                }
                .padding()
                .background(.green, in: Capsule())
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        viewModel.successMessage = nil
                    }
                }
            }
        }
        .animation(.spring(), value: viewModel.successMessage)
    }
    
    @ViewBuilder
    private func userDetailContent(for user: NextcloudUser) -> some View {
        List {
            Section("User Information") {
                LabeledContent("User ID", value: user.userid)
                
                if let displayName = user.displayname {
                    LabeledContent("Display Name", value: displayName)
                }
                
                if let email = user.email {
                    LabeledContent("Email", value: email)
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    HStack {
                        Image(systemName: user.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(user.enabled ? .green : .red)
                        Text(user.enabled ? "Enabled" : "Disabled")
                    }
                }
                
                if let lastLogin = user.lastLogin {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Last Login")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(lastLogin, style: .date)
                                    .font(.body)
                                Text(lastLogin, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text(lastLogin, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let creationDate = user.creationDate {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Account Created")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(creationDate, style: .date)
                                    .font(.body)
                                Text(creationDate, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text(creationDate, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let quota = user.quota {
                Section("Storage") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Used")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: quota.used, countStyle: .file))
                                .foregroundStyle(.secondary)
                        }
                        
                        ProgressView(value: quota.relative / 100.0)
                            .tint(quota.relative > 90 ? .red : quota.relative > 75 ? .orange : .blue)
                        
                        HStack {
                            Text("Available")
                            Spacer()
                            if quota.quota < 0 {
                                Text("Unlimited")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(ByteCountFormatter.string(fromByteCount: quota.quota, countStyle: .file))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            Section {
                Button {
                    Task {
                        await viewModel.toggleUserEnabled(user: user)
                    }
                } label: {
                    HStack {
                        Image(systemName: user.enabled ? "slash.circle" : "checkmark.circle")
                        Text(user.enabled ? "Disable User" : "Enable User")
                    }
                }
                .foregroundStyle(user.enabled ? .red : .green)
            }
            
            Section {
                ForEach(user.groups.sorted(), id: \.self) { group in
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundStyle(.blue)
                        Text(group)
                        Spacer()
                        
                        Button {
                            Task {
                                await viewModel.removeUserFromGroup(user: user, group: group)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button {
                    showingAddGroupSheet = true
                } label: {
                    Label("Add to Group", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Groups")
            } footer: {
                Text("\(user.groups.count) group(s)")
            }
        }
    }
}

struct AddToGroupSheet: View {
    let user: NextcloudUser
    @ObservedObject var viewModel: UserManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    var availableGroups: [NextcloudGroup] {
        viewModel.groups.filter { !user.groups.contains($0.name) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if availableGroups.isEmpty {
                    ContentUnavailableView(
                        "No Available Groups",
                        systemImage: "person.2.slash",
                        description: Text("This user is already in all groups")
                    )
                } else {
                    ForEach(availableGroups) { group in
                        Button {
                            Task {
                                await viewModel.addUserToGroup(user: user, group: group)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundStyle(.blue)
                                Text(group.name)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        let viewModel = UserManagementViewModel(apiService: NextcloudAPIService())
        let sampleUser = NextcloudUser(
            userid: "john.doe",
            displayname: "John Doe",
            email: "john@example.com",
            enabled: true,
            groups: ["admin", "users"],
            quota: NextcloudUser.UserQuota(
                quota: 10_000_000_000,
                used: 5_000_000_000,
                free: 5_000_000_000,
                relative: 50.0
            ),
            lastLogin: Date(),
            creationDate: Calendar.current.date(byAdding: .day, value: -90, to: Date())
        )
        
        // Add the sample user to the viewModel for preview
        viewModel.users = [sampleUser]
        
        return UserDetailView(
            userId: "john.doe",
            viewModel: viewModel
        )
    }
}
