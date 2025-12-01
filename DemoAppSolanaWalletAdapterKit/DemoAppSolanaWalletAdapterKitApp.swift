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
    init() {
        SolanaWalletAdapter.registerCallbackScheme("demoappsolanawalletadapterkitcallback")
    }

    var body: some Scene {
        WindowGroup {
//            ContentView()
//                .onOpenURL {
//                    if SolanaWalletAdapter.handleOnOpenURL($0) { return }
//                }
            EmptyView()
        }
    }
}
