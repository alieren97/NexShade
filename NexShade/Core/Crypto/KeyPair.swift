//
//  KeyPair.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//


import Foundation

/// Represents an ECDSA key pair
struct KeyPair: Equatable {
    
    /// Private key (raw representation)
    let privateKey: Data
    
    /// Public key (raw representation)
    let publicKey: Data
    
    /// Initialize with raw key data
    init(privateKey: Data, publicKey: Data) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }
    
    /// Private key as hex string
    var privateKeyHex: String {
        privateKey.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Public key as hex string
    var publicKeyHex: String {
        publicKey.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Public key as base64 string (for transmission)
    var publicKeyBase64: String {
        publicKey.base64EncodedString()
    }
}
