//
//  ViewModel.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by Dang Khoa Chiem on 2025-11-06.
//

import SimpleKeychain
import SolanaRPC
import SolanaTransactions
import SolanaWalletAdapterKit
import SwiftUI

@Observable
class ViewModel {
    let appId = AppIdentity(
        name: "Demo App Solana Wallet Adapter Kit",
        url: URL(string: "https://solshare.team")!,
        icon: "favicon.ico"
    )
    let cluster = Endpoint.devnet
    let solanaRPC = SolanaRPCClient(endpoint: .devnet)

    let keychain: SimpleKeychain
    var walletManager: WalletConnectionManager

    var selectedPublicKey: PublicKey? = nil

    init() {
        keychain = SimpleKeychain()
        walletManager = WalletConnectionManager(storage: KeychainStorage(keychain))

        Task { [weak self] in
            try await self?.walletManager.recoverWallets()
        }
    }

    func signTransaction(toAccount: PublicKey, lamportsAmount: Int64, send: Bool) async throws -> String? {
        guard let selectedPublicKey = selectedPublicKey,
            let selectedWallet = walletManager.connectedWallets[selectedPublicKey]
        else { return nil }

        let latestBlockhash = try await solanaRPC.getLatestBlockhash().blockhash
        let transaction = try SolanaTransactions.Transaction(
            feePayer: selectedPublicKey,
            blockhash: latestBlockhash
        ) {
            SystemProgram.transfer(
                from: selectedPublicKey,
                to: toAccount,
                lamports: lamportsAmount)
        }

        if send {
            let response = try await selectedWallet.signAndSendTransaction(transaction: transaction, sendOptions: nil)
            return String(describing: response.signature)
        } else {
            let response = try await selectedWallet.signTransaction(transaction: transaction)
            return String(describing: response.transaction)
        }
    }
}
