//
//  multiWalletAdapter.swift
//  DemoAppSolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-22.
//

import Foundation
import SolanaWalletAdapterKit
import SwiftUI
import Combine
import CryptoKit

// note that all this works because swift classes are reference type, do NOT do this with structs

// tomorrow, wrap each provider function for easier calling, make a cluster datatype and jsondecode in the wallet function maybe

class MultiWalletAdapter: ObservableObject {
    @Published var storedWallets: [String: Wallet?]
    @Published var activeWallet: Wallet?
    @Published var demoAppMetadataUrl: String
    @Published var redirectProtocol: String
    
    init(demoAppMetadataUrl: String = "https://solshare.syc.onl", redirectProtocol: String = "solanaMWADemo://") {
        storedWallets =
        [ "backpack": nil,
            "solflare": nil,
            "phantom": nil] //put hard coded into a constants file eventually
        activeWallet = nil
        self.demoAppMetadataUrl = demoAppMetadataUrl
        self.redirectProtocol = redirectProtocol
    }
    
//    func checkWhatWalletsExists() -> [String: Bool] {
//        var returnDict: [String : Bool] = [:]
//        for (key, wallet) in storedWallets {
//            returnDict["key"] = (wallet != nil)
//        }
//        return returnDict
//    }
    
    func ensureWalletExists(_ provider: WalletProvider) throws -> Wallet? {
        guard let wallet = storedWallets[provider.rawValue] else {
            throw NSError(domain: "wallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "No wallet found for this provider"])
        }
        return wallet!
    }
    
    
    func activateExistingWallet(provider: WalletProvider) throws {
        let wallet = try ensureWalletExists(provider)
        activeWallet = wallet!
    }
    
    
    func createNewWallet(privateKey: Curve25519.KeyAgreement.PrivateKey?, provider: WalletProvider = WalletProvider.backpack) {
        activeWallet = WalletFactory.createWallet(provider: provider, privateKey: privateKey)!
        storedWallets[activeWallet!.provider.rawValue] = activeWallet
    }
    
    // wrappers for active wallet's provider functions for easier calling and auto passing of certain parameters (namely redirect link)
    
    func connect(cluster: String?) async throws {
        let connectionUrl = try await activeWallet?.connect(appUrl: demoAppMetadataUrl, redirectLink: "\(redirectProtocol)connected", cluster: cluster)
        UIApplication.shared.open(connectionUrl!)
        
    }
    
}
