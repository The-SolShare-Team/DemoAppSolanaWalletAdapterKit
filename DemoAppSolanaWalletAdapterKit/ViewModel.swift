//
//  ViewModel.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Dang Khoa Chiem on 2025-11-06.
//

import SwiftUI
import SolanaWalletAdapterKit
import SolanaRPC
import SimpleKeychain

extension ContentView {
    @Observable
    @MainActor
    class ViewModel{
        let appId = AppIdentity(
            name: "Demo App Solana Wallet Adapter Kit",
            url: URL(string: "https://solshare.syc.onl")!,
            icon: "favicon.ico"
        )
        let cluster = Endpoint.devnet
        
        let keychain: SimpleKeychain
        let walletManager: WalletConnectionManager
        var wallets: [any Wallet] = []
        init() {
            keychain = SimpleKeychain()
            walletManager = WalletConnectionManager(storage: KeychainStorage(keychain))
            
            Task { [weak self] in
                guard let self = self else { return }
                try await self.walletManager.recoverWallets()
                self.refreshWallets()
            }
            
            startPolling()
        }
        
        private func startPolling() {
            Task {
                while true {
                    // Check every 500ms (0.5 seconds)
                    try? await Task.sleep(for: .milliseconds(500))
                    checkForChanges()
                }
            }
        }
        
        private func checkForChanges() {
            let actualWallets = walletManager.connectedWallets
            
            // We compare 'counts' and 'public keys' to see if anything changed.
            // This prevents "Blind Assignment" which causes lag/scroll-stutter.
            let currentKeys = wallets.map { $0.publicKey?.description ?? "nil" }
            let actualKeys = actualWallets.map { $0.publicKey?.description ?? "nil" }
            
            if currentKeys != actualKeys {
                self.wallets = actualWallets
            }
        }
        
        func refreshWallets() {
            self.wallets = walletManager.connectedWallets
        }
        
        func disconnect(_ wallet: inout any Wallet) async throws {
            try await walletManager.unpair(&wallet)
            refreshWallets() // Update immediately, don't wait for the poll
        }
    }
}
