//
//  ContentView.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by The SolShare Team on 2024.
//

import SwiftUI
import SolanaWalletAdapterKit

struct ContentView: View {
    @StateObject private var walletManager = WalletConnectionManager(storage: SecureStorage())
    @State private var showingConnectionError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Header
                Text("Solana Wallet Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Wallet Management Section
                VStack(spacing: 15) {
                    Text("Wallet Management")
                        .font(.headline)
                        .padding(.bottom)
                    
                    // Connected Wallets List
                    if !walletManager.connectedWallets.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Connected Wallets:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(walletManager.connectedWallets.indices, id: \.self) { index in
                                let wallet = walletManager.connectedWallets[index]
                                HStack {
                                    Text(type(of: wallet).identifier)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if let publicKey = wallet.publicKey {
                                        Text(String(publicKey.prefix(8)) + "...")
                                            .font(.caption)
                                            .monospaced()
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Connect Wallet Button
                    Button(action: {
                        Task {
                            await connectWallet()
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Connect Wallet")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    // Disconnect Wallets Button - NEW
                    Button(action: {
                        Task {
                            await disconnectAllWallets()
                        }
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Disconnect Wallets")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(8)
                    .disabled(walletManager.connectedWallets.isEmpty)
                    .opacity(walletManager.connectedWallets.isEmpty ? 0.6 : 1.0)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Quick Actions Section
                VStack(spacing: 10) {
                    Text("Quick Actions")
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        Button("Get Balance") {
                            Task {
                                await getBalance()
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(walletManager.connectedWallets.isEmpty)
                        
                        Button("Send Transaction") {
                            Task {
                                await sendTransaction()
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(walletManager.connectedWallets.isEmpty)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .onAppear {
                Task {
                    await recoverWallets()
                }
            }
            .alert("Connection Error", isPresented: $showingConnectionError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Wallet Actions
    
    private func recoverWallets() async {
        do {
            try await walletManager.recoverWallets()
        } catch {
            errorMessage = "Failed to recover wallets: \(error.localizedDescription)"
            showingConnectionError = true
        }
    }
    
    private func connectWallet() async {
        do {
            // This would typically show a wallet selection UI
            // For demo purposes, we'll connect to the first available wallet
            guard let walletType = walletManager.availableWallets.first else {
                errorMessage = "No wallets available"
                showingConnectionError = true
                return
            }
            
            let appIdentity = AppIdentity(name: "Solana Demo App", uri: "solana-demo://")
            let cluster = Endpoint.mainnetBeta
            
            var wallet = try await walletManager.pair(walletType, for: appIdentity, cluster: cluster)
            print("Successfully connected to \(type(of: wallet).identifier)")
            
        } catch {
            errorMessage = "Failed to connect wallet: \(error.localizedDescription)"
            showingConnectionError = true
        }
    }
    
    private func disconnectAllWallets() async {
        do {
            // Create a mutable copy of connected wallets to disconnect
            let walletsToDisconnect = walletManager.connectedWallets
            
            for var wallet in walletsToDisconnect {
                try await walletManager.unpair(&wallet)
            }
            
            print("Successfully disconnected all wallets")
            
        } catch {
            errorMessage = "Failed to disconnect wallet(s): \(error.localizedDescription)"
            showingConnectionError = true
        }
    }
    
    private func getBalance() async {
        // Implementation would go here
        print("Get balance action")
    }
    
    private func sendTransaction() async {
        // Implementation would go here
        print("Send transaction action")
    }
}

// MARK: - Supporting Styles

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.75))
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}