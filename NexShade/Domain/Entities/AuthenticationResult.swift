struct AuthenticationResult {
    let success: Bool
    let user: User?
    let error: AuthenticationError?
    
    enum AuthenticationError: Error {
        case invalidSignature
        case userNotFound
        case userExpired
        case rateLimited
        case connectionLost
    }
}