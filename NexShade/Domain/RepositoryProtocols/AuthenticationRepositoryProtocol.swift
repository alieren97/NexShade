protocol AuthenticationRepositoryProtocol {
    func readChallenge(deviceId: UUID) async throws -> Data
    func authenticate(deviceId: UUID, publicKey: Data, signature: Data) async throws -> AuthenticationResult
    
    func storeAuthenticatedUser(_ user: User, for deviceId: UUID) async throws
    func getAuthenticatedUser(for deviceId: UUID) async throws -> User?
    
    func hasPermission(_ permission: Permissions) -> Bool
    
    func generateKeyPair() throws -> KeyPair
    func getPublicKey() throws -> Data
}

struct KeyPair {
    let publicKey: Data
    let privateKey: Data
}