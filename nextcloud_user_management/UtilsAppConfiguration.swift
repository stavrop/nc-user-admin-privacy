//
//  AppConfiguration.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
import Foundation

/// Manages app configuration and secure storage
struct AppConfiguration {
    
    // MARK: - UserDefaults Keys
    
    private enum UserDefaultsKey {
        static let serverURL = "nextcloud_server_url"
        static let username = "nextcloud_username"
        static let biometricEnabled = "biometric_auth_enabled"
    }
    
    // MARK: - Keychain Keys
    
    private enum KeychainKey {
        static let password = "nextcloud_password"
    }
    
    // MARK: - Server URL
    
    static func saveServerURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: UserDefaultsKey.serverURL)
    }
    
    static func loadServerURL() -> String? {
        UserDefaults.standard.string(forKey: UserDefaultsKey.serverURL)
    }
    
    // MARK: - Username
    
    static func saveUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: UserDefaultsKey.username)
    }
    
    static func loadUsername() -> String? {
        UserDefaults.standard.string(forKey: UserDefaultsKey.username)
    }
    
    // MARK: - Password (Secure)
    
    static func savePassword(_ password: String) {
        do {
            try KeychainHelper.save(password, forKey: KeychainKey.password)
        } catch {
            print("⚠️ Failed to save password to Keychain: \(error)")
            // Fallback to UserDefaults in development only
            #if DEBUG
            UserDefaults.standard.set(password, forKey: "nextcloud_password_fallback")
            #endif
        }
    }
    
    static func loadPassword() -> String? {
        do {
            return try KeychainHelper.load(forKey: KeychainKey.password)
        } catch {
            print("⚠️ Failed to load password from Keychain: \(error)")
            // Fallback to UserDefaults in development only
            #if DEBUG
            return UserDefaults.standard.string(forKey: "nextcloud_password_fallback")
            #else
            return nil
            #endif
        }
    }
    
    // MARK: - Biometric Authentication
    
    static func setBiometricEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKey.biometricEnabled)
    }
    
    static func isBiometricEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKey.biometricEnabled)
    }
    
    // MARK: - Clear All
    
    static func clearAllCredentials() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.serverURL)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.username)
        
        do {
            try KeychainHelper.delete(forKey: KeychainKey.password)
        } catch {
            print("⚠️ Failed to delete password from Keychain: \(error)")
        }
        
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: "nextcloud_password_fallback")
        #endif
        
        // Clear cached data as well
        Task {
            await DataCacheManager.shared.clearAllCache()
        }
    }
}
