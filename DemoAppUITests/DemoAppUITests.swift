//
//  DemoAppUITests.swift
//  DemoAppUITests
//
//  Created by William Jin on 2025-11-23.
//

import Testing
@testable import DemoAppSolanaWalletAdapterKit
@testable import SolanaWalletAdapterKit
import SolanaRPC
import Foundation
import SolanaTransactions
import SwiftBorsh
import SimpleKeychain
import Base58



@Suite("Wallet Integration Tests")

class IntegrationTests {
    
    let myApp = AppIdentity(
        name: "testApp",
        url: URL(string: "https://solshare.syc.onl")!,
        icon: "Solshare"
    )
    let keychainStorage: KeychainStorage
    let walletConnectionManager: WalletConnectionManager
    init() {
        keychainStorage = KeychainStorage(
            SimpleKeychain(
                service: "com.myapp.wallets",      // a unique string
                accessGroup: nil,                  // default group
                accessibility: .whenUnlocked,     // accessible only when device unlocked
                accessControlFlags: nil,           // default
                context: nil,                      // default LAContext
                synchronizable: false,             // not synced via iCloud
                attributes: [:]                    // default
            )
        )
        
        walletConnectionManager = WalletConnectionManager(availableWallets: [SolflareWallet.self, BackpackWallet.self], storage: keychainStorage)
    }
    func cleanupKeychain() async throws {
        print("\n--- [TearDown] Cleaning up keychain for next test ---")
        let allItems = try await keychainStorage.retrieveAll()
        for (key, _) in allItems {
            try await keychainStorage.clear(key: key)
        }
        // Also ensure the manager's in-memory state is clean for the next test.
        walletConnectionManager.connectedWallets.removeAll()
    }
    
    @Test("Connect to Backpack wallet")
    @MainActor
    func connectBackpackWallet() async throws {
        var wallet = BackpackWallet(for: myApp, cluster: .mainnet, connection: nil)
        
        print("Opening Backpack for pairing...")
        
        _ = try await wallet.connect()
        print("Wallet paired!")
        print(" Public Key: \(String(describing: wallet.publicKey))")
        print("Session: \(wallet.connection!.session)")
        #expect(wallet.connection != nil)
        #expect(wallet.publicKey != nil)
    }
    @Test("Connect to Solflare wallet")
    @MainActor
    func connectSolflareWallet() async throws {
        var wallet = SolflareWallet(for: myApp, cluster: .devnet, connection: nil)
        print("Opening Solflare for pairing...")
        _ = try await wallet.connect()
        print("Wallet paired!")
        print("Public Key: \(String(describing: wallet.publicKey))")
        print("Session: \(wallet.connection!.session)")
        #expect(wallet.connection != nil)
        #expect(wallet.publicKey != nil)
    }
    
    
    @Test("Manager initializes correctly")
    func testInitialization() async throws {
        // availableWallets
        try await cleanupKeychain()
        #expect(walletConnectionManager.availableWallets.count == 2)
        #expect(walletConnectionManager.availableWallets.contains(where: { $0 == SolflareWallet.self }))
        #expect(walletConnectionManager.availableWallets.contains(where: { $0 == BackpackWallet.self }))

        // availableWalletsMap
        if let solflareType = walletConnectionManager.availableWalletsMap[SolflareWallet.identifier] {
            #expect(solflareType == SolflareWallet.self)
        } else {
            #expect(Bool(false)) // fail test if nil
        }
        if let backpackType = walletConnectionManager.availableWalletsMap[BackpackWallet.identifier] {
            #expect(backpackType == BackpackWallet.self)
        } else {
            #expect(Bool(false)) // fail test if nil
        }

        // connectedWallets
        #expect(walletConnectionManager.connectedWallets.isEmpty)

        // storage (optional)
        #expect(walletConnectionManager.connectedWallets.isEmpty == true)
    }

    // MARK: - Pair / Unpair & Recovery

    @Test("Pairing a wallet and recovering it")
    func testPairAndRecoverWallet() async throws {
        try await cleanupKeychain()
        // --- First way of pairing ---
        var walletInstance = try await walletConnectionManager.pair(BackpackWallet.self, for: myApp, cluster: .mainnet)
        #expect(walletConnectionManager.connectedWallets.count == 1)
        try await walletConnectionManager.unpair(&walletInstance)
        #expect(walletConnectionManager.connectedWallets.count == 0)
        print("[debug] Completed first type-based pairing test")

        // --- Second way of pairing ---
        var wallet = BackpackWallet(for: myApp, cluster: .mainnet, connection: nil)
        try await walletConnectionManager.pair(&wallet)
        #expect(walletConnectionManager.connectedWallets.count == 1)
        #expect(walletConnectionManager.connectedWallets[0].connection!.session == wallet.connection!.session)
        #expect(walletConnectionManager.connectedWallets[0].publicKey == wallet.publicKey)
        try await walletConnectionManager.recoverWallets()
        #expect(walletConnectionManager.connectedWallets.count == 1)
        #expect(walletConnectionManager.connectedWallets[0].publicKey == wallet.publicKey)
        #expect(walletConnectionManager.connectedWallets[0].connection!.session == wallet.connection!.session)
        
        try await walletConnectionManager.unpair(&wallet)
        print("[debug] Completed second instance-based pairing and recovery test")

        // --- Corrupted wallet test ---
        try await keychainStorage.store(Data([0x00, 0x01]), key: "corrupted_wallet")
        try await walletConnectionManager.recoverWallets()
        #expect(walletConnectionManager.connectedWallets.count == 0) // only valid wallet recovered
        print("[debug] Completed corrupted wallet recovery test")
    }


    // MARK: - Multiple Wallets / Edge Cases

    @Test("Handle multiple wallets and edge cases")
    func testMultipleWalletsAndIdentifiers() async throws {
        try await cleanupKeychain()
        print("--- Step 1: Pairing Backpack and Solflare ---")
        let backpackWallet = try await walletConnectionManager.pair(
            BackpackWallet.self, for: myApp, cluster: .mainnet)
        let solflareWallet = try await walletConnectionManager.pair(
            SolflareWallet.self, for: myApp, cluster: .devnet)
        #expect(walletConnectionManager.connectedWallets.count == 2)
        #expect(walletConnectionManager.connectedWallets.contains { $0 is BackpackWallet })
        #expect(walletConnectionManager.connectedWallets.contains { $0 is SolflareWallet })
        
        guard let originalBackpackKey = backpackWallet.publicKey,
              let originalSolflareKey = solflareWallet.publicKey
        else {
            #expect(Bool(false), "Failed to get public keys or identifiers after pairing.")
            return
        }
        
        let backpackIdentifier = try WalletConnectionManager.walletIdentifier(for: type(of: backpackWallet), appIdentity: backpackWallet.appId, cluster: backpackWallet.cluster, publicKey: originalBackpackKey)
        let solflareIdentifier = try WalletConnectionManager.walletIdentifier(for: type(of: solflareWallet), appIdentity: solflareWallet.appId, cluster: solflareWallet.cluster, publicKey: originalSolflareKey)
        
        print("Successfully paired Backpack (\(originalBackpackKey)) with ID: \(backpackIdentifier)")
        print("Successfully paired Solflare (\(originalSolflareKey)) with ID: \(solflareIdentifier)")
        
        print("\n--- Step 2: Verifying Identifier Uniqueness and Determinism ---")
        #expect(backpackIdentifier != solflareIdentifier, "Wallet identifiers must be unique!")
        let regeneratedBackpackId = try WalletConnectionManager.walletIdentifier(
            for: BackpackWallet.self,
            appIdentity: myApp,
            cluster: .mainnet,
            publicKey: originalBackpackKey
        )
        let regeneratedSolflareId = try WalletConnectionManager.walletIdentifier(
            for: SolflareWallet.self,
            appIdentity: myApp,
            cluster: .devnet,
            publicKey: originalSolflareKey
        )
        
        #expect(regeneratedBackpackId == backpackIdentifier, "Backpack identifier is not deterministic.")
        #expect(regeneratedSolflareId == solflareIdentifier, "Solflare identifier is not deterministic.")
        print("Identifier uniqueness and determinism verified.")
        
        print("\n--- Step 3: Simulating App Restart and Recovering Wallets ---")
        
        walletConnectionManager.connectedWallets.removeAll()
        #expect(walletConnectionManager.connectedWallets.isEmpty)

        try await walletConnectionManager.recoverWallets()
        
        #expect(walletConnectionManager.connectedWallets.count == 2)
            
        let recoveredKeys = Set(walletConnectionManager.connectedWallets.compactMap(\.publicKey))
        #expect(recoveredKeys.contains(originalBackpackKey))
        #expect(recoveredKeys.contains(originalSolflareKey))
        print("Successfully recovered both wallets from storage.")
        
        print("\n--- Step 4: Unpairing Backpack wallet ---")
        
        guard var backpackToUnpair = walletConnectionManager.connectedWallets.first(where: { $0 is BackpackWallet }) as? BackpackWallet else {
            #expect(Bool(false), "Could not find Backpack wallet in manager to unpair.")
            return
        }
        
        try await walletConnectionManager.unpair(&backpackToUnpair)
        
        #expect(walletConnectionManager.connectedWallets.count == 1)
        #expect(walletConnectionManager.connectedWallets.first is SolflareWallet)
        
        guard let remainingSolflare = walletConnectionManager.connectedWallets.first as? SolflareWallet else {
            #expect(Bool(false), "Remaining wallet is not the expected Solflare wallet.")
            return
        }
        #expect(remainingSolflare.publicKey == originalSolflareKey)
        
        let storageItems = try await keychainStorage.retrieveAll()
        #expect(storageItems.count == 1)
        #expect(storageItems.keys.first == solflareIdentifier)
        
        print("Successfully unpaired Backpack. Solflare wallet remains intact.")
        print("Test completed successfully.")
    }

    // MARK: - Error Handling

    @Test("Handles errors during pairing, recovery, and unpairing")
    func testErrorHandling() async throws {
        // Steps / checks:
        // - Pairing throws if wallet.connect() fails
        // - Recovering handles storage failures gracefully
        // - Unpairing propagates storage clear errors
    }

    
}



@Suite("Transaction and RPC Tests")
struct TransactionAndRPCTests {
    let backpackB58PublicKey1 = "4aMrMVSkJotNykdGN3mhAHX4ByN5zqT4Hmw6MDRz68FH" // 1000000 sol localnet
    let backpackB58PublicKey2 = "6AK9k3ZSy9TZWd1Auz9Aep2gUvb5zkKNQd9PevrNo7Ww" // 100 sol localnet, both 5 sol on devnet
    let solflareB58PublicKey1 = "4WQjwtBG8RtiXaCMXBUBDhNSJgQbJWDi8sNuBDG5x2Lq" // Name: Main Wallet
    let solflareB58PublicKey2 = "3Z2pvaDbckbjTLhN7rhdSXhcCj7DoeBuxdCohd9BsTJY" // Name: WJWALLET
    
    let backpackClient = SolanaRPCClient(
        endpoint: Endpoint.other(
            name: "williams_localnet",
//            url: URL(string: "https://unsplinted-seasonedly-sienna.ngrok-free.dev")! // localnet url for ngrok + solforge
            url: URL(string: "https://api.devnet.solana.com")!
        )
    )
    
    let devNetClient = SolanaRPCClient(
        endpoint: .devnet
    )
    
    let myApp = AppIdentity(
        name: "testApp",
        url: URL(string: "https://solshare.syc.onl")!,
        icon: "Solshare"
    )
    let keychainStorage: KeychainStorage
    let walletConnectionManager: WalletConnectionManager
    init() {
        keychainStorage = KeychainStorage(
            SimpleKeychain(
                service: "com.myapp.wallets",      // a unique string
                accessGroup: nil,                  // default group
                accessibility: .whenUnlocked,     // accessible only when device unlocked
                accessControlFlags: nil,           // default
                context: nil,                      // default LAContext
                synchronizable: false,             // not synced via iCloud
                attributes: [:]                    // default
            )
        )
        
        walletConnectionManager = WalletConnectionManager(availableWallets: [SolflareWallet.self, BackpackWallet.self], storage: keychainStorage)
    }
    
    func cleanupKeychain() async throws {
        print("\n--- [TearDown] Cleaning up keychain for next test ---")
        let allItems = try await keychainStorage.retrieveAll()
        for (key, _) in allItems {
            try await keychainStorage.clear(key: key)
        }
        // Also ensure the manager's in-memory state is clean for the next test.
        walletConnectionManager.connectedWallets.removeAll()
    }
    
    @Test("Fetch wallet balance")
    @MainActor
    func fetchBalance() async throws {
        for publicKey in [backpackB58PublicKey1, backpackB58PublicKey2] {
            print("Fetching balance for (backpack): \(publicKey)")
            
            // Fetch balance using RPC client
            let balance = try await backpackClient.getBalance(publicKey: publicKey)
            
            print("Balance: \(balance) lamports")
            print("Balance: \(String(format: "%.2f", Double(balance) / 1_000_000_000)) SOL")
            
            // Verify balance is valid
            #expect(balance >= 0)
        }
        for publicKey in [solflareB58PublicKey1, solflareB58PublicKey2] {
            print("Fetching balance for (solflare): \(publicKey)")
            
            // Fetch balance using RPC client
            let balance = try await devNetClient.getBalance(publicKey: publicKey)
            
            print("Balance: \(balance) lamports")
            print("Balance: \(String(format: "%.2f", Double(balance) / 1_000_000_000)) SOL")
            
            // Verify balance is valid
            #expect(balance >= 0)
        }
    }
    
    
    @Test("Backpack to Backpack")
    func testBackpackToBackpack() async throws {
        print("==================================================")
        print("Backpack to Backpack")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: BackpackWallet.self,
            cluster: .mainnet,
            client: backpackClient,
            recipientKey1: backpackB58PublicKey1,
            recipientKey2: backpackB58PublicKey2
        )
    }
    
    @Test("Solflare to Solflare")
    func testSolflareToSolflareDevnet() async throws {
        print("==================================================")
        print("Solflare to Solflare")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            client: devNetClient,
            recipientKey1: solflareB58PublicKey1, // just use Main Wallet
            recipientKey2: solflareB58PublicKey1
        )
    }
    @Test("Backpack to Solflare")
        func testBackpackToSolflare() async throws {
            print("==================================================")
            print("Backpack to Solflare Main Wallet")
            print("==================================================")
            try await runStandardTransactionTest(
                walletType: BackpackWallet.self,
                cluster: .mainnet,
                client: backpackClient,
                recipientKey1: solflareB58PublicKey1, // transfer to main wallet
                recipientKey2: solflareB58PublicKey1
            )
        }
    
    @Test("Solflare to Backpack")
    func testSolflareToBackpack() async throws {
        print("==================================================")
        print("Solflare to Backpack Wallet 1")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            client: devNetClient,
            recipientKey1: backpackB58PublicKey1, // Wallet 1
            recipientKey2: backpackB58PublicKey1,
        )
    }

    // Helper functions (add to the struct)
    private func formatSOL(_ lamports: UInt64) -> String {
        String(format: "%.9f", Double(lamports) / 1_000_000_000)
    }

    private func formatKey(_ key: String) -> String {
        let prefix = key.prefix(4)
        let suffix = key.suffix(4)
        return "\(prefix)...\(suffix)"
    }
    
    private func runStandardTransactionTest<W: Wallet>(
        walletType: W.Type,
        cluster: Endpoint,
        client: SolanaRPCClient, // Assuming your clients conform to a common protocol
        recipientKey1: String,
        recipientKey2: String
    ) async throws {
        try await cleanupKeychain()
        
        // 1. Pair the specific wallet for this test
        let wallet = try await walletConnectionManager.pair(walletType, for: myApp, cluster: cluster)
        
        // 2. Define fee payer and recipient using clear variable names
        let feePayerB58 = wallet.publicKey!.description
        
        let recipientB58 = feePayerB58 == recipientKey2
                    ? recipientKey1
                    : recipientKey2
        
        let lamports: Int64 = 100_000_000 // 0.1 SOL
        
        print("\n=== Testing \(walletType) on \(cluster) ===")
        print("Fee Payer: \(formatKey(feePayerB58))")
        print("Recipient: \(formatKey(recipientB58))")
        
        print("\n--- BEFORE TRANSACTION ---")
        let fromBalanceBefore = try await client.getBalance(publicKey: feePayerB58)
        let toBalanceBefore = try await client.getBalance(publicKey: recipientB58)
        print("From: \(formatSOL(fromBalanceBefore)) SOL")
        print("To:   \(formatSOL(toBalanceBefore)) SOL")
        print("---------------------------\n")
        
        print("Building transaction...")
        
        // Use the correct client for the specified cluster
        let blockhash = try await client.getLatestBlockhash().blockhash
        let recipientPublicKey = PublicKey(bytes: Data(base58Encoded: recipientB58)!)
        
        let instruction = SystemProgram.transfer(from: wallet.publicKey!, to: recipientPublicKey, lamports: lamports)
        let transaction = try Transaction(blockhash: blockhash) { instruction }

        print("Signing and sending transaction...")
        let response = try await wallet.signAndSendTransaction(transaction: transaction, sendOptions: nil)
        let signature = response.signature
        print("Signature: \(signature)")

        try await Task.sleep(nanoseconds: 2_000_000_000)

        print("Fetching transaction status...")
        let transactionInfo = try await client.getTransaction(signature: signature.description)

        // Check for errors
        if let meta = transactionInfo.meta,
           case let .object(metaDict) = meta,
           let errValue = metaDict["err"] {
            switch errValue {
            case .null:
                print("Transaction successful.")
            default:
                #expect(Bool(false), "Transaction failed with error: \(errValue)")
                return
            }
        }

        // manual inspection in app shows that the balances changed
    }
    
    private func runTransactionWithRPCSend<W: Wallet> (walletType: W.Type, cluster: Endpoint, client: SolanaRPCClient,
       recipientKey1: String,
       recipientKey2: String
    ) async throws {
        try await cleanupKeychain()
        // 1. Pair the specific wallet for this test
        let wallet = try await walletConnectionManager.pair(walletType, for: myApp, cluster: cluster)
        // 2. Define fee payer and recipient using clear variable names
        let feePayerB58 = wallet.publicKey!.description
        
        let recipientB58 = feePayerB58 == recipientKey2
        ? recipientKey1
        : recipientKey2
        
        let lamports: Int64 = 100_000_000 // 0.1 SOL
        
        print("\n=== Testing \(walletType) on \(cluster) ===")
        print("Fee Payer: \(formatKey(feePayerB58))")
        print("Recipient: \(formatKey(recipientB58))")
        
        print("\n--- BEFORE TRANSACTION ---")
        let fromBalanceBefore = try await client.getBalance(publicKey: feePayerB58)
        let toBalanceBefore = try await client.getBalance(publicKey: recipientB58)
        print("From: \(formatSOL(fromBalanceBefore)) SOL")
        print("To:   \(formatSOL(toBalanceBefore)) SOL")
        print("---------------------------\n")
        
        print("Building transaction...")
        
        // Use the correct client for the specified cluster
        let blockhash = try await client.getLatestBlockhash().blockhash
        let recipientPublicKey = PublicKey(bytes: Data(base58Encoded: recipientB58)!)
        
        let instruction = SystemProgram.transfer(from: wallet.publicKey!, to: recipientPublicKey, lamports: lamports)
        let transaction = try Transaction(blockhash: blockhash) { instruction }
        
        print("Signing but not yet sending transaction")
        let response = try await wallet.signTransaction(transaction: transaction)
        let signedTransaction = response.transaction
        print("Signed transaction!")
        
        
        
        
        
    }
}
