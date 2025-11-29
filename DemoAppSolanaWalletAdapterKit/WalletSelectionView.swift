import SwiftUI
import SolanaWalletAdapterKit
import SolanaRPC

// 1. Add this wrapper helper to make the Wallet types iterable
struct WalletTypeWrapper: Identifiable {
    let id: String
    let walletType: any Wallet.Type
    
    init(_ walletType: any Wallet.Type) {
        self.id = walletType.identifier
        self.walletType = walletType
    }
}

struct WalletRow: View {
    let wallet: any Wallet.Type
    let onConnect: () -> Void
    @State private var isLoading: Bool = false
    
    var body: some View {
        Button(action: {
            isLoading = true
            Task {
                onConnect()
                isLoading = false
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "wallet.pass")
                    .walletIconStyle()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(describing: wallet))
                        .walletNameStyle()
                    
                    if wallet.isProbablyAvailable() {
                        Text("Available to connect")
                            .detectedTextStyle()
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

struct WalletSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ContentView.ViewModel.self) var viewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    VStack(spacing: 8) {
                        Image(systemName: "wallet.pass")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        
                        Text("Connect a Wallet")
                            .font(.title2.bold())
                            .connectTextStyle()
                        
                        Text("Choose your preferred Solana wallet to connect with this demo app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Available Wallets List
                    VStack(spacing: 12) {
                        // 2. Map the wallets to the wrapper
                        let wallets = viewModel.walletManager.availableWallets.map { WalletTypeWrapper($0) }
                        
                        // 3. Iterate over the wrapper
                        ForEach(wallets) { wrapper in
                            WalletRow(wallet: wrapper.walletType) {
                                Task {
                                    await handleWalletConnection(wrapper.walletType)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Select Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleWalletConnection(_ wallet: any Wallet.Type) async {
        do {
            _ = try await viewModel.walletManager.pair(wallet, for: viewModel.appId, cluster: viewModel.cluster)
            dismiss()
        } catch {
            print("Wallet connection failed: \(error)")
        }
    }
}
