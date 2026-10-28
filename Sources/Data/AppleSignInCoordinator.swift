#if FIREBASE_ENABLED
import Foundation
import AuthenticationServices
import CryptoKit
import Security
import FirebaseCore
import FirebaseAuth

@MainActor
final class AppleSignInCoordinator {
    private var nonce: String?

    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            nonce = nil
            return
        }
        let value = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        nonce = value
        request.requestedScopes = [.fullName, .email]
        request.nonce = SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func complete(_ result: Result<ASAuthorization, Error>) async throws -> AppUser {
        guard FirebaseApp.app() != nil else { throw WithError.missingConfiguration }
        defer { nonce = nil }
        let authorization = try result.get()
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw SignInError.invalidCredential
        }
        let firebaseCredential = OAuthProvider.appleCredential(withIDToken: token, rawNonce: nonce, fullName: credential.fullName)
        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
        return AppUser(id: authResult.user.uid, displayName: authResult.user.displayName ?? "Friend")
    }

    enum SignInError: LocalizedError {
        case invalidCredential
        var errorDescription: String? { "Apple sign-in couldn’t be completed. Please try again." }
    }
}
#endif
