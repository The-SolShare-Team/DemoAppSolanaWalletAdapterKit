//
//  signTransactionView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-27.
//

import Foundation
import SwiftUI
import SolanaWalletAdapterKit
import SolanaRPC

struct signTransactionView: View {
    @StateObject private var mwAdapter = MobileWalletAdapter()
    var body: some View {
        VStack {
            Text("✅ Transaction Details View")
                .font(.title)
                .padding()
            Text("This view was pushed onto the stack.")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Transaction")
    }
    
    
    func buildTransaction () async throws -> Void {
        let LAMPORTS_PER_SOL: UInt64 = 1_000_000_000
        let transferAmount = LAMPORTS_PER_SOL / 100 // 0.01 SOL
        
        
        
        let client = SolanaRPCClient(endpoint: .devnet)
        var publicKey = mwAdapter.activeWallet?.dappEncryptionPublicKey // fee payer, account public key
        print(try! await client.getVersion())
        let latestHash = try await client.getLatestBlockhash()
        // note to Will: figure out configurations
        let instruction = nil
        
    }
}


