import Foundation
import Combine
import Supabase
import AuthenticationServices
import GoogleSignIn

/// Service responsible for authentication operations
@MainActor
class AuthService: ObservableObject {
    // MARK: - Properties

    @Published var currentSession: Session?
    @Published var isAuthenticated = false
    @Published var currentUserId: UUID?

    private let supabase = SupabaseConfig.shared.client

    // MARK: - Initialization

    init() {
        Task {
            await checkSession()
        }
    }

    // MARK: - Session Management

    /// Check if user has an active session
    func checkSession() async {
        do {
            let session = try await supabase.auth.session

            // Check if session is expired (recommended by Supabase Auth SDK)
            if session.isExpired {
                print("⚠️ Session expired, clearing authentication state")
                self.currentSession = nil
                self.isAuthenticated = false
                self.currentUserId = nil
                return
            }

            self.currentSession = session
            self.isAuthenticated = true
            self.currentUserId = UUID(uuidString: session.user.id.uuidString)
            print("✅ Active session found for user: \(session.user.email ?? "unknown")")
        } catch {
            self.currentSession = nil
            self.isAuthenticated = false
            self.currentUserId = nil
            print("ℹ️ No active session")
        }
    }

    /// Get the current authenticated user's ID
    func getCurrentUserId() throws -> UUID {
        guard let userId = currentUserId else {
            throw AuthError.notAuthenticated
        }
        return userId
    }

    // MARK: - Email/Password Authentication

    /// Sign up with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The created session
    func signUp(email: String, password: String) async throws -> Session {
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            guard let session = response.session else {
                // Email confirmation might be required
                throw AuthError.emailConfirmationRequired
            }

            self.currentSession = session
            self.isAuthenticated = true
            self.currentUserId = UUID(uuidString: session.user.id.uuidString)

            print("✅ User signed up: \(email)")
            return session

        } catch let error as AuthError {
            throw error
        } catch {
            print("❌ Sign up error: \(error)")
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The user's session
    func signIn(email: String, password: String) async throws -> Session {
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            self.currentSession = session
            self.isAuthenticated = true
            self.currentUserId = UUID(uuidString: session.user.id.uuidString)

            print("✅ User signed in: \(email)")
            return session

        } catch {
            print("❌ Sign in error: \(error)")
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    // MARK: - Google Sign-In

    /// Sign in with Google OAuth
    /// - Parameter presentingViewController: The view controller to present Google Sign-In
    /// - Returns: The user's session
    func signInWithGoogle(presentingViewController: UIViewController) async throws -> Session {
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: AppEnvironment.googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        // Get Google ID token
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.googleSignInFailed("Failed to get ID token")
        }

        // Sign in to Supabase with Google token
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )

            self.currentSession = session
            self.isAuthenticated = true
            self.currentUserId = UUID(uuidString: session.user.id.uuidString)

            print("✅ User signed in with Google")
            return session

        } catch {
            print("❌ Google sign in error: \(error)")
            throw AuthError.googleSignInFailed(error.localizedDescription)
        }
    }

    // MARK: - Password Reset

    /// Send password reset email
    /// - Parameter email: User's email address
    func sendPasswordReset(email: String) async throws {
        do {
            try await supabase.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: "\(AppEnvironment.appScheme)://reset-password")
            )
            print("✅ Password reset email sent to: \(email)")
        } catch {
            print("❌ Password reset error: \(error)")
            throw AuthError.passwordResetFailed(error.localizedDescription)
        }
    }

    /// Update user's password
    /// - Parameter newPassword: The new password
    func updatePassword(newPassword: String) async throws {
        do {
            _ = try await supabase.auth.update(
                user: UserAttributes(
                    password: newPassword
                )
            )
            print("✅ Password updated successfully")
        } catch {
            print("❌ Password update error: \(error)")
            throw AuthError.passwordUpdateFailed(error.localizedDescription)
        }
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()

            self.currentSession = nil
            self.isAuthenticated = false
            self.currentUserId = nil

            print("✅ User signed out")
        } catch {
            print("❌ Sign out error: \(error)")
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }

    // MARK: - Account Management

    /// Delete the current user's account
    func deleteAccount() async throws {
        guard isAuthenticated else {
            throw AuthError.notAuthenticated
        }

        do {
            // Delete user data first (cascade will handle related records)
            if let userId = currentUserId {
                try await supabase
                    .from("users")
                    .delete()
                    .eq("id", value: userId.uuidString)
                    .execute()
            }

            // Sign out
            try await signOut()

            print("✅ Account deleted successfully")
        } catch {
            print("❌ Account deletion error: \(error)")
            throw AuthError.accountDeletionFailed(error.localizedDescription)
        }
    }

    // MARK: - Email Verification

    /// Resend verification email
    /// - Parameter email: User's email address
    func resendVerificationEmail(email: String) async throws {
        do {
            try await supabase.auth.resend(
                email: email,
                type: .signup
            )
            print("✅ Verification email resent to: \(email)")
        } catch {
            print("❌ Resend verification error: \(error)")
            throw AuthError.emailVerificationFailed(error.localizedDescription)
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case emailConfirmationRequired
    case signUpFailed(String)
    case signInFailed(String)
    case googleSignInFailed(String)
    case passwordResetFailed(String)
    case passwordUpdateFailed(String)
    case signOutFailed(String)
    case accountDeletionFailed(String)
    case emailVerificationFailed(String)
    case invalidCredentials
    case weakPassword
    case emailAlreadyInUse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .emailConfirmationRequired:
            return "Please check your email to confirm your account"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .googleSignInFailed(let message):
            return "Google sign in failed: \(message)"
        case .passwordResetFailed(let message):
            return "Password reset failed: \(message)"
        case .passwordUpdateFailed(let message):
            return "Password update failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .accountDeletionFailed(let message):
            return "Account deletion failed: \(message)"
        case .emailVerificationFailed(let message):
            return "Email verification failed: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emailConfirmationRequired:
            return "Check your inbox and click the confirmation link"
        case .weakPassword:
            return "Use a stronger password with at least 8 characters"
        case .emailAlreadyInUse:
            return "Try signing in instead, or use a different email"
        case .notAuthenticated:
            return "Please sign in to continue"
        default:
            return "Please try again or contact support if the problem persists"
        }
    }
}

// MARK: - Helper Extensions

extension AuthService {
    /// Validate email format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Validate password strength
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
}
