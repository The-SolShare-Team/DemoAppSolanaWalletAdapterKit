//
//  multiWalletAdapter.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-22.
//

import Foundation
import SolanaWalletAdapterKit
import SolanaKit
import SwiftUI


class MultiWalletAdapter: ObservableObject {
    @Published var connectedWallets: [Wallet] = []
    @Published var activeWallet: Wallet?

    func connect() {
        // Create wallet via factory
        
    }

    func disconnect(wallet: Wallet) {
        connectedWallets.removeAll { $0.id == wallet.id }

        if activeWallet?.id == wallet.id {
            activeWallet = nil
        }
    }
}
