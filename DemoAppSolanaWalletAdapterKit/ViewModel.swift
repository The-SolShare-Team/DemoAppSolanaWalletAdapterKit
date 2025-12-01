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
import SolanaTransactions

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
    let walletManager: WalletConnectionManager
    
    var selectedWalletIndex: Int = -1

    init() {
        keychain = SimpleKeychain()
        walletManager = WalletConnectionManager(storage: KeychainStorage(keychain))
        
        Task { [weak self] in
            try await self?.walletManager.recoverWallets()
        }
    }
    
    func signAndSendTransaction(fromAccount: String, toAccount: String, lamportsAmount: String) async throws {
        do {
            let latestBlockhash = try! await solanaRPC.getLatestBlockhash().blockhash
            let transaction = try! SolanaTransactions.Transaction(
                feePayer: PublicKey(string: fromAccount)!,
                blockhash: latestBlockhash) {
                SystemProgram.transfer(
                    from: PublicKey(string: fromAccount)!,
                    to: PublicKey(string: toAccount)!,
                    lamports: Int64(lamportsAmount)!)
            }
            
            let response = try await walletManager.connectedWallets[selectedWalletIndex].signAndSendTransaction(
                transaction: transaction,
                sendOptions: nil)
            
            print(response)
            
        } catch {
            print("Caught error: \(error)")
        }
    }
    
    func signTransaction(fromAccount: String, toAccount: String, lamportsAmount: String) async throws {
        do {
            let latestBlockhash = try! await solanaRPC.getLatestBlockhash().blockhash
            let transaction = try! SolanaTransactions.Transaction(
                feePayer: PublicKey(string: fromAccount)!,
                blockhash: latestBlockhash) {
                SystemProgram.transfer(
                    from: PublicKey(string: fromAccount)!,
                    to: PublicKey(string: toAccount)!,
                    lamports: Int64(lamportsAmount)!)
            }
            
            let response = try await walletManager.connectedWallets[selectedWalletIndex].signTransaction(transaction: transaction)
            
            print(response)
            
        } catch {
            print("Caught error: \(error)")
        }
    }
}
