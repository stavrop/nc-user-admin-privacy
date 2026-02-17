//
//  DataCacheManager.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 26/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import Foundation

/// Manages caching of users and groups data to disk
actor DataCacheManager {
    
    // MARK: - Cache Configuration
    
    /// How long cached data is considered valid (in seconds)
    static let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    // MARK: - Cache Keys
    
    private enum CacheKey {
        static let users = "cached_users"
        static let groups = "cached_groups"
        static let usersTimestamp = "cached_users_timestamp"
        static let groupsTimestamp = "cached_groups_timestamp"
    }
    
    // MARK: - Singleton
    
    static let shared = DataCacheManager()
    
    private init() {}
    
    // MARK: - Cache Directory
    
    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    private func cacheFileURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent("\(key).json")
    }
    
    // MARK: - Users Cache
    
    /// Save users to cache
    func cacheUsers(_ users: [NextcloudUser]) {
        do {
            let data = try JSONEncoder().encode(users)
            let fileURL = cacheFileURL(for: CacheKey.users)
            try data.write(to: fileURL, options: .atomic)
            
            // Save timestamp
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: CacheKey.usersTimestamp)
            
            #if DEBUG
            print("💾 Cached \(users.count) users")
            #endif
        } catch {
            print("⚠️ Failed to cache users: \(error)")
        }
    }
    
    /// Load users from cache
    func loadCachedUsers() -> [NextcloudUser]? {
        guard isCacheValid(for: CacheKey.usersTimestamp) else {
            #if DEBUG
            print("⏰ Users cache expired")
            #endif
            return nil
        }
        
        do {
            let fileURL = cacheFileURL(for: CacheKey.users)
            let data = try Data(contentsOf: fileURL)
            let users = try JSONDecoder().decode([NextcloudUser].self, from: data)
            
            #if DEBUG
            print("📂 Loaded \(users.count) users from cache")
            #endif
            
            return users
        } catch {
            #if DEBUG
            print("⚠️ Failed to load cached users: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Groups Cache
    
    /// Save groups to cache
    func cacheGroups(_ groups: [NextcloudGroup]) {
        do {
            let data = try JSONEncoder().encode(groups)
            let fileURL = cacheFileURL(for: CacheKey.groups)
            try data.write(to: fileURL, options: .atomic)
            
            // Save timestamp
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: CacheKey.groupsTimestamp)
            
            #if DEBUG
            print("💾 Cached \(groups.count) groups")
            #endif
        } catch {
            print("⚠️ Failed to cache groups: \(error)")
        }
    }
    
    /// Load groups from cache
    func loadCachedGroups() -> [NextcloudGroup]? {
        guard isCacheValid(for: CacheKey.groupsTimestamp) else {
            #if DEBUG
            print("⏰ Groups cache expired")
            #endif
            return nil
        }
        
        do {
            let fileURL = cacheFileURL(for: CacheKey.groups)
            let data = try Data(contentsOf: fileURL)
            let groups = try JSONDecoder().decode([NextcloudGroup].self, from: data)
            
            #if DEBUG
            print("📂 Loaded \(groups.count) groups from cache")
            #endif
            
            return groups
        } catch {
            #if DEBUG
            print("⚠️ Failed to load cached groups: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Cache Validity
    
    /// Check if cache is still valid based on timestamp
    private func isCacheValid(for timestampKey: String) -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? TimeInterval else {
            return false
        }
        
        let cacheAge = Date().timeIntervalSince1970 - timestamp
        return cacheAge < Self.cacheValidityDuration
    }
    
    /// Get the age of the cache in seconds
    func getCacheAge(for type: CacheType) -> TimeInterval? {
        let key = type == .users ? CacheKey.usersTimestamp : CacheKey.groupsTimestamp
        guard let timestamp = UserDefaults.standard.object(forKey: key) as? TimeInterval else {
            return nil
        }
        return Date().timeIntervalSince1970 - timestamp
    }
    
    enum CacheType {
        case users
        case groups
    }
    
    // MARK: - Clear Cache
    
    /// Clear all cached data
    func clearAllCache() {
        let fileManager = FileManager.default
        
        // Remove files
        try? fileManager.removeItem(at: cacheFileURL(for: CacheKey.users))
        try? fileManager.removeItem(at: cacheFileURL(for: CacheKey.groups))
        
        // Remove timestamps
        UserDefaults.standard.removeObject(forKey: CacheKey.usersTimestamp)
        UserDefaults.standard.removeObject(forKey: CacheKey.groupsTimestamp)
        
        #if DEBUG
        print("🗑️ All cache cleared")
        #endif
    }
    
    /// Clear only users cache
    func clearUsersCache() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: cacheFileURL(for: CacheKey.users))
        UserDefaults.standard.removeObject(forKey: CacheKey.usersTimestamp)
        
        #if DEBUG
        print("🗑️ Users cache cleared")
        #endif
    }
    
    /// Clear only groups cache
    func clearGroupsCache() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: cacheFileURL(for: CacheKey.groups))
        UserDefaults.standard.removeObject(forKey: CacheKey.groupsTimestamp)
        
        #if DEBUG
        print("🗑️ Groups cache cleared")
        #endif
    }
}
