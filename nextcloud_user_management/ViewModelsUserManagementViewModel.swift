//
//  UserManagementViewModel.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
import Foundation
import SwiftUI
internal import Combine

@MainActor
class UserManagementViewModel: ObservableObject {
    @Published var users: [NextcloudUser] = []
    @Published var groups: [NextcloudGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText = ""
    @Published var userFilter: UserFilter = .all
    @Published var userSortOrder: UserSortOrder = .alphabetical
    
    enum UserFilter {
        case all
        case enabledOnly
        case disabledOnly
        
        var displayName: String {
            switch self {
            case .all: return "All Users"
            case .enabledOnly: return "Enabled Only"
            case .disabledOnly: return "Disabled Only"
            }
        }
    }
    
    enum UserSortOrder {
        case alphabetical
        case lastLogin
        //case creationDate
        
        var displayName: String {
            switch self {
            case .alphabetical: return "Alphabetically"
            case .lastLogin: return "Last Login"
            //case .creationDate: return "Creation Date"
            }
        }
        
        var icon: String {
            switch self {
            case .alphabetical: return "textformat.abc"
            case .lastLogin: return "clock"
            //case .creationDate: return "calendar"
            }
        }
    }
    
    let apiService: NextcloudAPIService
    
    init(apiService: NextcloudAPIService) {
        self.apiService = apiService
    }
    
    var filteredUsers: [NextcloudUser] {
        var result = users
        
        // Apply status filter
        switch userFilter {
        case .all:
            break
        case .enabledOnly:
            result = result.filter { $0.enabled }
        case .disabledOnly:
            result = result.filter { !$0.enabled }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { user in
                user.userid.localizedCaseInsensitiveContains(searchText) ||
                user.displayname?.localizedCaseInsensitiveContains(searchText) == true ||
                user.email?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply sorting
        switch userSortOrder {
        case .alphabetical:
            result = result.sorted { ($0.displayname ?? $0.userid).localizedCaseInsensitiveCompare($1.displayname ?? $1.userid) == .orderedAscending }
        case .lastLogin:
            result = result.sorted { user1, user2 in
                guard let date1 = user1.lastLogin, let date2 = user2.lastLogin else {
                    // Users without last login go to the end
                    if user1.lastLogin == nil && user2.lastLogin == nil {
                        return user1.userid < user2.userid
                    }
                    return user1.lastLogin != nil
                }
                return date1 > date2 // Most recent first
            }
//        case .creationDate:
//            result = result.sorted { user1, user2 in
//                guard let date1 = user1.creationDate, let date2 = user2.creationDate else {
//                    // Users without creation date go to the end
//                    if user1.creationDate == nil && user2.creationDate == nil {
//                        return user1.userid < user2.userid
//                    }
//                    return user1.creationDate != nil
//                }
//                return date1 > date2 // Newest first
//            }
        }
        
        return result
    }
    
    var filteredGroups: [NextcloudGroup] {
        if searchText.isEmpty {
            return groups
        }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func loadData(forceRefresh: Bool = false) async {
        // Load from cache first if available (unless force refresh)
        if !forceRefresh {
            await loadFromCache()
        }
        
        isLoading = true
        errorMessage = nil
        
        async let usersResult: () = loadUsers()
        async let groupsResult: () = loadGroups()
        
        await usersResult
        await groupsResult
        
        isLoading = false
    }
    
    /// Load data from cache immediately
    func loadFromCache() async {
        let cacheManager = DataCacheManager.shared
        
        if let cachedUsers = await cacheManager.loadCachedUsers() {
            users = cachedUsers
        }
        
        if let cachedGroups = await cacheManager.loadCachedGroups() {
            groups = cachedGroups
        }
    }
    
    func loadUsers() async {
        do {
            let userIds = try await apiService.fetchUsers()
            
            // Fetch details for each user
            var loadedUsers: [NextcloudUser] = []
            for userId in userIds {
                do {
                    let user = try await apiService.fetchUserDetails(userId: userId)
                    loadedUsers.append(user)
                } catch {
                    print("Failed to load details for user \(userId): \(error)")
                }
            }
            
            users = loadedUsers.sorted { $0.userid < $1.userid }
            
            // Cache the loaded users
            await DataCacheManager.shared.cacheUsers(users)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadGroups() async {
        do {
            let groupNames = try await apiService.fetchGroups()
            groups = groupNames.map { NextcloudGroup(name: $0) }.sorted { $0.name < $1.name }
            
            // Cache the loaded groups
            await DataCacheManager.shared.cacheGroups(groups)
        } catch {
            if errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleUserEnabled(user: NextcloudUser) async {
        errorMessage = nil
        successMessage = nil
        
        do {
            if user.enabled {
                try await apiService.disableUser(userId: user.userid)
                successMessage = "User '\(user.displayname ?? user.userid)' disabled successfully"
            } else {
                try await apiService.enableUser(userId: user.userid)
                successMessage = "User '\(user.displayname ?? user.userid)' enabled successfully"
            }
            
            // Reload user details to get updated status
            if let index = users.firstIndex(where: { $0.userid == user.userid }) {
                let updatedUser = try await apiService.fetchUserDetails(userId: user.userid)
                users[index] = updatedUser
                
                #if DEBUG
                print("🔄 User details refreshed - Enabled: \(updatedUser.enabled)")
                #endif
            }
        } catch {
            errorMessage = error.localizedDescription
            successMessage = nil
        }
    }
    
    func addUserToGroup(user: NextcloudUser, group: NextcloudGroup) async {
        errorMessage = nil
        successMessage = nil
        
        do {
            try await apiService.addUserToGroup(userId: user.userid, groupId: group.name)
            successMessage = "User '\(user.displayname ?? user.userid)' added to '\(group.name)'"
            
            // Reload user details
            if let index = users.firstIndex(where: { $0.userid == user.userid }) {
                let updatedUser = try await apiService.fetchUserDetails(userId: user.userid)
                users[index] = updatedUser
            }
        } catch {
            errorMessage = error.localizedDescription
            successMessage = nil
        }
    }
    
    func removeUserFromGroup(user: NextcloudUser, group: String) async {
        errorMessage = nil
        successMessage = nil
        
        do {
            try await apiService.removeUserFromGroup(userId: user.userid, groupId: group)
            successMessage = "User '\(user.displayname ?? user.userid)' removed from '\(group)'"
            
            // Reload user details
            if let index = users.firstIndex(where: { $0.userid == user.userid }) {
                let updatedUser = try await apiService.fetchUserDetails(userId: user.userid)
                users[index] = updatedUser
            }
        } catch {
            errorMessage = error.localizedDescription
            successMessage = nil
        }
    }
}
