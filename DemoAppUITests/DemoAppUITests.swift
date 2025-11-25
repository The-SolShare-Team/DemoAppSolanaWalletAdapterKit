
//
//  DemoAppUITests.swift
//  DemoAppUITests
//
//  Created by William Jin on 2025-11-23.
//

import Testing
import CryptoKit
@testable import DemoAppSolanaWalletAdapterKit
@testable import SolanaWalletAdapterKit
import SolanaRPC
import Foundation
import SolanaTransactions
import SwiftBorsh
import SimpleKeychain
import Base58

// MARK: - Global Constants
let backpackB58PublicKey1 = "4aMrMVSkJotNykdGN3mhAHX4ByN5zqT4Hmw6MDRz68FH" // 1000000 sol localnet
let backpackB58PublicKey2 = "6AK9k3ZSy9TZWd1Auz9Aep2gUvb5zkKNQd9PevrNo7Ww" // 100 sol localnet, both 5 sol on devnet

let solflareB58PublicKey1 = "4WQjwtBG8RtiXaCMXBUBDhNSJgQbJWDi8sNuBDG5x2Lq" // Name: Main Wallet
let solflareB58PublicKey2 = "3Z2pvaDbckbjTLhN7rhdSXhcCj7DoeBuxdCohd9BsTJY" // Name: WJWALLET

let phantomB58PublicKey1 = "FN9SyYhkWWwa88R8VReBdLnMUeX4yMrGFcDEmbtw9AnN" // WJ1
let phantomB58PublicKey2 = "CCyzatoBEznSjBbLvLZRWBKFCrz1vGcPXW66t8fxNu1i" // WJ2

let myApp = AppIdentity(
    name: "testApp",
    url: URL(string: "https://solshare.syc.onl")!,
    icon: "Solshare"
)

let backpackDevNetClient = SolanaRPCClient(
    endpoint: Endpoint.other(
        name: "mainnet-beta",
//        url: URL(string: "https://unsplinted-seasonedly-sienna.ngrok-free.dev")! // localnet url for ngrok + solforge
        url: URL(string: "https://api.devnet.solana.com")!
    )
)

let devNetClient = SolanaRPCClient(
    endpoint: .devnet
)

// MARK: - Global Helper Functions
func formatSOL(_ lamports: UInt64) -> String {
    String(format: "%.9f", Double(lamports) / 1_000_000_000)
}

func formatKey(_ key: String) -> String {
    let prefix = key.prefix(4)
    let suffix = key.suffix(4)
    return "\(prefix)...\(suffix)"
}

func createWalletInfrastructure(availableWallets: [any Wallet.Type]? = nil) -> (KeychainStorage, WalletConnectionManager) {
    let keychainStorage = KeychainStorage(
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
    
    let walletConnectionManager: WalletConnectionManager
    if let wallets = availableWallets {
        walletConnectionManager = WalletConnectionManager(availableWallets: wallets, storage: keychainStorage)
    } else {
        walletConnectionManager = WalletConnectionManager(storage: keychainStorage)
    }
    
    return (keychainStorage, walletConnectionManager)
}

func cleanupKeychain(_ walletConnectionManager: WalletConnectionManager, _ keychainStorage: KeychainStorage) async throws {
    print("\n--- [TearDown] Cleaning up keychain for next test ---")
    let allItems = try await keychainStorage.retrieveAll()
    for (key, _) in allItems {
        try await keychainStorage.clear(key: key)
    }
    // Also ensure the manager's in-memory state is clean for the next test.
    walletConnectionManager.connectedWallets.removeAll()
}

@Suite("Wallet Integration Tests")
class IntegrationTests {
    let keychainStorage: KeychainStorage
    let walletConnectionManager: WalletConnectionManager
    
    init() {
        (keychainStorage, walletConnectionManager) = createWalletInfrastructure()
    }
    
    @Test("Connect to Backpack wallet")
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
    
    @Test("Connect to Phantom wallet")
    func connectPhantomWallet() async throws {
        var wallet = PhantomWallet(for: myApp, cluster: .devnet, connection: nil)
        print("Opening Phantom for pairing...")
        _ = try await wallet.connect()
        print("Wallet paired!")
        print("Public Key: \(String(describing: wallet.publicKey))")
        print("Session: \(wallet.connection!.session)")
        #expect(wallet.connection != nil)
        #expect(wallet.publicKey!.description == phantomB58PublicKey1 || wallet.publicKey!.description == phantomB58PublicKey2)
    }
    
    @Test("Manager initializes correctly")
    func testInitialization() async throws {
        // availableWallets
        try await cleanupKeychain(walletConnectionManager, keychainStorage)
        #expect(walletConnectionManager.availableWallets.count == 3)
        #expect(walletConnectionManager.availableWallets.contains(where: { $0 == SolflareWallet.self }))
        #expect(walletConnectionManager.availableWallets.contains(where: { $0 == BackpackWallet.self }))
        #expect(walletConnectionManager.availableWallets.contains(where: { $0 == PhantomWallet.self }))

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
        if let phantomType = walletConnectionManager.availableWalletsMap[PhantomWallet.identifier] {
            #expect(phantomType == PhantomWallet.self)
        } else {
            #expect(Bool(false)) // fail test if nil
        }

        // connectedWallets
        #expect(walletConnectionManager.connectedWallets.isEmpty)
    }

    // MARK: - Pair / Unpair & Recovery

    @Test("Pairing a wallet and recovering it")
    func testPairAndRecoverWallet() async throws {
        try await cleanupKeychain(walletConnectionManager, keychainStorage)
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
        try await cleanupKeychain(walletConnectionManager, keychainStorage)
        print("--- Step 1: Pairing Backpack, Solflare, and Phantom ---")
        let backpackWallet = try await walletConnectionManager.pair(
            BackpackWallet.self, for: myApp, cluster: .mainnet)
        let solflareWallet = try await walletConnectionManager.pair(
            SolflareWallet.self, for: myApp, cluster: .devnet)
        let phantomWallet = try await walletConnectionManager.pair(
            PhantomWallet.self, for: myApp, cluster: .devnet)

        #expect(walletConnectionManager.connectedWallets.count == 3)
        #expect(walletConnectionManager.connectedWallets.contains { $0 is BackpackWallet })
        #expect(walletConnectionManager.connectedWallets.contains { $0 is SolflareWallet })
        #expect(walletConnectionManager.connectedWallets.contains { $0 is PhantomWallet })

        guard let originalBackpackKey = backpackWallet.publicKey,
              let originalSolflareKey = solflareWallet.publicKey,
              let originalPhantomKey = phantomWallet.publicKey
        else {
            #expect(Bool(false), "Failed to get public keys or identifiers after pairing.")
            return
        }
        
        let backpackIdentifier = try WalletConnectionManager.walletIdentifier(for: type(of: backpackWallet), appIdentity: backpackWallet.appId, cluster: backpackWallet.cluster, publicKey: originalBackpackKey)
        let solflareIdentifier = try WalletConnectionManager.walletIdentifier(for: type(of: solflareWallet), appIdentity: solflareWallet.appId, cluster: solflareWallet.cluster, publicKey: originalSolflareKey)
        let phantomIdentifier = try WalletConnectionManager.walletIdentifier(for: type(of: phantomWallet), appIdentity: phantomWallet.appId, cluster: phantomWallet.cluster, publicKey: originalPhantomKey)
        
        print("Successfully paired Backpack (\(originalBackpackKey)) with ID: \(backpackIdentifier)")
        print("Successfully paired Solflare (\(originalSolflareKey)) with ID: \(solflareIdentifier)")
        print("Successfully paired Phantom (\(originalPhantomKey)) with ID: \(phantomIdentifier)")
        
        print("\n--- Step 2: Verifying Identifier Uniqueness and Determinism ---")
        #expect(backpackIdentifier != solflareIdentifier, "Wallet identifiers must be unique!")
        #expect(backpackIdentifier != phantomIdentifier, "Wallet identifiers must be unique!")
        #expect(solflareIdentifier != phantomIdentifier, "Wallet identifiers must be unique!")
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
        let regeneratedPhantomId = try WalletConnectionManager.walletIdentifier(
            for: PhantomWallet.self,
            appIdentity: myApp,
            cluster: .devnet,
            publicKey: originalPhantomKey
        )
        
        #expect(regeneratedBackpackId == backpackIdentifier, "Backpack identifier is not deterministic.")
        #expect(regeneratedSolflareId == solflareIdentifier, "Solflare identifier is not deterministic.")
        #expect(regeneratedPhantomId == phantomIdentifier, "Phantom identifier is not deterministic.")
        print("Identifier uniqueness and determinism verified.")
        
        print("\n--- Step 3: Simulating App Restart and Recovering Wallets ---")
        
        walletConnectionManager.connectedWallets.removeAll()
        #expect(walletConnectionManager.connectedWallets.isEmpty)

        try await walletConnectionManager.recoverWallets()
        
        #expect(walletConnectionManager.connectedWallets.count == 3)
            
        let recoveredKeys = Set(walletConnectionManager.connectedWallets.compactMap(\.publicKey))
        #expect(recoveredKeys.contains(originalBackpackKey))
        #expect(recoveredKeys.contains(originalSolflareKey))
        #expect(recoveredKeys.contains(originalPhantomKey))
        print("Successfully recovered all wallets from storage.")
        
        print("\n--- Step 4: Unpairing Backpack wallet ---")
        
        guard var backpackToUnpair = walletConnectionManager.connectedWallets.first(where: { $0 is BackpackWallet }) as? BackpackWallet else {
            #expect(Bool(false), "Could not find Backpack wallet in manager to unpair.")
            return
        }
        
        try await walletConnectionManager.unpair(&backpackToUnpair)
        
        #expect(walletConnectionManager.connectedWallets.count == 2)
        #expect(walletConnectionManager.connectedWallets.contains { $0 is SolflareWallet })
        #expect(walletConnectionManager.connectedWallets.contains { $0 is PhantomWallet })
        
        guard let remainingSolflare = walletConnectionManager.connectedWallets.first(where: { $0 is SolflareWallet }) as? SolflareWallet else {
            #expect(Bool(false), "Could not find Solflare wallet after unpairing.")
            return
        }
        guard let remainingPhantom = walletConnectionManager.connectedWallets.first(where: { $0 is PhantomWallet }) as? PhantomWallet else {
            #expect(Bool(false), "Could not find Phantom wallet after unpairing.")
            return
        } // NEW
        #expect(remainingSolflare.publicKey == originalSolflareKey)
        #expect(remainingPhantom.publicKey == originalPhantomKey)
        
        let storageItems = try await keychainStorage.retrieveAll()
        let expectedIdentifiers = Set([solflareIdentifier, phantomIdentifier])
        #expect(storageItems.count == 2)
        #expect(Set(storageItems.keys) == expectedIdentifiers)
        
        print("Successfully unpaired Backpack. Solflare and Phantom wallets remain intact.") // CHANGED
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

@Suite("signTransaction + RPC / signAndSendTransaction Tests")
struct TransactionAndRPCTests {
    let keychainStorage: KeychainStorage
    let walletConnectionManager: WalletConnectionManager
    
    init() {
        (keychainStorage, walletConnectionManager) = createWalletInfrastructure(availableWallets: [SolflareWallet.self, BackpackWallet.self])
    }
    
    @Test("Fetch wallet balance")
    
    func fetchBalance() async throws {
        for publicKey in [backpackB58PublicKey1, backpackB58PublicKey2] {
            print("Fetching balance for (backpack): \(publicKey)")
            
            // Fetch balance using RPC client
            let balance = try await backpackDevNetClient.getBalance(publicKey: publicKey)
            
            print("Balance: \(balance) lamports")
            print("Balance: \(String(format: "%.2f", Double(balance) / 1_000_000_000)) SOL")
            
            // Verify balance is valid
            #expect(balance >= 0)
        }
        for publicKey in [solflareB58PublicKey1, solflareB58PublicKey2, phantomB58PublicKey1, phantomB58PublicKey2] {
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
            client: backpackDevNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: backpackB58PublicKey1,
            recipientKey2: backpackB58PublicKey2
        )
    }
    
    @Test("Solflare to Solflare")
    func testSolflareToSolflare() async throws {
        print("==================================================")
        print("Solflare to Solflare")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: solflareB58PublicKey1,
            recipientKey2: solflareB58PublicKey2
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
            client: backpackDevNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
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
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: backpackB58PublicKey1, // Wallet 1
            recipientKey2: backpackB58PublicKey1,
        )
    }
    
    
    @Test("Phantom to Phantom")
    func testPhantomToPhantom() async throws {
        print("==================================================")
        print("Phantom to Phantom")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: PhantomWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: phantomB58PublicKey1,
            recipientKey2: phantomB58PublicKey2
        )
    }

    @Test("Phantom to Backpack")
    func testPhantomToBackpack() async throws {
        print("==================================================")
        print("Phantom to Backpack Wallet 1")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: PhantomWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: backpackB58PublicKey1, // transfer to wallet 1
            recipientKey2: backpackB58PublicKey1
        )
    }

    @Test("Backpack to Phantom")
    func testBackpackToPhantom() async throws {
        print("==================================================")
        print("Backpack to Phantom Wallet 1")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: BackpackWallet.self,
            cluster: .mainnet,
            client: backpackDevNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: phantomB58PublicKey1, // transfer to WJ1
            recipientKey2: phantomB58PublicKey1
        )
    }

    @Test("Phantom to Solflare")
    func testPhantomToSolflare() async throws {
        print("==================================================")
        print("Phantom to Solflare Main Wallet")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: PhantomWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: solflareB58PublicKey1, // transfer Main Wallet
            recipientKey2: solflareB58PublicKey1
        )
    }

    @Test("Solflare to Phantom")
    func testSolflareToPhantom() async throws {
        print("==================================================")
        print("Solflare to Phantom Wallet 1")
        print("==================================================")
        try await runStandardTransactionTest(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: phantomB58PublicKey1, // WJ1
            recipientKey2: phantomB58PublicKey1,
        )
    }
    
    @Test("Backpack to Backpack using sendTransaction + RPC")
    func testBackpackToBackpackWithRPCSend() async throws {
        print("==================================================")
        print("Backpack to Backpack using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: BackpackWallet.self,
            cluster: .mainnet,
            client: backpackDevNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: backpackB58PublicKey1,
            recipientKey2: backpackB58PublicKey2
        )
    }

    @Test("Solflare to Solflare using sendTransaction + RPC")
    func testSolflareToSolflareWithRPCSend() async throws {
        print("==================================================")
        print("Solflare to Solflare using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: solflareB58PublicKey1,
            recipientKey2: solflareB58PublicKey2
        )
    }

    @Test("Backpack to Solflare using sendTransaction + RPC")
    func testBackpackToSolflareWithRPCSend() async throws {
        print("==================================================")
        print("Backpack to Solflare Main Wallet using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: BackpackWallet.self,
            cluster: .mainnet,
            client: backpackDevNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: solflareB58PublicKey1, // transfer to main wallet
            recipientKey2: solflareB58PublicKey1
        )
    }

    @Test("Solflare to Backpack using sendTransaction + RPC")
    func testSolflareToBackpackWithRPCSend() async throws {
        print("==================================================")
        print("Solflare to Backpack Wallet 1 using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: backpackB58PublicKey1, // Wallet 1
            recipientKey2: backpackB58PublicKey1,
        )
    }


    @Test("Phantom to Phantom using sendTransaction + RPC")
    func testPhantomToPhantomWithRPCSend() async throws {
        print("==================================================")
        print("Phantom to Phantom using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: PhantomWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: phantomB58PublicKey1,
            recipientKey2: phantomB58PublicKey2
        )
    }

    @Test("Phantom to Backpack using sendTransaction + RPC")
    func testPhantomToBackpackWithRPCSend() async throws {
        print("==================================================")
        print("Phantom to Backpack Wallet 1 using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: PhantomWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: backpackB58PublicKey1, // transfer to wallet 1
            recipientKey2: backpackB58PublicKey1
        )
    }

    @Test("Backpack to Phantom using sendTransaction + RPC")
    func testBackpackToPhantomWithRPCSend() async throws {
        print("==================================================")
        print("Backpack to Phantom Wallet 1 using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: BackpackWallet.self,
            cluster: .mainnet,
            client: backpackDevNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: phantomB58PublicKey1, // WJ1
            recipientKey2: phantomB58PublicKey1
        )
    }

    @Test("Phantom to Solflare using sendTransaction + RPC")
    func testPhantomToSolflareWithRPCSend() async throws {
        print("==================================================")
        print("Phantom to Solflare Main Wallet using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: PhantomWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: solflareB58PublicKey1, // transfer to main wallet
            recipientKey2: solflareB58PublicKey1
        )
    }

    @Test("Solflare to Phantom using sendTransaction + RPC")
    func testSolflareToPhantomWithRPCSend() async throws {
        print("==================================================")
        print("Solflare to Phantom Wallet 1 using sendTransaction + RPC")
        print("==================================================")
        try await runTransactionWithRPCSend(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey1: phantomB58PublicKey1, // WJ1
            recipientKey2: phantomB58PublicKey1,
        )
    }
    
    @Test("Send two transactions with options")
    func testSendTransactionWithOptions() async throws {
        try await cleanupKeychain(walletConnectionManager, keychainStorage)
        
        let walletType = PhantomWallet.self
        let cluster = Endpoint.devnet
        let client = devNetClient
        let lamports: Int64 = 100_000_000 // 0.1 SOL
        
        print("Pairing \(walletType) for send options test...")
        let wallet = try await walletConnectionManager.pair(walletType, for: myApp, cluster: cluster)
        guard let fromPublicKey = wallet.publicKey else {
            #expect(Bool(false), "Could not get public key from paired wallet.")
            return
        }
        // For simplicity, we will send the transaction back to the sender's own address.
        let recipientPublicKey = fromPublicKey
        print("Using wallet \(formatKey(fromPublicKey.description)) as both sender and recipient.")
        print("\n--- [Test 1] Building and sending transaction with configuration tuple ---")
        let transaction1 = try await buildTransferTransaction(
            client: client,
            fromPublicKey: fromPublicKey,
            toPublicKey: recipientPublicKey,
            lamports: lamports
        )
        let signedResponse1 = try await wallet.signTransaction(transaction: transaction1)
        let signedTransaction1 = try Transaction(bytes: Data(base58Encoded: signedResponse1.transaction)!)
        
        let config1: (
            encoding: TransactionEncoding?,
            skipPreflight: Bool?,
            preflightCommitment: Commitment?,
            maxRetries: Int?,
            minContextSlot: Int?
        ) = (
            encoding: .base64,         // Test with base64 encoding
            skipPreflight: false,       // Perform preflight checks
            preflightCommitment: .confirmed, // Wait for 'confirmed' commitment
            maxRetries: nil,
            minContextSlot: nil
        )
        
        print("Sending transaction 1 with options: encoding=base64, preflightCommitment=confirmed")
        let signature1 = try await client.sendTransaction(transaction: signedTransaction1, configuration: config1)
        print("Transaction 1 sent. Signature: \(signature1)")
        #expect(signedTransaction1.signatures.first == signature1)
        
        print("\n--- [Test 2] Building and sending transaction with TransactionOptions struct ---")
        let transaction2 = try await buildTransferTransaction(
            client: client,
            fromPublicKey: fromPublicKey,
            toPublicKey: recipientPublicKey,
            lamports: lamports
        )
        
        // Sign the second transaction
        let signedResponse2 = try await wallet.signTransaction(transaction: transaction2)
        let signedTransaction2 = try Transaction(bytes: Data(base58Encoded: signedResponse2.transaction)!)
        
        // Define options using the struct
        let options2 = TransactionOptions(
            encoding: .base58,         // Test with default base58 encoding
            skipPreflight: true,        // Skip preflight checks
            preflightCommitment: .processed, // Use a lower commitment level
            maxRetries: 3,              // Set a max retry count
            minContextSlot: nil
        )
        
        print("Sending transaction 2 with options: skipPreflight=true, maxRetries=3")
        let signature2 = try await client.sendTransaction(transaction: signedTransaction2, transactionOptions: options2)
        print("Transaction 2 sent. Signature: \(signature2)")
        #expect(signedTransaction2.signatures.first == signature2)
        
        print("\n--- Verifying both transactions on-chain ---")
        // Wait a few seconds for transactions to be finalized
        try await Task.sleep(nanoseconds: 4_000_000_000)

        // Verify transaction 1
        print("Verifying transaction 1: \(signature1)...")
        let transactionInfo1 = try await client.getTransaction(signature: signature1.description)
        if let meta = transactionInfo1.meta, case let .object(metaDict) = meta, let errValue = metaDict["err"] {
            switch errValue {
            case .null: print("Transaction 1 successful.")
            default: #expect(Bool(false), "Transaction 1 failed with error: \(errValue)")
            }
        }

        // Verify transaction 2
        print("Verifying transaction 2: \(signature2)...")
        let transactionInfo2 = try await client.getTransaction(signature: signature2.description)
        if let meta = transactionInfo2.meta, case let .object(metaDict) = meta, let errValue = metaDict["err"] {
            switch errValue {
            case .null: print("Transaction 2 successful.")
            default: #expect(Bool(false), "Transaction 2 failed with error: \(errValue)")
            }
        }
        
        print("\nSend options test completed successfully.")
    }
    

}

@Suite("Sign All Transactions Tests")
struct SignAllTransactionsTests {
    let keychainStorage: KeychainStorage
    let walletConnectionManager: WalletConnectionManager
    
    init() {
        (keychainStorage, walletConnectionManager) = createWalletInfrastructure()
    }
    
    @Test("Backpack signAllTransactions and send")
    func testBackpackSignAllTransactions() async throws {
        let sol: Int64 = 100_000_000
        let amounts: [Int64] = [sol, sol, 2*sol]
        try await signAndSendAllTransactionsTest(
            label: "Backpack",
            walletType: BackpackWallet.self,
            client: backpackDevNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey: PublicKey(bytes: Data(base58Encoded: solflareB58PublicKey1)!),
            myApp: myApp,
            amounts: amounts
        )
    }
    
    @Test("Solflare signAllTransactions and send")
    func testSolflareSignAllTransactions() async throws {
        let sol: Int64 = 100_000_000
        let amounts: [Int64] = [sol, sol, sol]
        try await signAndSendAllTransactionsTest(
            label: "Solflare",
            walletType: SolflareWallet.self,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey: PublicKey(bytes: Data(base58Encoded: backpackB58PublicKey1)!),
            myApp: myApp,
            amounts: amounts
        )
    }
    
    @Test("Phantom signAllTransactions and send")
    func testPhantomSignAllTransactions() async throws {
        let sol: Int64 = 100_000_000
        let amounts: [Int64] = [sol, sol, sol]
        try await signAndSendAllTransactionsTest(
            label: "Phantom",
            walletType: PhantomWallet.self,
            client: devNetClient,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage,
            recipientKey: PublicKey(bytes: Data(base58Encoded: phantomB58PublicKey2)!),
            myApp: myApp,
            amounts: amounts
        )
    }
}

@Suite("signMessage tests")
struct signMessageTests {
    let keychainStorage: KeychainStorage
    let walletConnectionManager: WalletConnectionManager
    
    init() {
        (keychainStorage, walletConnectionManager) = createWalletInfrastructure()
    }
    @Test("BackpackWallet: sign and verify message")
        func backpackSignMessageTest() async throws {
            let message = "Hello from Backpack!"
            let messageData = message.data(using: .utf8)!
            
            try await runSignAndVerifyMessageTest(
                walletType: BackpackWallet.self,
                cluster: .mainnet,
                messageData: messageData,
                display: .utf8,
                walletConnectionManager: walletConnectionManager
            )
        }
        
        @Test("PhantomWallet: sign and verify message")
        func phantomSignMessageTest() async throws {
            let message = "Hello from Phantom!"
            let messageData = message.data(using: .utf8)!
            
            try await runSignAndVerifyMessageTest(
                walletType: PhantomWallet.self,
                cluster: .devnet,
                messageData: messageData,
                display: .utf8,
                walletConnectionManager: walletConnectionManager
            )
        }

        @Test("SolflareWallet: sign and verify message")
        func solflareSignMessageTest() async throws {
            let message = "Hello from Solflare!"
            let messageData = message.data(using: .utf8)!
            
            try await runSignAndVerifyMessageTest(
                walletType: SolflareWallet.self,
                cluster: .devnet,
                messageData: messageData,
                display: .utf8,
                walletConnectionManager: walletConnectionManager
            )
        }
}


@Suite("Browse tests")
struct browseTests {
    let keychainStorage: KeychainStorage
    let walletConnectionManager: WalletConnectionManager
    
    init() {
        (keychainStorage, walletConnectionManager) = createWalletInfrastructure()
    }

    // Backpack tests
    @Test("Backpack: browse via WalletConnectionManager", .timeLimit(.minutes(5)))
    func testBackpackBrowseViaManager() async throws {
        let url = URL(string: "https://solscan.io/account/\(backpackB58PublicKey1)")!
        
        print("\n--- Testing Backpack browse via WalletConnectionManager ---")
        try await runBrowseTestViaManager(
            walletType: BackpackWallet.self,
            cluster: .mainnet,
            url: url,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage
        )
    }

    @Test("Backpack: browse with direct instantiation", .timeLimit(.minutes(5)))
    func testBackpackBrowseDirect() async throws {
        let url = URL(string: "https://solscan.io/account/\(backpackB58PublicKey1)")!
        
        print("\n--- Testing Backpack browse with direct instantiation ---")
        var wallet = BackpackWallet(for: myApp, cluster: .mainnet, connection: nil)
        try await runBrowseTestDirectly(
            wallet: &wallet,
            url: url
        )
    }

    // Phantom tests
    @Test("Phantom: browse via WalletConnectionManager", .timeLimit(.minutes(5)))
    func testPhantomBrowseViaManager() async throws {
        let url = URL(string: "https://solscan.io/account/\(phantomB58PublicKey1)")!

        print("\n--- Testing Phantom browse via WalletConnectionManager ---")
        try await runBrowseTestViaManager(
            walletType: PhantomWallet.self,
            cluster: .devnet,
            url: url,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage
        )
    }

    @Test("Phantom: browse with direct instantiation", .timeLimit(.minutes(5)))
    func testPhantomBrowseDirect() async throws {
        let url = URL(string: "https://solscan.io/account/\(phantomB58PublicKey1)")!

        print("\n--- Testing Phantom browse with direct instantiation ---")
        var wallet = PhantomWallet(for: myApp, cluster: .devnet, connection: nil)
        try await runBrowseTestDirectly(
            wallet: &wallet,
            url: url
        )
    }

    // Solflare tests
    @Test("Solflare: browse via WalletConnectionManager", .timeLimit(.minutes(5)))
    func testSolflareBrowseViaManager() async throws {
        let url = URL(string: "https://solscan.io/account/\(solflareB58PublicKey1)")!

        print("\n--- Testing Solflare browse via WalletConnectionManager ---")
        try await runBrowseTestViaManager(
            walletType: SolflareWallet.self,
            cluster: .devnet,
            url: url,
            walletConnectionManager: walletConnectionManager,
            keychainStorage: keychainStorage
        )
    }

    @Test("Solflare: browse with direct instantiation", .timeLimit(.minutes(5)))
    func testSolflareBrowseDirect() async throws {
        let url = URL(string: "https://solscan.io/account/\(solflareB58PublicKey1)")!

        print("\n--- Testing Solflare browse with direct instantiation ---")
        var wallet = SolflareWallet(for: myApp, cluster: .devnet, connection: nil)
        try await runBrowseTestDirectly(
            wallet: &wallet,
            url: url
        )
    }
    
//    @Test("Browse should fail when wallet is not connected")
//    func testBrowseWhenNotConnected() async throws {
//        print("\n--- Testing browse on an unconnected Backpack wallet ---")
//        // Create a wallet instance without pairing it through the manager.
//        let wallet = BackpackWallet(for: myApp, cluster: .mainnet, connection: nil)
//        let url = URL(string: "https://solana.com")!
//
//        // Expect a specific error when trying to browse without an active connection.
//        await #expect(throws: SolanaWalletAdapterError.notConnected) {
//            try await wallet.browse(url: url, ref: myApp.url)
//        }
//        print("Correctly threw WalletAdapterError.notConnected for an unpaired wallet.")
//    }
}

// MARK: - Helper Functions for Browse Tests

/// Runs a browse test using a wallet obtained from the `WalletConnectionManager`.
func runBrowseTestViaManager<W: Wallet>(
    walletType: W.Type,
    cluster: Endpoint,
    url: URL,
    walletConnectionManager: WalletConnectionManager,
    keychainStorage: KeychainStorage
) async throws {
    try await cleanupKeychain(walletConnectionManager, keychainStorage)
    print("\n--- Testing browse for \(walletType) via WalletConnectionManager ---")
    print("URL: \(url)")

    let wallet = try await walletConnectionManager.pair(walletType, for: myApp, cluster: cluster)
    guard let _ = wallet.publicKey else {
        #expect(Bool(false), "Failed to get public key from paired wallet.")
        return
    }

    try await wallet.browse(url: url, ref: myApp.url)
    print("Successfully called browse on connected \(walletType).")
}

/// Runs a browse test using a directly instantiated wallet.
func runBrowseTestDirectly<W: Wallet>(
    wallet: inout W,
    url: URL
) async throws {
    print("\n--- Testing browse for a directly instantiated \(type(of: wallet)) ---")
    print("URL: \(url)")
    
    // 1. Connect the wallet directly
    _ = try await wallet.connect()
    guard let _ = wallet.publicKey else {
        #expect(Bool(false), "Failed to get public key from connected wallet.")
        return
    }
    
    // 2. Call browse. The test passes if no error is thrown.
    try await wallet.browse(url: url, ref: myApp.url)
    print("Successfully called browse on a directly instantiated and connected \(type(of: wallet)).")
}

func runSignAndVerifyMessageTest<W: Wallet>(
        walletType: W.Type,
        cluster: Endpoint,
        messageData: Data,
        display: MessageDisplayFormat? = .utf8,
        walletConnectionManager: WalletConnectionManager
    ) async throws {
        print("\n--- Testing signMessage for \(walletType) ---")
        print("Message Data (\(String(describing: display))): \(messageData.base64EncodedString())")
        
        // 1. Pair the wallet
        let wallet = try await walletConnectionManager.pair(walletType, for: myApp, cluster: cluster)
        guard let publicKey = wallet.publicKey else {
            #expect(Bool(false), "Failed to get public key from paired wallet.")
            return
        }
        print("Wallet Public Key: \(publicKey.description)")
        
        // 2. Sign the message
        let response = try await wallet.signMessage(message: messageData, display: display)
        let signature = response.signature
        print("Got Signature: \(signature.description)")
        
        // 3. Basic Assertions
        #expect(!signature.description.isEmpty, "Signature should not be empty.")
        
        // 4. Cryptographic Verification
        guard let signatureData = Data(base58Encoded: signature.description) else {
            #expect(Bool(false), "Failed to decode signature from Base58.")
            return
        }
        do {
            // Create the public key object from the wallet's raw public key bytes.
            let cryptoPublicKey = try Curve25519.Signing.PublicKey(
                rawRepresentation: publicKey.bytes
            )
            
            let isSignatureValid = cryptoPublicKey.isValidSignature(signatureData, for: messageData)

            #expect(isSignatureValid, "The signature is cryptographically INVALID for the provided message and public key.")
            print("Signature verified successfully!")
            
        } catch {
            // This will catch errors if the public key data has an incorrect length (e.g., not 32 bytes).
            #expect(Bool(false), "Failed to create CryptoKit public key: \(error)")
        }
    }


func runStandardTransactionTest<W: Wallet>(
    walletType: W.Type,
    cluster: Endpoint,
    client: SolanaRPCClient,
    walletConnectionManager: WalletConnectionManager,
    keychainStorage: KeychainStorage,
    recipientKey1: String,
    recipientKey2: String
) async throws {
    try await cleanupKeychain(walletConnectionManager, keychainStorage)
    
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
    
    // Use the helper function to build the transaction, which now also prints balances
    let transaction = try await buildTransferTransaction(
        client: client,
        fromPublicKey: wallet.publicKey!,
        toPublicKey: PublicKey(bytes: Data(base58Encoded: recipientB58)!),
        lamports: lamports
    )

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


func runTransactionWithRPCSend<W: Wallet> (
    walletType: W.Type,
    cluster: Endpoint,
    client: SolanaRPCClient,
    walletConnectionManager: WalletConnectionManager,
    keychainStorage: KeychainStorage,
    recipientKey1: String,
    recipientKey2: String
) async throws {
    try await cleanupKeychain(walletConnectionManager, keychainStorage)
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
    
    // Use the helper function to build the transaction, which now also prints balances
    let transaction = try await buildTransferTransaction(
        client: client,
        fromPublicKey: wallet.publicKey!,
        toPublicKey: PublicKey(bytes: Data(base58Encoded: recipientB58)!),
        lamports: lamports
    )
    
    print("Signing transaction")
    let response = try await wallet.signTransaction(transaction: transaction)
    let signedTransaction = try Transaction(bytes: Data(base58Encoded: response.transaction)!)
    let signedSignature = signedTransaction.signatures.first!
    print("Got signed transaction back with a signature of \(signedSignature.description)")
    
    let confirmedSignature = try await client.sendTransaction(transaction: signedTransaction)
    print("confirmed signature from RPC sendTransaction: \(confirmedSignature.description)")
    assert(confirmedSignature == signedSignature)
    
    try await Task.sleep(nanoseconds: 2_000_000_000)
    print("Fetching transaction status...")
    let transactionInfo = try await client.getTransaction(signature: signedSignature.description)

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

// MARK: - Transaction Building Helper Function

func buildTransferTransaction(
    client: SolanaRPCClient,
    fromPublicKey: PublicKey,
    toPublicKey: PublicKey,
    lamports: Int64
) async throws -> Transaction {
    print("\n--- BEFORE TRANSACTION ---")
    let fromBalanceBefore = try await client.getBalance(publicKey: fromPublicKey.description)
    let toBalanceBefore = try await client.getBalance(publicKey: toPublicKey.description)
    print("From (\(formatKey(fromPublicKey.description))): \(formatSOL(fromBalanceBefore)) SOL")
    print("To (\(formatKey(toPublicKey.description))):   \(formatSOL(toBalanceBefore)) SOL")
    print("---------------------------\n")

    print("Building transaction...")
    let blockhash = try await client.getLatestBlockhash().blockhash
    let instruction = SystemProgram.transfer(
        from: fromPublicKey,
        to: toPublicKey,
        lamports: lamports
    )
    return try Transaction(blockhash: blockhash) { instruction }
}


func signAndSendAllTransactionsTest(
    label: String,
    walletType: any Wallet.Type,
    client: SolanaRPCClient,
    walletConnectionManager: WalletConnectionManager,
    keychainStorage: KeychainStorage,
    recipientKey: PublicKey,
    myApp: AppIdentity,
    amounts: [Int64]
) async throws {
    try await cleanupKeychain(walletConnectionManager, keychainStorage)
    print("Connecting to \(label)...")

    let wallet = try await walletConnectionManager.pair(
        walletType,
        for: myApp,
        cluster: client.endpoint
    )
    guard let publicKey = wallet.publicKey else {
        #expect(Bool(false), "Failed to get \(label) public key.")
        return
    }

    print("\(label) connected: \(formatKey(publicKey.description))")

    var transactions = [] as [Transaction]

    for amount in amounts {
        print("Building \(label) transactions:")
        guard let fromPk = wallet.publicKey
        else {
            #expect(Bool(false), "Could not get public keys.")
            continue
        }

        let tx = try await buildTransferTransaction(
            client: client,
            fromPublicKey: fromPk,
            toPublicKey: recipientKey,
            lamports: amount
        )

        print("\(label) transaction: \(tx)")
        transactions.append(tx)
    }

    let encoded = try await wallet.signAllTransactions(transactions: transactions).transactions
    let decoded: [Transaction] = try encoded.compactMap { encoded in
        guard let bytes = Data(base58Encoded: encoded) else {
            print("Failed to decode transaction: \(encoded)")
            return nil
        }
        return try Transaction(bytes: bytes)
    }

    let signatures = decoded.compactMap { $0.signatures.first }
    print("\(label) Signatures:")
    signatures.enumerated().forEach { i, sig in
        print("  [\(i)] \(sig)")
    }

    for (idx, transaction) in decoded.enumerated() {
        let confirmedSig = try await client.sendTransaction(transaction: transaction)
        assert(signatures[idx] == confirmedSig)
        print("Sent transaction with signature \(confirmedSig.description)")
    }
}
