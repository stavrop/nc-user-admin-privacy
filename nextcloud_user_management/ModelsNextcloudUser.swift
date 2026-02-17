//
//  NextcloudUser.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import Foundation

struct NextcloudUser: Identifiable, Codable, Hashable {
    var id: String { userid }
    
    let userid: String
    var displayname: String?
    var email: String?
    var enabled: Bool
    var groups: [String]
    var quota: UserQuota?
    var lastLogin: Date?
    var creationDate: Date?
    
    struct UserQuota: Codable, Hashable {
        let quota: Int64
        let used: Int64
        let free: Int64
        let relative: Double
    }
}

// Response models for API decoding
struct NextcloudUsersResponse: Codable {
    let ocs: OCSUsersWrapper
    
    struct OCSUsersWrapper: Codable {
        let meta: OCSMeta
        let data: OCSUsersData
    }
    
    struct OCSUsersData: Codable {
        let users: [String]
    }
}

struct NextcloudUserDetailResponse: Codable {
    let ocs: OCSUserDetailWrapper
    
    struct OCSUserDetailWrapper: Codable {
        let meta: OCSMeta
        let data: UserDetail
    }
    
    struct UserDetail: Codable {
        let id: String?
        let enabled: Bool?
        let displayname: String?
        let email: String?
        let groups: [String]?
        let quota: QuotaDetail?
        let lastLogin: Int64?
        let creationTimestamp: Int64?
        let backend: String?
        
        struct QuotaDetail: Codable {
            let quota: Int64?
            let used: Int64?
            let free: Int64?
            let relative: Double?
        }
        
        private enum CodingKeys: String, CodingKey {
            case id, enabled, displayname, email, groups, quota, lastLogin, backend
            case creationTimestamp = "creation_timestamp"
        }
    }
}

struct OCSMeta: Codable {
    let status: String
    let statuscode: Int
    let message: String?
}
