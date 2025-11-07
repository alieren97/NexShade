//
//  CryptoError.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//

import Foundation

/// Cryptographic operation errors
enum CryptoError: LocalizedError {
    case keyGenerationFailed(String)
    case keyImportFailed(String)
    case signingFailed(String)
    case verificationFailed(String)
    case encryptionFailed(String)
    case decryptionFailed(String)
    case invalidKeyFormat
    case invalidSignatureFormat
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed(let reason):
            return "Key generation failed: \(reason)"
        case .keyImportFailed(let reason):
            return "Key import failed: \(reason)"
        case .signingFailed(let reason):
            return "Signing failed: \(reason)"
        case .verificationFailed(let reason):
            return "Verification failed: \(reason)"
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .invalidKeyFormat:
            return "Invalid key format"
        case .invalidSignatureFormat:
            return "Invalid signature format"
        case .unknown(let reason):
            return "Cryptographic error: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .keyGenerationFailed:
            return "Try generating new keys."
        case .keyImportFailed:
            return "Check the key format and try again."
        case .signingFailed:
            return "Ensure you have valid credentials."
        case .verificationFailed:
            return "The signature may be invalid or tampered."
        default:
            return "Contact support if the problem persists."
        }
    }
}
