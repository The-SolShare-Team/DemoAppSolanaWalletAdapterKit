//
//  DemoAppSolanaWalletAdapterKitApp.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SwiftUI

@main
struct DemoAppSolanaWalletAdapterKitApp: App {
    
    @StateObject private var pathManager = NavigationPathManager()  // navigation stack path environment object
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pathManager)
        }
    }
}
