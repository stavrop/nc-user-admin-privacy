//
//  BiometricAuthHelper.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import LocalAuthentication
import Foundation

/// Helper for Face ID / Touch ID authentication
enum BiometricAuthHelper {
    
    // MARK: - Biometric Type
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID // For Vision Pro
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "xmark.circle"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "opticid"
            }
        }
    }
    
    // MARK: - Error Types
    
    enum BiometricError: LocalizedError {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancel
        case systemCancel
        case passcodeNotSet
        case biometricLockout
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric authentication is enrolled. Please set up Face ID or Touch ID in Settings."
            case .authenticationFailed:
                return "Authentication failed. Please try again."
            case .userCancel:
                return "Authentication was cancelled"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Please set up a device passcode first"
            case .biometricLockout:
                return "Biometric authentication is locked. Please use your passcode."
            case .unknown(let error):
                return "Authentication error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Check Availability
    
    /// Check what biometric type is available
    static func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    /// Check if biometric authentication is available
    static func isAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Authenticate
    
    /// Authenticate using Face ID / Touch ID
    static func authenticate(reason: String = "Authenticate to access the app") async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                throw mapError(error)
            }
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if !success {
                throw BiometricError.authenticationFailed
            }
        } catch let laError as LAError {
            throw mapError(laError)
        } catch {
            throw BiometricError.unknown(error)
        }
    }
    
    /// Authenticate with fallback to passcode
    static func authenticateWithPasscodeFallback(reason: String = "Authenticate to access the app") async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error {
                throw mapError(error)
            }
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if !success {
                throw BiometricError.authenticationFailed
            }
        } catch let laError as LAError {
            throw mapError(laError)
        } catch {
            throw BiometricError.unknown(error)
        }
    }
    
    // MARK: - Error Mapping
    
    private static func mapError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return .unknown(error)
        }
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .biometricLockout
        default:
            return .unknown(error)
        }
    }
}
