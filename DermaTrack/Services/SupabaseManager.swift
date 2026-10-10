//
//  SupabaseManager.swift
//  DermaTrack
//
//  Created by Julia Marek on 10/10/2026.
//


import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(
                string: "https://mtakndbmbqiwbgixiqco.supabase.co"
            )!,
            supabaseKey: "sb_publishable_SMrCg16jpNr6-CoB3yE25Q_szmBGGS3"
        )
    }
}
