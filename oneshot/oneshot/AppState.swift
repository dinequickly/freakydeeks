import Foundation
import SwiftUI
import Combine

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var currentDuo: Duo?  // Store duo separately
    @Published var isOnboardingComplete: Bool = false
    @Published var onboardingStep: OnboardingStep = .basics

    @Published var discoveryDuos: [Duo] = []
    @Published var matches: [Match] = []
    @Published var pendingInvites: [DuoInvite] = []
    @Published var outgoingInvites: [DuoInvite] = []
    @Published var notifications: [AppNotification] = []

    @Published var discoveryPreferences: DiscoveryPreferences = .default
    @Published var notificationSettings: NotificationSettings = .default

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Onboarding Data (temporary)
    @Published var onboardingFirstName: String = ""
    @Published var onboardingBirthday: Date = Calendar.current.date(byAdding: .year, value: -21, to: Date()) ?? Date()
    @Published var onboardingGender: Gender = .male
    @Published var onboardingGenderPreference: GenderPreference = .everyone
    @Published var onboardingPhotos: [UIImage] = []
    @Published var onboardingBio: String = ""
    @Published var onboardingPrompts: [ProfilePrompt] = []
    @Published var onboardingUniversity: String = ""
    @Published var onboardingMajor: String = ""
    @Published var onboardingInterests: [Interest] = []

    // MARK: - Services
    private let services = ServiceContainer.shared

    // MARK: - Initialization
    init() {
        Task {
            await checkAuthAndLoadData()
        }
    }

    // MARK: - Data Loading

    /// Check authentication status and load user data if authenticated
    func checkAuthAndLoadData() async {
        if services.authService.isAuthenticated {
            await loadUserData()
        }
    }

    /// Load user data from database after authentication
    func loadUserData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user from database
            let user = try await services.userService.getCurrentUser()
            currentUser = user

            // Check if profile is complete (has name, photos, etc.)
            if !user.firstName.isEmpty && !user.photos.isEmpty {
                isOnboardingComplete = true
            }

            // Load duo if exists
            if let pairId = user.duoId {
                currentDuo = try await services.pairService.getPair(id: pairId)
                matches = try await services.matchService.getCurrentMatches()
            }

            // Load pending invites
            pendingInvites = try await services.pairService.getPendingInvites(userId: user.id)

            // Load discovery duos if user has a pair
            if let pairId = currentDuo?.id {
                await loadDiscoveryDuos(currentPairId: pairId)
            }

            isLoading = false

        } catch {
            print("❌ Load user data error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Load discovery duos for swiping
    func loadDiscoveryDuos(currentPairId: UUID) async {
        do {
            discoveryDuos = try await services.pairService.getDiscoveryPairs(currentPairId: currentPairId)
        } catch {
            print("❌ Load discovery duos error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Onboarding
    func completeOnboarding() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user ID from auth
            let userId = try services.authService.getCurrentUserId()

            // 1. Create user profile FIRST (so photos can reference it)
            let user = try await services.userService.createUserProfile(
                userId: userId,
                firstName: onboardingFirstName,
                birthday: onboardingBirthday,
                gender: onboardingGender,
                genderPreference: onboardingGenderPreference,
                bio: onboardingBio,
                university: onboardingUniversity.isEmpty ? nil : onboardingUniversity,
                major: onboardingMajor.isEmpty ? nil : onboardingMajor
            )

            // 2. Upload photos AFTER user exists in database
            _ = try await services.photoService.uploadPhotos(
                images: onboardingPhotos,
                userId: userId
            )

            // 3. Add interests if any
            if !onboardingInterests.isEmpty {
                try await services.userService.addInterests(
                    userId: userId,
                    interests: onboardingInterests
                )
            }

            // 4. Add prompts if any
            if !onboardingPrompts.isEmpty {
                try await services.userService.addPrompts(
                    userId: userId,
                    prompts: onboardingPrompts
                )
            }

            // 5. Update local state
            currentUser = user
            isOnboardingComplete = true

            // 6. Clear onboarding data
            clearOnboardingData()

            isLoading = false
            print("✅ Onboarding completed successfully")

        } catch {
            print("❌ Complete onboarding error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Clear onboarding temporary data
    private func clearOnboardingData() {
        onboardingFirstName = ""
        onboardingBirthday = Calendar.current.date(byAdding: .year, value: -21, to: Date()) ?? Date()
        onboardingGender = .male
        onboardingGenderPreference = .everyone
        onboardingPhotos = []
        onboardingBio = ""
        onboardingPrompts = []
        onboardingUniversity = ""
        onboardingMajor = ""
        onboardingInterests = []
    }

    // MARK: - Duo Management
    func sendDuoInvite(to userId: UUID) async {
        guard let currentUser = currentUser else { return }
        isLoading = true
        errorMessage = nil

        do {
            let invite = try await services.pairService.sendInvite(
                fromUserId: currentUser.id,
                toUserId: userId
            )
            outgoingInvites.append(invite)
            isLoading = false
            print("✅ Duo invite sent")

        } catch {
            print("❌ Send duo invite error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func acceptInvite(_ invite: DuoInvite) async {
        guard currentUser != nil else { return }
        isLoading = true
        errorMessage = nil

        do {
            let duo = try await services.pairService.acceptInvite(inviteId: invite.id)
            self.currentUser?.duoId = duo.id
            self.currentDuo = duo
            pendingInvites.removeAll { $0.id == invite.id }

            // Load discovery duos now that user has a pair
            await loadDiscoveryDuos(currentPairId: duo.id)

            isLoading = false
            print("✅ Invite accepted")

        } catch {
            print("❌ Accept invite error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func declineInvite(_ invite: DuoInvite) async {
        isLoading = true
        errorMessage = nil

        do {
            try await services.pairService.declineInvite(inviteId: invite.id)
            pendingInvites.removeAll { $0.id == invite.id }
            isLoading = false
            print("✅ Invite declined")

        } catch {
            print("❌ Decline invite error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func leaveDuo() async {
        guard let pairId = currentUser?.duoId else { return }
        isLoading = true
        errorMessage = nil

        do {
            try await services.pairService.leavePair(pairId: pairId)
            currentUser?.duoId = nil
            currentDuo = nil
            matches = []
            discoveryDuos = []
            isLoading = false
            print("✅ Left duo")

        } catch {
            print("❌ Leave duo error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Swiping
    func swipe(_ action: SwipeAction, on duo: Duo) async {
        guard let currentPairId = currentDuo?.id,
              let currentUserId = currentUser?.id else { return }

        // Remove from discovery immediately for better UX
        discoveryDuos.removeAll { $0.id == duo.id }

        do {
            // Record swipe and check for match
            let match = try await services.matchService.recordSwipe(
                swiperPairId: currentPairId,
                swipedPairId: duo.id,
                swiperUserId: currentUserId,
                direction: action
            )

            // If it's a match, add to matches list
            if let match = match {
                matches.insert(match, at: 0)
                print("✅ It's a match!")
            }

        } catch {
            print("❌ Swipe error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Messaging
    func sendMessage(to matchId: UUID, content: String, type: MessageType = .text) async {
        guard let currentUserId = currentUser?.id else { return }

        do {
            // Send message via MatchService
            try await services.matchService.sendMessage(
                matchId: matchId,
                senderId: currentUserId,
                content: content,
                type: type
            )

            // Update local match state
            if let matchIndex = matches.firstIndex(where: { $0.id == matchId }) {
                let messageSummary = MessageSummary(
                    id: UUID(),
                    senderId: currentUserId,
                    senderName: currentUser?.firstName ?? "",
                    content: content,
                    messageType: type,
                    createdAt: Date()
                )

                matches[matchIndex].lastMessageSummary = messageSummary
                matches[matchIndex].lastMessageAt = Date()
            }

            print("✅ Message sent")

        } catch {
            print("❌ Send message error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

}

// MARK: - Onboarding Step
enum OnboardingStep: Int, CaseIterable {
    case basics = 0
    case photos = 1
    case profile = 2
    case duo = 3

    var title: String {
        switch self {
        case .basics: return "The Basics"
        case .photos: return "Add Photos"
        case .profile: return "Your Profile"
        case .duo: return "Find Your Duo"
        }
    }

    var subtitle: String {
        switch self {
        case .basics: return "Let's start with some basics"
        case .photos: return "Show off your best self"
        case .profile: return "Tell us about yourself"
        case .duo: return "Team up with a friend"
        }
    }
}
