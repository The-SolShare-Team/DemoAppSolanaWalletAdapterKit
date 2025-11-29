import SwiftUI
import SolanaWalletAdapterKit
import SimpleKeychain
import SolanaTransactions
import SolanaRPC
internal import Base58

struct ContentView: View {
    @State private var viewModel = ViewModel()
    @State private var showingWalletSelection: Bool = false
    
    // MARK: - Selected Wallet State
    @State private var varselectedWalletIndex: Int = 0
    
    // MARK: - Disconnect Selection State
    @State private var showingDisconnectSelection: Bool = false
    @State private var selectedWalletsToDisconnect: Set<Int> = []
    
    private var selectedWallet: (any Wallet)? {
        guard !viewModel.connectedWallets.isEmpty,
              viewModel.connectedWallets.indices.contains(selectedWalletIndex) else {
            return nil
        }
        return viewModel.connectedWallets[selectedWalletIndex]
    }
    
    private var connectedWallets: [any Wallet] {
        viewModel.connectedWallets
    }
    
    private var isSwitchEnabled: Bool {
        connectedWallets.count >= 2
    }
    
    private func formatWalletDisplay(_ wallet: any Wallet) -> String {
        let provider = String(describing: type(of: wallet))
        if let publicKey = wallet.publicKey {
            let publicKeyString = publicKey.description
            let shortKey = publicKeyString.prefix(3) + "…" + publicKeyString.suffix(3)
            return "\(provider) wallet: \(shortKey)"
        } else {
            return "\(provider) wallet: unknown"
        }
    }
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        // Connected Wallet Status Card
                        WalletStatusCard(
                            connectedWallets: connectedWallets,
                            selectedWalletIndex: $selectedWalletIndex,
                            onSelectWallet: { index in
                                selectedWalletIndex = index
                            }
                        )
                        
                        // Wallet Management Section
                        DemoSection(title: "Wallet Management", icon: "wrench.and.screwdriver") {
                            DemoButton(
                                title: "Pair Wallets",
                                icon: "link.circle.fill",
                                style: .primary,
                                isLoading: isLoading
                            ) {
                                showingWalletSelection = true
                            }
                            
                            DemoButton(
                                title: "Clear Keychain",
                                icon: "trash.circle.fill",
                                style: .secondary,
                                isLoading: false
                            ) {
                                clearKeychain()
                            }
                            
                            DemoButton(
                                title: "Debug Info",
                                icon: "info.circle.fill",
                                style: .secondary,
                                isLoading: false
                            ) {
                                print(viewModel.walletManager.connectedWallets)
                            }
                            
                            DemoButton(
                                title: "Disconnect Wallet(s)",
                                icon: "xmark.circle.fill",
                                style: .danger,
                                isLoading: isLoading
                            ) {
                                showDisconnectSelection()
                            }
                        }
                        
                        // Transaction Operations Section
                        DemoSection(title: "Transaction Operations", icon: "doc.text.fill") {
                            DemoButton(
                                title: "Sign Transaction",
                                icon: "signature",
                                style: .primary,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await signTransaction()
                                }
                            }
                            
                            DemoButton(
                                title: "Sign All Transactions",
                                icon: "list.bullet.rectangle.portrait.fill",
                                style: .primary,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await signAllTransactions()
                                }
                            }
                            
                            DemoButton(
                                title: "Sign & Send Transaction",
                                icon: "paperplane.fill",
                                style: .primary,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await signAndSendTransaction()
                                }
                            }
                        }
                        
                        // Quick Send Section
                        DemoSection(title: "Quick Send (DEVNET)", icon: "arrow.left.arrow.right.circle.fill") {
                            DemoButton(
                                title: "Send SOL to Phantom",
                                icon: "arrow.up.circle.fill",
                                style: .success,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await sendSOL(toPhantom: true)
                                }
                            }
                            
                            DemoButton(
                                title: "Send SOL from Phantom",
                                icon: "arrow.down.circle.fill",
                                style: .success,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await sendSOL(toPhantom: false)
                                }
                            }
                        }
                        
                        // Other Operations Section
                        DemoSection(title: "Other Operations", icon: "gear.circle.fill") {
                            DemoButton(
                                title: "Sign Message",
                                icon: "envelope.fill",
                                style: .secondary,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await signMessage()
                                }
                            }
                            
                            DemoButton(
                                title: "Browse URL",
                                icon: "safari.fill",
                                style: .secondary,
                                isLoading: isLoading
                            ) {
                                Task {
                                    await browseURL()
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: geometry.size.width > 600 ? 600 : .infinity)
                }
            }
            .background(LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground).opacity(0.8), Color(.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            ))
            .navigationTitle("Solana Wallet Demo")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingWalletSelection) {
                WalletSelectionView()
            }
            .onChange(of: showingWalletSelection) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    // WalletSelectionView was dismissed, refresh connected wallets
                    viewModel.updateConnectedWallets()
                }
            }
            .sheet(isPresented: $showingDisconnectSelection) {
                DisconnectWalletSelectionView(
                    connectedWallets: connectedWallets,
                    selectedWallets: $selectedWalletsToDisconnect,
                    onDisconnect: {
                        Task {
                            await disconnectSelectedWallets()
                        }
                    },
                    onCancel: {
                        selectedWalletsToDisconnect.removeAll()
                    }
                )
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh wallet list when app comes to foreground
                viewModel.updateConnectedWallets()
            }
        }
        .environment(viewModel)
    }
    
    private func clearKeychain() {
        do {
            try viewModel.keychain.deleteAll()
            // Force UI update after clearing keychain
            viewModel.updateConnectedWallets()
        } catch {
            errorMessage = "Failed to clear keychain: \(error.localizedDescription)"
        }
    }
    
    private func showDisconnectSelection() {
        guard !connectedWallets.isEmpty else {
            errorMessage = "No wallets to disconnect."
            return
        }
        selectedWalletsToDisconnect.removeAll()
        showingDisconnectSelection = true
    }
    
    private func disconnectSelectedWallets() async {
        isLoading = true
        defer { isLoading = false }
        
        // Get the wallets to disconnect in order to avoid index mutation issues
        let walletsToDisconnect = selectedWalletsToDisconnect.compactMap { index in
            connectedWallets.indices.contains(index) ? connectedWallets[index] : nil
        }
        
        for var wallet in walletsToDisconnect {
            do {
                try await viewModel.walletManager.unpair(&wallet)
                print("✅ Successfully disconnected \(type(of: wallet))")
            } catch {
                print("❌ Failed to disconnect wallet: \(error)")
                errorMessage = "Failed to disconnect wallet: \(error.localizedDescription)"
            }
        }
        
        // Force UI update after disconnecting wallets
        await MainActor.run {
            viewModel.updateConnectedWallets()
            
            // Reset selected wallet index if necessary
            if selectedWalletIndex >= viewModel.connectedWallets.count {
                selectedWalletIndex = max(0, viewModel.connectedWallets.count - 1)
            }
        }
        
        selectedWalletsToDisconnect.removeAll()
        showingDisconnectSelection = false
    }
    
    private func signTransaction() async {
        isLoading = true
        do {
            guard let wallet = selectedWallet else {
                errorMessage = "No wallet selected."
                isLoading = false
                return
            }
            
            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
            let latestBlockhash = try await solanaRPC.getLatestBlockhash().blockhash
            let transaction = try SolanaTransactions.Transaction(
                feePayer: PublicKey(bytes: Data(base58Encoded: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW")!),
                blockhash: latestBlockhash
            ) {
                SystemProgram.transfer(
                    from: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                    to: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                    lamports: 1_000_000_000
                )
            }
            
            let response = try await wallet.signTransaction(transaction: transaction)
            print(response)
        } catch {
            errorMessage = "Transaction signing failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func signAllTransactions() async {
        isLoading = true
        do {
            guard let wallet = selectedWallet else {
                errorMessage = "No wallet selected."
                isLoading = false
                return
            }
            
            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
            let latestBlockhash = try await solanaRPC.getLatestBlockhash().blockhash
            let transaction1 = try SolanaTransactions.Transaction(
                feePayer: PublicKey(bytes: Data(base58Encoded: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW")!),
                blockhash: latestBlockhash
            ) {
                SystemProgram.transfer(
                    from: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                    to: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                    lamports: 1_000_000_000
                )
            }
            let transaction2 = try SolanaTransactions.Transaction(
                feePayer: PublicKey(bytes: Data(base58Encoded: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW")!),
                blockhash: latestBlockhash
            ) {
                SystemProgram.transfer(
                    from: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                    to: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                    lamports: 100_000_000
                )
            }
            
            let response = try await wallet.signAllTransactions(transactions: [transaction1, transaction2])
            print(response)
        } catch {
            errorMessage = "All transactions signing failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func signAndSendTransaction() async {
        isLoading = true
        do {
            guard let wallet = selectedWallet else {
                errorMessage = "No wallet selected."
                isLoading = false
                return
            }
            
            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
            let latestBlockhash = try await solanaRPC.getLatestBlockhash().blockhash
            let transaction = try SolanaTransactions.Transaction(
                feePayer: PublicKey(bytes: Data(base58Encoded: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW")!),
                blockhash: latestBlockhash
            ) {
                SystemProgram.transfer(
                    from: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW",
                    to: "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                    lamports: 1_000_000_000
                )
            }
            
            let response = try await wallet.signAndSendTransaction(transaction: transaction, sendOptions: nil)
            print(response)
        } catch {
            errorMessage = "Transaction signing and sending failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func signMessage() async {
        isLoading = true
        do {
            guard let wallet = selectedWallet else {
                errorMessage = "No wallet selected."
                isLoading = false
                return
            }
            
            let response = try await wallet.signMessage(
                message: "Hello World!".data(using: .utf8)!,
                display: .utf8
            )
            print(response)
        } catch {
            errorMessage = "Message signing failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func browseURL() async {
        isLoading = true
        do {
            guard let wallet = selectedWallet else {
                errorMessage = "No wallet selected."
                isLoading = false
                return
            }
            
            let response: () = try await wallet.browse(
                url: URL(string: "https://apple.com")!,
                ref: URL(string: "https://solshare.syc.onl")!
            )
            print(response)
        } catch {
            errorMessage = "Browse operation failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func sendSOL(toPhantom: Bool) async {
        isLoading = true
        do {
            guard let wallet = selectedWallet else {
                errorMessage = "No wallet selected."
                isLoading = false
                return
            }
            
            let solanaRPC = SolanaRPCClient(endpoint: .devnet)
            let latestBlockhash = try await solanaRPC.getLatestBlockhash().blockhash
            let transaction = try SolanaTransactions.Transaction(
                feePayer: PublicKey(bytes: Data(base58Encoded: "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW")!),
                blockhash: latestBlockhash
            ) {
                SystemProgram.transfer(
                    from: toPhantom ? "HL94zgjvNNYNvxTWDz2UicxmU24PtmtLghsBkQEhCYSW" : "Gz4m7AXonTJUSYcfJkHa8JLu6PuMwkj7BmAfFkqqKcis",
                    to: toPhantom ? "Gz4m7AXonTJUSYcfJkHa8JLu6PuMwkj7BmAfFkqqKcis" : "CjwgwZHiWUNokw4Xu8fYs6VPw8KYkeADBS9Y2LQVUeiz",
                    lamports: toPhantom ? 1_000_000_000 : 100_000_000
                )
            }
            
            let response = try await wallet.signAndSendTransaction(transaction: transaction, sendOptions: nil)
            print(response)
        } catch {
            errorMessage = "SOL transfer failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Wallet Status Card

struct WalletStatusCard: View {
    let connectedWallets: [any Wallet]
    @Binding var selectedWalletIndex: Int
    let onSelectWallet: (Int) -> Void
    
    private func formatWalletDisplay(_ wallet: any Wallet) -> String {
        let provider = String(describing: type(of: wallet))
        if let publicKey = wallet.publicKey {
            let publicKeyString = publicKey.description
            let shortKey = publicKeyString.prefix(3) + "…" + publicKeyString.suffix(3)
            return "\(provider) wallet: \(shortKey)"
        } else {
            return "\(provider) wallet: unknown"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: connectedWallets.isEmpty ? "wallet.pass" : "checkmark.circle.fill")
                    .foregroundColor(connectedWallets.isEmpty ? .gray : .green)
                    .font(.title2)
                
                Text(connectedWallets.isEmpty ? "No Wallet Connected" : "Wallet Connected")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if !connectedWallets.isEmpty {
                VStack(spacing: 4) {
                    ForEach(Array(connectedWallets.enumerated()), id: \.offset) { index, wallet in
                        HStack {
                            Text(formatWalletDisplay(wallet))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if index == selectedWalletIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            
            // Switch Wallet Button - grayed out when ≤1 wallet, dropdown when ≥2 wallets
            if !isSwitchEnabled {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.title3)
                        Text("Switch Wallet")
                            .font(.subheadline.bold())
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.5))
                .cornerRadius(10)
                .disabled(true)
            } else {
                Menu {
                    ForEach(Array(connectedWallets.enumerated()), id: \.offset) { index, wallet in
                        Button(action: {
                            onSelectWallet(index)
                        }) {
                            HStack {
                                Text(formatWalletDisplay(wallet))
                                    .font(.subheadline)
                                
                                if index == selectedWalletIndex {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.title3)
                        Text("Switch Wallet")
                            .font(.subheadline.bold())
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private var isSwitchEnabled: Bool {
        connectedWallets.count >= 2
    }
}

// MARK: - Demo Section

struct DemoSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                content
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
}

// MARK: - Demo Button

enum DemoButtonStyle {
    case primary
    case secondary
    case success
    case danger
}

struct DemoButton: View {
    let title: String
    let icon: String
    let style: DemoButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: icon)
                        .font(.callout)
                }
                Text(title)
                    .font(.subheadline)
                    .bold()
                Spacer()
            }
            .foregroundColor(isLoading ? .primary : .white)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .opacity(isLoading ? 0.6 : 1)
            )
        }
        .disabled(isLoading)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.purple
        case .secondary:
            return Color.gray
        case .success:
            return Color.green
        case .danger:
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
    }
}

// MARK: - Disconnect Wallet Selection View

struct DisconnectWalletSelectionView: View {
    let connectedWallets: [any Wallet]
    @Binding var selectedWallets: Set<Int>
    let onDisconnect: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private func formatWalletDisplay(_ wallet: any Wallet) -> String {
        let provider = String(describing: type(of: wallet))
        if let publicKey = wallet.publicKey {
            let publicKeyString = publicKey.description
            let shortKey = publicKeyString.prefix(3) + "…" + publicKeyString.suffix(3)
            return "\(provider) wallet: \(shortKey)"
        } else {
            return "\(provider) wallet: unknown"
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(connectedWallets.enumerated()), id: \.offset) { index, wallet in
                    HStack {
                        Text(formatWalletDisplay(wallet))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: selectedWallets.contains(index) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedWallets.contains(index) ? .red : .gray)
                            .font(.title3)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedWallets.contains(index) {
                            selectedWallets.remove(index)
                        } else {
                            selectedWallets.insert(index)
                        }
                    }
                }
            }
            .navigationTitle("Select Wallets to Disconnect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Disconnect") {
                        onDisconnect()
                    }
                    .disabled(selectedWallets.isEmpty)
                    .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}