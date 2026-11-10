//
//  UserProfile.swift
//  DermaTrack
//
//  Created by Julia Marek on 29/10/2026.
//


import Foundation

enum UserRole: String, Codable {
    case patient
    case dermatologist
}

struct UserProfile: Decodable {
    let id: UUID
    let displayName: String?
    let role: UserRole

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case role
    }
}
