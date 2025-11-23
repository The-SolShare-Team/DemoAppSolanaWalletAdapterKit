import Foundation
import SolanaWalletAdapterKit
import SolanaRPC
import SolanaTransactions
import Combine
import SwiftBorsh

class WalletData: Identifiable, Equatable{
    let wallet: DeeplinkWallet
    
    var balance: UInt64?
//    {
//        didSet { updateFormattedBalance() }
//    }
    var publicKey: String?
    
    var formattedBalance: String {
        guard let balance = balance else { return "Loading..." }
        return String(format: "%.2f", Double(balance) / 1_000_000_000)
    }
    var formattedPublicKey: String {
        guard let key = publicKey else { return "----" }
        let prefix = key.prefix(4)
        let suffix = key.suffix(4)
        return "\(prefix)...\(suffix)"
    }
    
    
    let id = UUID()
    
    init(wallet: DeeplinkWallet) {
        self.wallet = wallet
        self.balance = nil
        self.publicKey = wallet.connection?.walletPublicKey
        
//        updateFormattedPublicKey()
//        updateFormattedBalance()
    }
    
    var provider: String {
        switch wallet {
        case is BackpackWallet:
            return BackpackWallet.name
        case is SolflareWallet:
            return SolflareWallet.name
        default:
            return "Unknown Wallet"
        }
    }
    
    static func == (lhs: WalletData, rhs: WalletData) -> Bool {
        return lhs.id == rhs.id
    }
}
//extension WalletData {
//    private func updateFormattedPublicKey() {
//        guard let key = publicKey else {
//            formattedPublicKey = "----"
//            return
//        }
//        let prefix = key.prefix(4)
//        let suffix = key.suffix(4)
//        formattedPublicKey = "\(prefix)...\(suffix)"
//    }
//    
//    private func updateFormattedBalance() {
//        guard let balance = balance else {
//            formattedBalance = "Loading..."
//            return
//        }
//        formattedBalance = String(format: "%.2f", Double(balance) / 1_000_000_000)
//    }
//}

// The ViewModel manages the collection of wallets and the current selection.
class WalletViewModel: ObservableObject {
    public var wallets: [WalletData] = []
    // Track the selected wallet by its public key.
    @Published var selectedWallet: WalletData? {
        didSet {
            print("Changed selected wallet to public key: \(selectedWallet?.publicKey ?? "No Key")")
            fetchBalance(for: selectedWallet!)
        }
    }
    
    func printWallets() {
        print("=== Wallets Changed ===")
        print("Total wallets: \(wallets.count)")
        for (index, wallet) in wallets.enumerated() {
            print("Wallet \(index + 1): \(wallet.provider) - PublicKey: \(wallet.publicKey ?? "nil")")
        }
        print("=======================")
    }
    func addWallet(_ wallet: DeeplinkWallet) {
        let walletData = WalletData(wallet: wallet)
        
        guard let publicKey = walletData.publicKey else {
            print("Cannot add wallet without public key")
            return
        }
        
        // Check for duplicates by public key
        let isDuplicate = wallets.contains { existingWalletData in
            existingWalletData.publicKey == publicKey
        }
        
        if !isDuplicate {
            wallets.append(walletData)
            
            // Automatically select the newly added wallet
            selectedWallet = walletData
            
            // Fetch its balance
            fetchBalance(for: walletData)
        }
        
        printWallets()
    }
    
    func disconnectWallet(_ wallet: WalletData) {
        guard let publicKey = wallet.publicKey else { return }
        
        wallets.removeAll { $0.publicKey == publicKey }
        
        // If the disconnected wallet was selected, clear the selection.
        if selectedWallet == wallet {
            selectedWallet = wallets.first
        }
        
        printWallets()
    }
    
    func formatBalance(_ balance: UInt64?) -> String {
        String(format: "%.2f", Double(balance ?? 0) / 1_000_000_000)
    }
    
    func formatPublicKey(_ key: String) -> String {
        let prefix = key.prefix(4)
        let suffix = key.suffix(4)
        return "\(prefix)...\(suffix)"
    }
    
    private let rpcClient: SolanaRPCClient = SolanaRPCClient(
        endpoint: Endpoint.other(url: URL(string: "https://unsplinted-seasonedly-sienna.ngrok-free.dev")!))
    
    func fetchBalance(for walletData: WalletData) {
        guard let pubkey = walletData.publicKey else {
            print("Public key is not available for \(walletData.provider).")
            return
        }
        
        Task {
            do {
                let newBalance = try await rpcClient.getBalance(publicKey: pubkey)
                
                // Find the wallet and update its balance.
                // Since WalletData is a class (reference type), we can modify it directly.
                await MainActor.run {
                    if let wallet = wallets.first(where: { $0.publicKey == pubkey }) {
                        wallet.balance = newBalance
                    }
                }
            } catch {
                print("Failed to fetch balance for \(walletData.provider): \(error)")
            }
        }
    }
    
    
    
    func buildTransaction(from: String, to: String, lamports: Int64) async throws -> String{
        var signature : String = "No sig"
        do {
            let fromPubkey = try PublicKey(from)
            let toPubkey = try PublicKey(to)
            let blockhash = try await rpcClient.getLatestBlockhash().blockhash
            let instruction = SystemProgram.transfer(from: fromPubkey, to: toPubkey, lamports: lamports)
            let transaction = try Transaction(blockhash: blockhash) {
                instruction
            }
            print("Transaction successfully built, sending payload to provider method using wallet w/ pubkey \(selectedWallet?.publicKey ?? "No pubkey")")
            // --- DEBUGGING STEP ---
            print("=== DEBUG: Transaction ===")
            print("Lamports to transfer: \(lamports)")
            print("Instruction: \(instruction)")
            print("Transaction: \(transaction)")
            print("=================================")
            
            let response = try await selectedWallet?.wallet.signAndSendTransaction(transaction: transaction)
            // update balances
            for wallet in wallets {
                if wallet.publicKey == from || wallet.publicKey == to {
                    fetchBalance(for: wallet)
                }
            }
            
            signature = response?.signature ?? "No sig"
            print("Transaction signed and sent with signature: \(signature) bytes")
        }catch {
            let errorMsg = "Failed to build transaction for SOL transfer from \(from) to \(to): \(error.localizedDescription)"
            print(errorMsg)
            return errorMsg
        }
        if signature == "No sig" {
            return signature
        }
        // --- NEW: Poll using getTransaction ---
        do {
            print("Fetching transaction info for signature: \(signature)")
            let transactionInfo = try await rpcClient.getTransaction(signature: signature)
            
            // transactionInfo is a tuple: (slot, blockTime, meta, transaction, version)
            if let meta = transactionInfo.meta,
               case let .object(metaDict) = meta,
               let errValue = metaDict["err"] {
                // errValue is a JSONValue
                switch errValue {
                case .null:
                    print("No error in transaction")
                default:
                    let error = "Transaction failed with error: \(errValue)"
                    print(error)
                    return error
                }
            }
            
            let slot = transactionInfo.slot
            let version = transactionInfo.version
            print("Transaction succeeded at slot \(slot), version: \(version.map { "\($0)" } ?? "nil")")
            return "Transaction successful! Signature: \(signature), slot: \(slot)"
            
        } catch {
            print("Failed to fetch transaction info for signature \(signature): \(error)")
            return "Failed to get transaction info: \(error)"
        }
    }
}

