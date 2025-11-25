//import Foundation
//import SolanaWalletAdapterKit
//import SolanaRPC
//import SolanaTransactions
//import Combine
//import SwiftBorsh
//
//class WalletData: Identifiable, Equatable{
//    let wallet: any DeeplinkWallet
//    
//    var balance: UInt64?
////    {
////        didSet { updateFormattedBalance() }
////    }
//    var publicKey: String?
//    
//    var formattedBalance: String {
//        guard let balance = balance else { return "Loading..." }
//        return String(format: "%.2f", Double(balance) / 1_000_000_000)
//    }
//    var formattedPublicKey: String {
//        guard let key = publicKey else { return "----" }
//        let prefix = key.prefix(4)
//        let suffix = key.suffix(4)
//        return "\(prefix)...\(suffix)"
//    }
//    
//    
//    let id = UUID()
//    
//    init(wallet: any DeeplinkWallet) {
//        self.wallet = wallet
//        self.balance = nil
//        self.publicKey = wallet.connection?.publicKey
//        
////        updateFormattedPublicKey()
////        updateFormattedBalance()
//    }
//    
//    var provider: String {
//        switch wallet {
//        case is BackpackWallet:
//            return BackpackWallet.identifier
//        case is SolflareWallet:
//            return SolflareWallet.identifier
//        default:
//            return "Unknown Wallet"
//        }
//    }
//    
//    static func == (lhs: WalletData, rhs: WalletData) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//
//@MainActor
//class WalletViewModel: ObservableObject {
//
//    // MARK: - Public UI Data
//    @Published var wallets: [WalletData] = []
//    @Published var selectedWallet: WalletData? {
//        didSet {
//            print("Selected wallet changed to: \(selectedWallet?.publicKey ?? "nil")")
//            if let wallet = selectedWallet {
//                Task { await fetchBalance(for: wallet) }
//            }
//        }
//    }
//
//    // MARK: - Managers
//    private let connectionManager: WalletConnectionManager
//    
//    // RPC Client (your ngrok endpoint)
//    private let rpcClient = SolanaRPCClient(
//        endpoint: Endpoint.other(
//            name: "williams_localnet",
//            url: URL(string: "https://unsplinted-seasonedly-sienna.ngrok-free.dev")!
//        )
//    )
//
//    init(connectionManager: WalletConnectionManager) {
//        self.connectionManager = connectionManager
//    }
//
//    // MARK: - Load Stored Wallets
//    func loadWallets() async {
//        do {
//            try await connectionManager.recoverWallets()
//            reloadWalletList()
//        } catch {
//            print("Failed to recover stored wallets: \(error)")
//        }
//    }
//
//    // MARK: - Reload Wallet List from Manager
//    private func reloadWalletList() {
//        wallets = connectionManager.connectedWallets.map { WalletData(wallet: $0) }
//
//        // If nothing selected, auto-select first
//        if selectedWallet == nil {
//            selectedWallet = wallets.first
//        }
//
//        printWallets()
//    }
//
//    // MARK: - Add (Pair) Wallet
//    func addWallet<W: Wallet>(_ walletType: W.Type, appIdentity: AppIdentity, cluster: Endpoint) async {
//        do {
//            try await connectionManager.pair(walletType, for: appIdentity, cluster: cluster)
//            reloadWalletList()
//        } catch {
//            print("Error pairing wallet: \(error)")
//        }
//    }
//
//    // MARK: - Disconnect (Unpair) Wallet
//    func disconnectWallet(_ walletData: WalletData) async {
//        guard var actualWallet = walletData.wallet as? any Wallet else {
//            print("Could not cast to Wallet protocol")
//            return
//        }
//
//        do {
//            try await connectionManager.unpair(&actualWallet)
//            reloadWalletList()
//        } catch {
//            print("Error unpairing wallet: \(error)")
//        }
//    }
//
//    // MARK: - Balance Fetch
//    func fetchBalance(for walletData: WalletData) async {
//        guard let pubkey = walletData.publicKey else {
//            print("No public key for wallet \(walletData.provider)")
//            return
//        }
//
//        do {
//            let newBalance = try await rpcClient.getBalance(publicKey: pubkey)
//            walletData.balance = newBalance
//        } catch {
//            print("Failed to fetch balance for \(walletData.provider): \(error)")
//        }
//    }
//
//    // MARK: - Transaction Builder
//    func buildTransaction(from: String, to: String, lamports: Int64) async throws -> String {
//
//        guard let senderWallet = selectedWallet?.wallet else {
//            return "No wallet selected"
//        }
//
//        do {
//            let fromPubkey = PublicKey(bytes: Data(base58Encoded: from)!)
//            let toPubkey   = PublicKey(bytes: Data(base58Encoded: to)!)
//            let blockhash  = try await rpcClient.getLatestBlockhash().blockhash
//
//            let instruction = SystemProgram.transfer(
//                from: fromPubkey,
//                to: toPubkey,
//                lamports: lamports
//            )
//
//            let transaction = try Transaction(blockhash: blockhash) {
//                instruction
//            }
//
//            print("Signing with wallet PK: \(selectedWallet?.publicKey ?? "nil")")
//
//            let response = try await senderWallet.signAndSendTransaction(transaction: transaction)
//            let signature = response.signature
//
//            // Update balances for both wallets
//            for w in wallets where w.publicKey == from || w.publicKey == to {
//                Task { await fetchBalance(for: w) }
//            }
//
//            // Confirm transaction
//            let txInfo = try await rpcClient.getTransaction(signature: signature)
//            print("TX confirmed in slot \(txInfo.slot)")
//
//            return signature
//
//        } catch {
//            let errorMsg = "Transaction failed: \(error)"
//            print(errorMsg)
//            return errorMsg
//        }
//    }
//
//    // MARK: - Debug
//    private func printWallets() {
//        print("=== Wallet List ===")
//        for w in wallets {
//            print("\(w.provider) - \(w.publicKey ?? "nil")")
//        }
//        print("===================")
//    }
//}
