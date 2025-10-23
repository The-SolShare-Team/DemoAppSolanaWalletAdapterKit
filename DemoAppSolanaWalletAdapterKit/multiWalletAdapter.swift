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

// each provider function is wrapped for convenient calling
// should probably include this as an example implementation in docs

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
        await UIApplication.shared.open(connectionUrl!)
    }
    
    func disconnect() async throws {
        let disconnectUrl = try await activeWallet?.disconnect(redirectLink: "\(redirectProtocol)disconnected")
        await UIApplication.shared.open(disconnectUrl!)
    }
    
    func signAndSendTransaction(transaction: Data, sendOptions: SendOptions?) async throws {
        let signAndSendTransUrl = try await activeWallet?.signAndSendTransaction(redirectLink: "\(redirectProtocol)signAndSendTransaction", transaction: transaction, sendOptions: sendOptions)
        await UIApplication.shared.open(signAndSendTransUrl!)
    }
    
    func signAllTransactions(transactions: [Data]) async throws {
        let signAllUrl = try await activeWallet?.signAndSendTransaction(redirectLink: "\(redirectProtocol)signAllTransactions", transactions: transactions)
        await UIApplication.shared.open(signAllUrl!)
    }
    
    func signTransaction(transaction: Data) async throws {
        let signTransUrl = try await activeWallet?.signTransaction(redirectLink: "\(redirectProtocol)signTransaction", transaction: transaction)
        await UIApplication.shared.open(signTransUrl!)
    }
    func signMessage(message: String, encodingFormat: EncodingFormat?) async throws {
        let signMessageUrl = try await activeWallet?.signMessage(redirectLink: "\(redirectProtocol)signMessage", message: message, encodingFormat: encodingFormat)
        await UIApplication.shared.open(signMessageUrl!)
    }
    
    func browse(url: String, ref: String) async throws {
        let browseUrl = try await activeWallet?.browse(url: url, ref: ref)
        await UIApplication.shared.open(browseUrl!)
    }
    
    
}
