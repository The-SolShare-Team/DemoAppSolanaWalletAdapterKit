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
    @StateObject private var mwAdapter = MultiWalletAdapter()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pathManager)
                .environmentObject(mwAdapter)
        }
    }
}
