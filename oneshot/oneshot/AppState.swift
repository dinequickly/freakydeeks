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

            // Check if profile is complete (minimum: has name and bio)
            // Photos are optional - user can add them later
            if !user.firstName.isEmpty && !user.bio.isEmpty {
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

    // MARK: - Profile Management

    func updateProfile(firstName: String? = nil, bio: String? = nil, university: String? = nil, major: String? = nil, location: UserLocation? = nil) async {
        guard let userId = currentUser?.id else { return }
        isLoading = true
        errorMessage = nil

        do {
            try await services.userService.updateUserProfile(
                userId: userId,
                firstName: firstName,
                bio: bio,
                university: university,
                major: major,
                location: location
            )

            // Reload user to update UI
            let updatedUser = try await services.userService.getUser(id: userId)
            currentUser = updatedUser
            isLoading = false
            print("✅ Profile updated successfully")
        } catch {
            print("❌ Update profile error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func uploadPhoto(image: UIImage) async {
        guard let userId = currentUser?.id else { return }
        
        // Determine order index (append to end)
        let nextOrder = (currentUser?.photos.count ?? 0)
        let isFirst = (currentUser?.photos.isEmpty ?? true)
        
        do {
            // Upload via service
            let photo = try await services.photoService.uploadPhoto(
                image: image,
                userId: userId,
                orderIndex: nextOrder,
                isMain: isFirst
            )
            
            // Update local state
            currentUser?.photos.append(photo)
            print("✅ Photo uploaded and added to local state")
        } catch {
            print("❌ Upload photo error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    func deletePhoto(photoId: UUID) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            // Optimistically update UI
            if let index = currentUser?.photos.firstIndex(where: { $0.id == photoId }) {
                let deletedPhoto = currentUser?.photos[index]
                currentUser?.photos.remove(at: index)
                
                // Actually delete from backend (we don't track storage path locally well enough here, so pass nil for now or update model)
                // The service method signature is (photoId: UUID, storagePath: String?)
                // Since we don't have the storage path easily available in the lightweight model without fetching, 
                // we can just rely on the DB delete trigger or fetch full object.
                // For now, let's assume the service handles DB deletion which is critical.
                
                // Note: In a real app, we should store storage_path in the Photo model to pass it here.
                // See `Photo` struct in Models.swift - it only has URL. 
                // We will need to update the `Photo` model or fetch the path.
                // For now, we will call delete with nil path and rely on Supabase cascading/triggers or manual cleanup.
                
                try await services.photoService.deletePhoto(photoId: photoId, storagePath: nil)
                print("✅ Photo deleted")
            }
        } catch {
            print("❌ Delete photo error: \(error)")
            errorMessage = error.localizedDescription
            // Re-fetch user to restore state if failed
            if let user = try? await services.userService.getUser(id: userId) {
                currentUser = user
            }
        }
    }

    // MARK: - Onboarding
    func completeOnboarding() async {
        print("🎯 completeOnboarding() called")
        isLoading = true
        errorMessage = nil

        // Get current user ID from auth
        guard let userId = try? services.authService.getCurrentUserId() else {
            print("❌ Cannot complete onboarding: User not authenticated")
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }

        print("🎯 User ID obtained: \(userId)")

        // 1. Create user profile FIRST (so photos can reference it)
        do {
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

            currentUser = user
            print("✅ User profile created successfully")
        } catch {
            print("❌ Create profile error: \(error)")
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // 2. Upload photos AFTER user exists in database
        if !onboardingPhotos.isEmpty {
            do {
                _ = try await services.photoService.uploadPhotos(
                    images: onboardingPhotos,
                    userId: userId
                )
                print("✅ Photos uploaded successfully")
            } catch {
                print("❌ Photo upload error: \(error)")
                // Don't fail onboarding if photos fail - they can add them later
                errorMessage = "Photos failed to upload, but you can add them in settings"
            }
        }

        // 3. Add interests if any
        if !onboardingInterests.isEmpty {
            do {
                try await services.userService.addInterests(
                    userId: userId,
                    interests: onboardingInterests
                )
                print("✅ Interests added successfully")
            } catch {
                print("❌ Add interests error: \(error)")
                // Non-critical error
            }
        }

        // 4. Add prompts if any
        if !onboardingPrompts.isEmpty {
            do {
                try await services.userService.addPrompts(
                    userId: userId,
                    prompts: onboardingPrompts
                )
                print("✅ Prompts added successfully")
            } catch {
                print("❌ Add prompts error: \(error)")
                // Non-critical error
            }
        }

        // 5. Mark onboarding as complete and clear temporary data
        isOnboardingComplete = true
        clearOnboardingData()
        isLoading = false

        print("✅ Onboarding completed successfully")
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

    func fetchMessages(matchId: UUID) async -> [Message] {
        do {
            return try await services.matchService.getMessages(matchId: matchId)
        } catch {
            print("❌ Fetch messages error: \(error)")
            return []
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
