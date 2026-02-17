//
//  KeychainHelper.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import Foundation
import Security

/// Secure storage helper using iOS Keychain
enum KeychainHelper {
    
    // MARK: - Error Types
    
    enum KeychainError: Error {
        case duplicateItem
        case unknown(OSStatus)
        case itemNotFound
    }
    
    // MARK: - Service Identifier
    
    private static let service = "com.nextcloud.usermanagement"
    
    // MARK: - Save
    
    /// Save a string value to the Keychain
    static func save(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Try to delete existing item first
        let deleteStatus = SecItemDelete(query as CFDictionary)
        #if DEBUG
        if deleteStatus == errSecSuccess {
            print("🔑 Keychain: Deleted existing item for key: \(key)")
        }
        #endif
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        print("🔑 Keychain: Attempting to save '\(key)'")
        print("   Status code: \(status)")
        if status == errSecSuccess {
            print("   ✅ Successfully saved to Keychain")
        } else {
            print("   ❌ Failed to save. OSStatus: \(status)")
        }
        #endif
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    // MARK: - Load
    
    /// Load a string value from the Keychain
    static func load(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unknown(status)
        }
        
        return value
    }
    
    // MARK: - Delete
    
    /// Delete a value from the Keychain
    static func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    // MARK: - Clear All
    
    /// Clear all items for this app from the Keychain
    static func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}
