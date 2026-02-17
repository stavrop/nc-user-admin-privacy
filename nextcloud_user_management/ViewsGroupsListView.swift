//
//  GroupsListView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
import SwiftUI

struct GroupsListView: View {
    @ObservedObject var viewModel: UserManagementViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.groups.isEmpty {
                ProgressView("Loading groups...")
            } else if viewModel.groups.isEmpty {
                ContentUnavailableView(
                    "No Groups Found",
                    systemImage: "person.2.slash",
                    description: Text("Connect to your Nextcloud server to view groups")
                )
            } else {
                List {
                    ForEach(viewModel.filteredGroups) { group in
                        NavigationLink {
                            GroupDetailView(group: group, viewModel: viewModel)
                        } label: {
                            GroupRowView(group: group, viewModel: viewModel)
                        }
                    }
                }
                .searchable(text: $viewModel.searchText, prompt: "Search groups")
            }
        }
        .navigationTitle("Groups")
    }
}

struct GroupRowView: View {
    let group: NextcloudGroup
    @ObservedObject var viewModel: UserManagementViewModel
    
    var memberCount: Int {
        viewModel.users.filter { $0.groups.contains(group.name) }.count
    }
    
    var body: some View {
        HStack {
            Image(systemName: "person.2.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                Text("\(memberCount) member(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct GroupDetailView: View {
    let group: NextcloudGroup
    @ObservedObject var viewModel: UserManagementViewModel
    
    var members: [NextcloudUser] {
        viewModel.users.filter { $0.groups.contains(group.name) }
    }
    
    var body: some View {
        List {
            Section {
                if members.isEmpty {
                    ContentUnavailableView(
                        "No Members",
                        systemImage: "person.slash",
                        description: Text("This group has no members")
                    )
                } else {
                    ForEach(members) { user in
                        NavigationLink {
                            UserDetailView(userId: user.userid, viewModel: viewModel)
                        } label: {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(user.enabled ? .blue : .gray)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayname ?? user.userid)
                                        .font(.body)
                                    
                                    if user.displayname != nil {
                                        Text(user.userid)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: user.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(user.enabled ? .green : .red)
                                    .font(.caption)
                            }
                        }
                    }
                }
            } header: {
                Text("Members")
            } footer: {
                Text("\(members.count) member(s) in this group")
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GroupsListView(viewModel: UserManagementViewModel(apiService: NextcloudAPIService()))
    }
}
