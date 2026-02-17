//
//  UsersListView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
import SwiftUI

struct UsersListView: View {
    @ObservedObject var viewModel: UserManagementViewModel
    @State private var showingFilterOptions = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.users.isEmpty {
                ProgressView("Loading users...")
            } else if viewModel.users.isEmpty {
                ContentUnavailableView(
                    "No Users Found",
                    systemImage: "person.slash",
                    description: Text("Connect to your Nextcloud server to view users")
                )
            } else if viewModel.filteredUsers.isEmpty {
                ContentUnavailableView(
                    "No Matching Users",
                    systemImage: "magnifyingglass",
                    description: Text("Try adjusting your filters or search criteria")
                )
            } else {
                List {
                    ForEach(viewModel.filteredUsers) { user in
                        NavigationLink {
                            UserDetailView(userId: user.userid, viewModel: viewModel)
                        } label: {
                            CompactUserRowView(user: user)
                        }
                    }
                }
                .searchable(text: $viewModel.searchText, prompt: "Search users")
            }
        }
        .navigationTitle("Users (\(viewModel.filteredUsers.count))")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Filter by Status") {
                        Picker("Status", selection: $viewModel.userFilter) {
                            ForEach([UserManagementViewModel.UserFilter.all,
                                     .enabledOnly,
                                     .disabledOnly], id: \.self) { filter in
                                Label(filter.displayName, systemImage: iconForFilter(filter))
                                    .tag(filter)
                            }
                        }
                    }
                    
                    Section("Sort by") {
                        Picker("Sort Order", selection: $viewModel.userSortOrder) {
                            ForEach([UserManagementViewModel.UserSortOrder.alphabetical,
                                     .lastLogin], id: \.self) { order in
                                Label(order.displayName, systemImage: order.icon)
                                    .tag(order)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
    
    private func iconForFilter(_ filter: UserManagementViewModel.UserFilter) -> String {
        switch filter {
        case .all: return "person.2"
        case .enabledOnly: return "checkmark.circle"
        case .disabledOnly: return "xmark.circle"
        }
    }
}

// Compact user row - shows only name and status
struct CompactUserRowView: View {
    let user: NextcloudUser
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(user.enabled ? .blue : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayname ?? user.userid)
                    .font(.body)
                    .fontWeight(.medium)
                
                if user.displayname != nil && user.displayname != user.userid {
                    Text(user.userid)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Status badge
            HStack(spacing: 4) {
                Image(systemName: user.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                Text(user.enabled ? "Enabled" : "Disabled")
                    .font(.caption)
            }
            .foregroundStyle(user.enabled ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(user.enabled ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// Original detailed user row (kept for reference)
struct UserRowView: View {
    let user: NextcloudUser
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(user.enabled ? .blue : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayname ?? user.userid)
                    .font(.headline)
                
                if user.displayname != nil {
                    Text(user.userid)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let email = user.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: user.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(user.enabled ? .green : .red)
                    
                    Text(user.enabled ? "Enabled" : "Disabled")
                        .font(.caption2)
                        .foregroundStyle(user.enabled ? .green : .red)
                    
                    if !user.groups.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("\(user.groups.count) group(s)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let quota = user.quota, quota.quota > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(quota.relative))%")
                        .font(.caption)
                        .foregroundStyle(quota.relative > 90 ? .red : quota.relative > 75 ? .orange : .secondary)
                    
                    ProgressView(value: quota.relative / 100.0)
                        .frame(width: 50)
                        .tint(quota.relative > 90 ? .red : quota.relative > 75 ? .orange : .blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        UsersListView(viewModel: UserManagementViewModel(apiService: NextcloudAPIService()))
    }
}
