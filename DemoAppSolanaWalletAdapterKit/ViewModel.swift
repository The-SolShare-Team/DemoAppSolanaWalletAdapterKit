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
    class ViewModel {
        let appId = AppIdentity(
            name: "Demo App Solana Wallet Adapter Kit",
            url: URL(string: "https://solshare.team")!,
            icon: "favicon.ico"
        )
        let cluster = Endpoint.devnet
        
        let keychain: SimpleKeychain
        let walletManager: WalletConnectionManager

        init() {
            keychain = SimpleKeychain()
            walletManager = WalletConnectionManager(storage: KeychainStorage(keychain))
            
            Task { [weak self] in
                try await self?.walletManager.recoverWallets()
            }
        }
    }
}
