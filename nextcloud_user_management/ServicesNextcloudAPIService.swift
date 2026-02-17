//
//  NextcloudAPIService.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.

import Foundation
internal import Combine

enum NextcloudAPIError: LocalizedError {
    case invalidURL
    case invalidCredentials
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case tlsError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidCredentials:
            return "Invalid credentials"
        case .networkError(let error):
            // Check for TLS-specific errors
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorSecureConnectionFailed:
                    return "TLS/SSL connection failed. The server's certificate may be invalid or self-signed. Enable 'Allow Self-Signed Certificates' in settings."
                case NSURLErrorServerCertificateUntrusted:
                    return "Server certificate is not trusted. Enable 'Allow Self-Signed Certificates' or install the certificate in your keychain."
                case NSURLErrorClientCertificateRequired:
                    return "Server requires a client certificate"
                case NSURLErrorClientCertificateRejected:
                    return "Client certificate was rejected"
                default:
                    break
                }
            }
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Unauthorized. Please check your credentials."
        case .tlsError(let message):
            return "TLS/SSL Error: \(message)"
        }
    }
}

@MainActor
class NextcloudAPIService: ObservableObject {
    @Published var serverURL: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var allowSelfSignedCertificates: Bool = false
    
    // Custom URLSession configuration with delegate support
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        config.httpAdditionalHeaders = [
            "User-Agent": "NCUserAdmin/1.0"
        ]
        
        // Create session with delegate for custom certificate handling
        let session = URLSession(
            configuration: config,
            delegate: CertificateDelegate(allowSelfSigned: allowSelfSignedCertificates),
            delegateQueue: nil
        )
        return session
    }()
    
    // URL Session Delegate for handling authentication challenges
    private final class CertificateDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
        let allowSelfSigned: Bool
        
        init(allowSelfSigned: Bool) {
            self.allowSelfSigned = allowSelfSigned
        }
        
        func urlSession(
            _ session: URLSession,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            #if DEBUG
            print("🔐 Received authentication challenge")
            print("   - Method: \(challenge.protectionSpace.authenticationMethod)")
            print("   - Host: \(challenge.protectionSpace.host)")
            print("   - Protocol: \(challenge.protectionSpace.protocol ?? "none")")
            #endif
            
            // Handle server trust (certificate validation)
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if allowSelfSigned {
                    #if DEBUG
                    print("⚠️ Accepting self-signed certificate (allowSelfSignedCertificates = true)")
                    #endif
                    
                    if let serverTrust = challenge.protectionSpace.serverTrust {
                        let credential = URLCredential(trust: serverTrust)
                        completionHandler(.useCredential, credential)
                        return
                    }
                } else {
                    #if DEBUG
                    print("🔒 Using default certificate validation")
                    #endif
                }
            }
            
            // Use default handling for other cases
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private var baseURL: URL? {
        guard let url = URL(string: serverURL) else { return nil }
        // Use OCS API v2 which has better API authentication support
        return url.appendingPathComponent("ocs/v2.php/cloud")
    }
    
    private var authHeader: String {
        let credentials = "\(username):\(password)"
        let credentialsData = credentials.data(using: .utf8)!
        return "Basic \(credentialsData.base64EncodedString())"
    }
    
    private func createRequest(path: String, method: String = "GET") throws -> URLRequest {
        guard let baseURL = baseURL else {
            throw NextcloudAPIError.invalidURL
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("true", forHTTPHeaderField: "OCS-APIREQUEST")  // Changed for v2 API
        
        // Only set Content-Type for requests with body
        if method != "GET" {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    // MARK: - User Management
    
    func fetchUsers() async throws -> [String] {
        let request = try createRequest(path: "users")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextcloudAPIError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 401 {
            throw NextcloudAPIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NextcloudAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(NextcloudUsersResponse.self, from: data)
            return response.ocs.data.users
        } catch {
            throw NextcloudAPIError.decodingError(error)
        }
    }
    
    func fetchUserDetails(userId: String) async throws -> NextcloudUser {
        let request = try createRequest(path: "users/\(userId)")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextcloudAPIError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 401 {
            throw NextcloudAPIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NextcloudAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        #if DEBUG
        // Print raw JSON response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Raw API response for \(userId):")
            print(jsonString)
        }
        #endif
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(NextcloudUserDetailResponse.self, from: data)
            let detail = response.ocs.data
            
            #if DEBUG
            print("🔍 Parsed user detail for \(userId):")
            print("   - ID: \(detail.id ?? "nil")")
            print("   - Enabled: \(detail.enabled?.description ?? "nil")")
            print("   - Display Name: \(detail.displayname ?? "nil")")
            print("   - Email: \(detail.email ?? "nil")")
            print("   - Groups: \(detail.groups?.joined(separator: ", ") ?? "nil")")
            print("   - Last Login: \(detail.lastLogin?.description ?? "nil")")
            print("   - Creation Timestamp: \(detail.creationTimestamp?.description ?? "nil")")
            print("   - Backend: \(detail.backend ?? "nil")")
            #endif
            
            var quota: NextcloudUser.UserQuota?
            if let q = detail.quota,
               let quotaValue = q.quota,
               let used = q.used,
               let free = q.free,
               let relative = q.relative {
                quota = NextcloudUser.UserQuota(
                    quota: quotaValue,
                    used: used,
                    free: free,
                    relative: relative
                )
            }
            
            var lastLogin: Date?
            if let timestamp = detail.lastLogin, timestamp > 0 {
                // Nextcloud returns timestamps in milliseconds, but sometimes in seconds
                // If the timestamp is too large (year > 3000), it's likely in milliseconds
                let timestampValue = TimeInterval(timestamp)
                
                #if DEBUG
                print("📅 LastLogin timestamp for \(userId): \(timestamp)")
                #endif
                
                // Check if this looks like milliseconds (very large number)
                // Timestamps after year 2100 are ~4 billion, milliseconds would be ~4 trillion
                if timestampValue > 10_000_000_000 {
                    // Likely milliseconds, convert to seconds
                    lastLogin = Date(timeIntervalSince1970: timestampValue / 1000.0)
                    #if DEBUG
                    print("   ↳ Converted from milliseconds: \(lastLogin!)")
                    #endif
                } else {
                    // Already in seconds
                    lastLogin = Date(timeIntervalSince1970: timestampValue)
                    #if DEBUG
                    print("   ↳ Used as seconds: \(lastLogin!)")
                    #endif
                }
            }
            
            var creationDate: Date?
            if let timestamp = detail.creationTimestamp, timestamp > 0 {
                // Apply same logic for creation timestamp
                let timestampValue = TimeInterval(timestamp)
                
                #if DEBUG
                print("📅 CreationTimestamp for \(userId): \(timestamp)")
                #endif
                
                if timestampValue > 10_000_000_000 {
                    creationDate = Date(timeIntervalSince1970: timestampValue / 1000.0)
                    #if DEBUG
                    print("   ↳ Converted from milliseconds: \(creationDate!)")
                    #endif
                } else {
                    creationDate = Date(timeIntervalSince1970: timestampValue)
                    #if DEBUG
                    print("   ↳ Used as seconds: \(creationDate!)")
                    #endif
                }
            } else {
                #if DEBUG
                print("⚠️ No creation timestamp found for \(userId)")
                #endif
            }
            
            return NextcloudUser(
                userid: detail.id ?? userId,
                displayname: detail.displayname,
                email: detail.email,
                enabled: detail.enabled ?? false,
                groups: detail.groups ?? [],
                quota: quota,
                lastLogin: lastLogin,
                creationDate: creationDate
            )
        } catch {
            throw NextcloudAPIError.decodingError(error)
        }
    }
    
    func enableUser(userId: String) async throws {
        let request = try createRequest(path: "users/\(userId)/enable", method: "PUT")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextcloudAPIError.networkError(URLError(.badServerResponse))
        }
        
        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Enable user response (\(httpResponse.statusCode)): \(responseString)")
        }
        #endif
        
        if httpResponse.statusCode == 401 {
            throw NextcloudAPIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NextcloudAPIError.serverError("Failed to enable user: HTTP \(httpResponse.statusCode) - \(errorMessage)")
        }
        
        #if DEBUG
        print("✅ User '\(userId)' enabled successfully")
        #endif
    }
    
    func disableUser(userId: String) async throws {
        let request = try createRequest(path: "users/\(userId)/disable", method: "PUT")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextcloudAPIError.networkError(URLError(.badServerResponse))
        }
        
        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Disable user response (\(httpResponse.statusCode)): \(responseString)")
        }
        #endif
        
        if httpResponse.statusCode == 401 {
            throw NextcloudAPIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NextcloudAPIError.serverError("Failed to disable user: HTTP \(httpResponse.statusCode) - \(errorMessage)")
        }
        
        #if DEBUG
        print("✅ User '\(userId)' disabled successfully")
        #endif
    }
    
    func addUserToGroup(userId: String, groupId: String) async throws {
        var request = try createRequest(path: "users/\(userId)/groups", method: "POST")
        
        let bodyString = "groupid=\(groupId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? groupId)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextcloudAPIError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 401 {
            throw NextcloudAPIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NextcloudAPIError.serverError("Failed to add user to group")
        }
    }
    
    func removeUserFromGroup(userId: String, groupId: String) async throws {
        var request = try createRequest(path: "users/\(userId)/groups", method: "DELETE")
        
        let bodyString = "groupid=\(groupId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? groupId)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextcloudAPIError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 401 {
            throw NextcloudAPIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NextcloudAPIError.serverError("Failed to remove user from group")
        }
    }
    
    // MARK: - Group Management
    
    func fetchGroups() async throws -> [String] {
        let request = try createRequest(path: "groups")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NextcloudAPIError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 401 {
            throw NextcloudAPIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NextcloudAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(NextcloudGroupsResponse.self, from: data)
            return response.ocs.data.groups
        } catch {
            throw NextcloudAPIError.decodingError(error)
        }
    }
}

