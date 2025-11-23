//
//  DemoAppUITests.swift
//  DemoAppUITests
//
//  Created by William Jin on 2025-11-23.
//

import Testing
@testable import DemoAppSolanaWalletAdapterKit
import SolanaWalletAdapterKit
import SolanaRPC
import Foundation

struct DemoAppUITests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}


@Suite("Wallet Integration Tests")

struct BackpackIntegrationTests {
    let backpackPublicKey1 = "4aMrMVSkJotNykdGN3mhAHX4ByN5zqT4Hmw6MDRz68FH" // 1000000 sol
    let backpackPublicKey2 = "6AK9k3ZSy9TZWd1Auz9Aep2gUvb5zkKNQd9PevrNo7Ww" // 100 sol
    let rpcClient: SolanaRPCClient = SolanaRPCClient(
        endpoint: Endpoint.other(url: URL(string: "https://unsplinted-seasonedly-sienna.ngrok-free.dev")!))
    
    
    let myApp = AppIdentity(
            name: "testApp",
            url: URL(string: "https://solshare.syc.onl")!,
            icon: "Solshare"
        )
        
    @Test("Connect to Backpack wallet")
    @MainActor
    func connectBackpackWallet() async throws {
        let secureStorage = InMemorySecureStorage()
        
        var wallet = try await BackpackWallet(
            for: myApp,
            cluster: Endpoint.mainnet,
            restoreFrom: secureStorage
        )
        
        print("Opening Backpack for pairing...")
        let pairTask = Task {
            try await wallet.pair()
        }
        
        try await pairTask.value
        
        print("Wallet paired!")
        print(" Public Key: \(wallet.connection!.walletPublicKey)")
        print("Session: \(wallet.connection!.session)")
        #expect(wallet.connection != nil)
        #expect(!wallet.connection!.walletPublicKey.isEmpty)
    }
    @Test("Connect to Solflare wallet")
    @MainActor
    func connectSolflareWallet() async throws {
        let secureStorage = InMemorySecureStorage()
        
        var wallet = try await SolflareWallet(
            for: myApp,
            cluster: Endpoint.devnet,
            restoreFrom: secureStorage
        )
        
        print("Opening Solflare for pairing...")
        let pairTask = Task {
            try await wallet.pair()
        }
        
        try await pairTask.value
        
        print("Wallet paired!")
        print(" Public Key: \(wallet.connection!.walletPublicKey)")
        print("Session: \(wallet.connection!.session)")
        #expect(wallet.connection != nil)
        #expect(!wallet.connection!.walletPublicKey.isEmpty)
    }
    
    
    @Test("Fetch wallet balance")
    @MainActor
    func fetchBalance() async throws {
        _ = InMemorySecureStorage()
        
        for publicKey in [backpackPublicKey1, backpackPublicKey2] {
            print("Fetching balance for: \(publicKey)")
            
            // Fetch balance using RPC client
            let balance = try await rpcClient.getBalance(publicKey: publicKey)
            
            print("Balance: \(balance) lamports")
            print("Balance: \(String(format: "%.2f", Double(balance) / 1_000_000_000)) SOL")
            
            // Verify balance is valid
            #expect(balance >= 0)
        }
    }
}
