//
//  DemoAppSolanaWalletAdapterKitApp.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Samuel Martineau on 2025-10-13.
//

import SwiftUI
import SolanaWalletAdapterKit

@main
struct DemoAppSolanaWalletAdapterKitApp: App {
    
    @StateObject private var pathManager = NavigationPathManager()  // navigation stack path environment object
    @StateObject private var mwAdapter = MobileWalletAdapter()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pathManager)
                .environmentObject(mwAdapter)
                .onOpenURL { url in
                    if url.scheme == "solanaMWADemo" {
                        Task {
                            do {
                                let result = try await mwAdapter.handleRedirect(url)
                                if let response = result {
                                    print("Redirect Handled Successfully for \(url). Response: \(response)")
                                } else {
                                    print("Redirect Handled for \(url). No specific response returned.")
                                }
                            } catch {
                                print("Error handling redirect URL: \(error.localizedDescription)")
                            }
                        }
                    }
                }
        }
    }
}
