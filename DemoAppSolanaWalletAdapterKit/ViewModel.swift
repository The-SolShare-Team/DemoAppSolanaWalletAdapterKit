//
//  ViewModel.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Dang Khoa Chiem on 2025-11-06.
//

import SwiftUI
import SolanaWalletAdapterKit
import SolanaRPC

extension ContentView {
    @Observable
    class ViewModel {
        let appId = AppIdentity(
            name: "Demo App Solana Wallet Adapter Kit",
            url: URL(string: "https://chiem.me")!,
            icon: "test"
        )
        let keychain = Keychain()

        // Wallet must be created asynchronously after self is initialized
        private(set) var wallet: SolflareWallet?

        init() {
            // Optionally kick off async setup from init without blocking
            Task { [weak self] in
                await self?.setupWallet()
            }
        }

        @MainActor
        func setupWallet() async {
            do {
                let w = try await SolflareWallet(for: appId, cluster: .devnet, restoreFrom: keychain)
                self.wallet = w
            } catch {
                print("Failed to create wallet: \(error)")
            }
        }

        func pairSolflare() async {
            print("Pairing with Solflare...")
            if wallet == nil {
                print("Wallet not initialized yet. Initializing now...")
                await setupWallet()
            }
            do {
                try await wallet!.pair()
                if let pubkey = wallet!.connection?.walletPublicKey {
                    print("Wallet Public Key: \(pubkey)")
                }
                print("Paired successfully with Solflare!")
            } catch {
                print("Pairing failed: \(error)")
            }
        }

        func unpairSolflare() async {
            print("Unpairing with Solflare...")
            guard let wallet else {
                print("No wallet to unpair.")
                return
            }
            do {
                try await wallet.unpair()
                print("Unpaired successfully with Solflare!")
            } catch {
                print("Unpair failed: \(error)")
            }
        }
    }
}
