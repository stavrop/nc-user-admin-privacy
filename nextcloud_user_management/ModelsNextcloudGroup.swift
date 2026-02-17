//
//  NextcloudGroup.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.

// Copyright (c) 2026 Georgios Stavropoulos. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
//

import Foundation

struct NextcloudGroup: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
}

// Response models for API decoding
struct NextcloudGroupsResponse: Codable {
    let ocs: OCSGroupsWrapper
    
    struct OCSGroupsWrapper: Codable {
        let meta: OCSMeta
        let data: OCSGroupsData
    }
    
    struct OCSGroupsData: Codable {
        let groups: [String]
    }
}
