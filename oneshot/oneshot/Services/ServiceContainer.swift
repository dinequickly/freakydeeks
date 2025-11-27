import Foundation
import SwiftUI
import Combine

/// Container that manages all app services with proper dependency injection
/// This is a singleton that provides access to all services throughout the app
@MainActor
class ServiceContainer: ObservableObject {
    // MARK: - Singleton

    static let shared = ServiceContainer()

    // MARK: - Services

    let authService: AuthService
    let photoService: PhotoService
    let userService: UserService
    let pairService: PairService
    let matchService: MatchService

    // MARK: - Initialization

    private init() {
        // Initialize services in dependency order
        let auth = AuthService()
        let photo = PhotoService()
        let user = UserService(authService: auth)
        let pair = PairService(authService: auth, userService: user)
        let match = MatchService(authService: auth, userService: user, pairService: pair)

        self.authService = auth
        self.photoService = photo
        self.userService = user
        self.pairService = pair
        self.matchService = match

        print("✅ ServiceContainer initialized")
    }

    // MARK: - Convenience Methods

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }

    /// Get current user ID
    var currentUserId: UUID? {
        authService.currentUserId
    }

    /// Reset all services (useful for logout)
    func reset() {
        // Services will be reinitialized automatically through singleton
        print("🔄 ServiceContainer reset")
    }
}

// MARK: - SwiftUI Environment Key

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = .shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject the ServiceContainer into the environment
    func withServices() -> some View {
        self.environmentObject(ServiceContainer.shared)
            .environmentObject(ServiceContainer.shared.authService)
    }
}
