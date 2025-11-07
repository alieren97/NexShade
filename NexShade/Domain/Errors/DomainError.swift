enum DomainError: LocalizedError, Equatable {
    
    // MARK: - Device Errors
    
    case deviceNotFound
    case deviceAlreadyExists
    case deviceNotConnected
    case connectionFailed(String)
    case disconnectionFailed(String)
    
    // MARK: - Authentication Errors
    
    case authenticationFailed(String)
    case authenticationRequired
    case invalidCredentials
    case credentialsExpired
    
    // MARK: - Permission Errors
    
    case permissionDenied(String)
    case insufficientPermissions
    case ownershipRequired
    
    // MARK: - Command Errors
    
    case commandFailed(String)
    case invalidCommand
    case deviceBusy
    case operationTimeout
    
    // MARK: - User Management Errors
    
    case userNotFound
    case invitationInvalid
    case invitationExpired
    case invitationAlreadyRedeemed
    case maxUsersReached
    
    // MARK: - Data Errors
    
    case dataCorrupted
    case saveFailed(String)
    case deleteFailed(String)
    
    // MARK: - Crypto Errors
    
    case cryptoError(String)
    case keyGenerationFailed
    case signatureFailed
    case verificationFailed
    
    // MARK: - Network/BLE Errors
    
    case bleUnavailable
    case bleUnauthorized
    case characteristicNotFound
    case serviceNotFound
    
    // MARK: - Validation Errors
    
    case invalidInput(String)
    case validationFailed(String)
    
    // MARK: - General Errors
    
    case unknown(String)
    case notImplemented
    
    // MARK: - LocalizedError Conformance
    
    var errorDescription: String? {
        switch self {
        // Device Errors
        case .deviceNotFound:
            return "Device not found"
        case .deviceAlreadyExists:
            return "Device already exists"
        case .deviceNotConnected:
            return "Device is not connected"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .disconnectionFailed(let reason):
            return "Disconnection failed: \(reason)"
            
        // Authentication Errors
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .authenticationRequired:
            return "Authentication required"
        case .invalidCredentials:
            return "Invalid credentials"
        case .credentialsExpired:
            return "Your access has expired"
            
        // Permission Errors
        case .permissionDenied(let reason):
            return "Permission denied: \(reason)"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .ownershipRequired:
            return "Only the owner can perform this action"
            
        // Command Errors
        case .commandFailed(let reason):
            return "Command failed: \(reason)"
        case .invalidCommand:
            return "Invalid command"
        case .deviceBusy:
            return "Device is busy processing another command"
        case .operationTimeout:
            return "Operation timed out"
            
        // User Management Errors
        case .userNotFound:
            return "User not found"
        case .invitationInvalid:
            return "Invalid invitation code"
        case .invitationExpired:
            return "This invitation has expired"
        case .invitationAlreadyRedeemed:
            return "This invitation has already been used"
        case .maxUsersReached:
            return "Maximum number of users reached"
            
        // Data Errors
        case .dataCorrupted:
            return "Data is corrupted"
        case .saveFailed(let reason):
            return "Failed to save: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete: \(reason)"
            
        // Crypto Errors
        case .cryptoError(let reason):
            return "Cryptographic error: \(reason)"
        case .keyGenerationFailed:
            return "Failed to generate encryption keys"
        case .signatureFailed:
            return "Failed to create signature"
        case .verificationFailed:
            return "Signature verification failed"
            
        // Network/BLE Errors
        case .bleUnavailable:
            return "Bluetooth is unavailable"
        case .bleUnauthorized:
            return "Bluetooth permission required"
        case .characteristicNotFound:
            return "Required device characteristic not found"
        case .serviceNotFound:
            return "Required device service not found"
            
        // Validation Errors
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
            
        // General Errors
        case .unknown(let message):
            return "An error occurred: \(message)"
        case .notImplemented:
            return "This feature is not yet implemented"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        // Device Errors
        case .deviceNotFound:
            return "Make sure the device is powered on and nearby, then scan again."
        case .deviceNotConnected:
            return "Connect to the device first."
        case .connectionFailed:
            return "Check that the device is powered on and in range, then try again."
            
        // Authentication Errors
        case .authenticationFailed:
            return "Try reconnecting to the device."
        case .authenticationRequired:
            return "Please authenticate with the device."
        case .credentialsExpired:
            return "Request a new invitation from the device owner."
            
        // Permission Errors
        case .permissionDenied:
            return "Contact the device owner to request permission."
        case .insufficientPermissions:
            return "Ask the owner to grant you additional permissions."
        case .ownershipRequired:
            return "Only the device owner can perform this action."
            
        // Command Errors
        case .commandFailed:
            return "Wait a moment and try again."
        case .deviceBusy:
            return "Wait for the current operation to complete."
        case .operationTimeout:
            return "Check your connection and try again."
            
        // User Management Errors
        case .invitationInvalid:
            return "Double-check the invitation code."
        case .invitationExpired:
            return "Ask for a new invitation code."
        case .invitationAlreadyRedeemed:
            return "This code has been used. Request a new one."
        case .maxUsersReached:
            return "The owner needs to remove users before adding more."
            
        // BLE Errors
        case .bleUnavailable:
            return "Turn on Bluetooth in Settings."
        case .bleUnauthorized:
            return "Enable Bluetooth permission in Settings → Pergola Control."
            
        // Validation Errors
        case .invalidInput:
            return "Please check your input and try again."
            
        default:
            return "Try again or restart the app."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .authenticationFailed(let reason),
             .connectionFailed(let reason),
             .commandFailed(let reason),
             .cryptoError(let reason),
             .unknown(let reason):
            return reason
        default:
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if error is recoverable
    var isRecoverable: Bool {
        switch self {
        case .deviceNotFound, .deviceNotConnected, .connectionFailed,
             .deviceBusy, .operationTimeout, .bleUnavailable:
            return true
        case .credentialsExpired, .invitationExpired, .invitationInvalid:
            return false
        default:
            return true
        }
    }
    
    /// Check if error requires user action
    var requiresUserAction: Bool {
        switch self {
        case .bleUnauthorized, .authenticationRequired, .permissionDenied,
             .insufficientPermissions, .ownershipRequired:
            return true
        default:
            return false
        }
    }
}