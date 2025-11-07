//
//  CryptoManager.swift
//  NexShade
//
//  Created by Ali Eren on 7.11.2025.
//


// Core/Crypto/CryptoManager.swift

import Foundation
import CryptoKit
import OSLog

/// Manager for all cryptographic operations using CryptoKit
final class CryptoManager {
    
    // MARK: - Logger
    
    private let logger = Logger(subsystem: "com.pergola.crypto", category: "CryptoManager")
    
    // MARK: - Initialization
    
    init() {
        logger.info("CryptoManager initialized")
    }
    
    // MARK: - Key Generation
    
    /// Generate a new ECDSA P-256 key pair
    /// - Returns: KeyPair containing private and public keys
    /// - Throws: CryptoError if generation fails
    func generateKeyPair() throws -> KeyPair {
        logger.info("Generating ECDSA P-256 key pair")
        
        do {
            // Generate P-256 signing key
            let privateKey = P256.Signing.PrivateKey()
            let publicKey = privateKey.publicKey
            
            // Export keys as raw representation
            let privateKeyData = privateKey.rawRepresentation
            let publicKeyData = publicKey.rawRepresentation
            
            logger.info("Key pair generated successfully")
            
            return KeyPair(
                privateKey: privateKeyData,
                publicKey: publicKeyData
            )
        } catch {
            logger.error("Key generation failed: \(error.localizedDescription)")
            throw CryptoError.keyGenerationFailed(error.localizedDescription)
        }
    }
    
    /// Generate key pair and return as P256 objects
    /// - Returns: Tuple of (PrivateKey, PublicKey)
    /// - Throws: CryptoError if generation fails
    func generateP256KeyPair() throws -> (privateKey: P256.Signing.PrivateKey, publicKey: P256.Signing.PublicKey) {
        logger.info("Generating P-256 key pair objects")
        
        do {
            let privateKey = P256.Signing.PrivateKey()
            let publicKey = privateKey.publicKey
            
            logger.info("P-256 key pair generated successfully")
            return (privateKey, publicKey)
        } catch {
            logger.error("P-256 key generation failed: \(error.localizedDescription)")
            throw CryptoError.keyGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Signing
    
    /// Sign data with private key
    /// - Parameters:
    ///   - data: Data to sign
    ///   - privateKey: P256 private key
    /// - Returns: Signature as Data
    /// - Throws: CryptoError if signing fails
    func sign(_ data: Data, with privateKey: P256.Signing.PrivateKey) throws -> Data {
        logger.info("Signing data (\(data.count) bytes)")
        
        do {
            let signature = try privateKey.signature(for: data)
            logger.info("Data signed successfully")
            return signature.rawRepresentation
        } catch {
            logger.error("Signing failed: \(error.localizedDescription)")
            throw CryptoError.signingFailed(error.localizedDescription)
        }
    }
    
    /// Sign data with private key (Data format)
    /// - Parameters:
    ///   - data: Data to sign
    ///   - privateKeyData: Private key as Data
    /// - Returns: Signature as Data
    /// - Throws: CryptoError if signing fails
    func sign(_ data: Data, withKeyData privateKeyData: Data) throws -> Data {
        logger.info("Signing data with key data")
        
        do {
            // Convert Data to PrivateKey
            let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
            
            // Sign
            let signature = try privateKey.signature(for: data)
            
            logger.info("Data signed successfully")
            return signature.rawRepresentation
        } catch {
            logger.error("Signing with key data failed: \(error.localizedDescription)")
            throw CryptoError.signingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Verification
    
    /// Verify signature with public key
    /// - Parameters:
    ///   - signature: Signature to verify
    ///   - data: Original data that was signed
    ///   - publicKey: P256 public key
    /// - Returns: True if signature is valid
    func verify(signature: Data, for data: Data, publicKey: P256.Signing.PublicKey) -> Bool {
        logger.info("Verifying signature")
        
        do {
            let ecdsaSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
            let isValid = publicKey.isValidSignature(ecdsaSignature, for: data)
            
            logger.info("Signature verification: \(isValid ? "valid" : "invalid")")
            return isValid
        } catch {
            logger.error("Signature verification failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Verify signature with public key (Data format)
    /// - Parameters:
    ///   - signature: Signature to verify
    ///   - data: Original data that was signed
    ///   - publicKeyData: Public key as Data
    /// - Returns: True if signature is valid
    /// - Throws: CryptoError if verification process fails
    func verify(signature: Data, for data: Data, publicKeyData: Data) throws -> Bool {
        logger.info("Verifying signature with key data")
        
        do {
            // Convert Data to PublicKey
            let publicKey = try P256.Signing.PublicKey(rawRepresentation: publicKeyData)
            
            // Verify
            return verify(signature: signature, for: data, publicKey: publicKey)
        } catch {
            logger.error("Verification with key data failed: \(error.localizedDescription)")
            throw CryptoError.verificationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Key Import/Export
    
    /// Import private key from raw representation
    /// - Parameter data: Raw key data
    /// - Returns: P256 private key
    /// - Throws: CryptoError if import fails
    func importPrivateKey(from data: Data) throws -> P256.Signing.PrivateKey {
        logger.info("Importing private key")
        
        do {
            let privateKey = try P256.Signing.PrivateKey(rawRepresentation: data)
            logger.info("Private key imported successfully")
            return privateKey
        } catch {
            logger.error("Private key import failed: \(error.localizedDescription)")
            throw CryptoError.keyImportFailed(error.localizedDescription)
        }
    }
    
    /// Import public key from raw representation
    /// - Parameter data: Raw key data
    /// - Returns: P256 public key
    /// - Throws: CryptoError if import fails
    func importPublicKey(from data: Data) throws -> P256.Signing.PublicKey {
        logger.info("Importing public key")
        
        do {
            let publicKey = try P256.Signing.PublicKey(rawRepresentation: data)
            logger.info("Public key imported successfully")
            return publicKey
        } catch {
            logger.error("Public key import failed: \(error.localizedDescription)")
            throw CryptoError.keyImportFailed(error.localizedDescription)
        }
    }
    
    /// Export private key to raw representation
    /// - Parameter privateKey: P256 private key
    /// - Returns: Raw key data
    func exportPrivateKey(_ privateKey: P256.Signing.PrivateKey) -> Data {
        logger.info("Exporting private key")
        return privateKey.rawRepresentation
    }
    
    /// Export public key to raw representation
    /// - Parameter publicKey: P256 public key
    /// - Returns: Raw key data
    func exportPublicKey(_ publicKey: P256.Signing.PublicKey) -> Data {
        logger.info("Exporting public key")
        return publicKey.rawRepresentation
    }
    
    // MARK: - Hashing
    
    /// Hash data using SHA-256
    /// - Parameter data: Data to hash
    /// - Returns: SHA-256 hash
    func sha256(_ data: Data) -> Data {
        logger.info("Hashing data with SHA-256")
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }
    
    /// Hash string using SHA-256
    /// - Parameter string: String to hash
    /// - Returns: SHA-256 hash
    func sha256(_ string: String) -> Data? {
        guard let data = string.data(using: .utf8) else {
            logger.error("Failed to convert string to data")
            return nil
        }
        return sha256(data)
    }
    
    // MARK: - Random Data Generation
    
    /// Generate cryptographically secure random data
    /// - Parameter length: Number of bytes to generate
    /// - Returns: Random data
    func generateRandomData(length: Int) -> Data {
        logger.info("Generating \(length) bytes of random data")
        
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, length, buffer.baseAddress!)
        }
        
        return data
    }
    
    /// Generate random challenge (32 bytes)
    /// - Returns: Random 32-byte challenge
    func generateChallenge() -> Data {
        logger.info("Generating authentication challenge")
        return generateRandomData(length: 32)
    }
    
    // MARK: - Symmetric Encryption (Bonus)
    
    /// Encrypt data using AES-GCM
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - key: Symmetric key
    /// - Returns: Encrypted data with nonce
    /// - Throws: CryptoError if encryption fails
    func encrypt(_ data: Data, with key: SymmetricKey) throws -> Data {
        logger.info("Encrypting data with AES-GCM")
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed("Failed to get combined data")
            }
            
            logger.info("Data encrypted successfully")
            return combined
        } catch {
            logger.error("Encryption failed: \(error.localizedDescription)")
            throw CryptoError.encryptionFailed(error.localizedDescription)
        }
    }
    
    /// Decrypt data using AES-GCM
    /// - Parameters:
    ///   - data: Encrypted data with nonce
    ///   - key: Symmetric key
    /// - Returns: Decrypted data
    /// - Throws: CryptoError if decryption fails
    func decrypt(_ data: Data, with key: SymmetricKey) throws -> Data {
        logger.info("Decrypting data with AES-GCM")
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            logger.info("Data decrypted successfully")
            return decryptedData
        } catch {
            logger.error("Decryption failed: \(error.localizedDescription)")
            throw CryptoError.decryptionFailed(error.localizedDescription)
        }
    }
}