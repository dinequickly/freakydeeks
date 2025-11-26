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

    // MARK: - Initialization
    init() {
        loadMockData()
    }

    // MARK: - Onboarding
    func completeOnboarding() {
        let photos = onboardingPhotos.enumerated().map { index, _ in
            Photo(url: "photo_\(index)", order: index, isMain: index == 0)
        }

        let user = User(
            id: UUID(),
            firstName: onboardingFirstName,
            birthday: onboardingBirthday,
            gender: onboardingGender,
            genderPreference: onboardingGenderPreference,
            photos: photos,
            bio: onboardingBio,
            prompts: onboardingPrompts,
            university: onboardingUniversity.isEmpty ? nil : onboardingUniversity,
            major: onboardingMajor.isEmpty ? nil : onboardingMajor,
            interests: onboardingInterests,
            duoId: nil,
            createdAt: Date()
        )

        currentUser = user
        isOnboardingComplete = true
    }

    // MARK: - Duo Management
    func sendDuoInvite(to userId: UUID) {
        guard let currentUser = currentUser else { return }

        let invite = DuoInvite(
            id: UUID(),
            fromUserId: currentUser.id,
            fromUser: UserSummary(from: currentUser),
            toUserId: userId,
            toUser: nil,
            status: .pending,
            createdAt: Date()
        )

        outgoingInvites.append(invite)
    }

    func acceptInvite(_ invite: DuoInvite) {
        guard let currentUser = currentUser else { return }

        let duo = Duo(
            id: UUID(),
            user1Id: invite.fromUserId,
            user2Id: currentUser.id,
            user1: invite.fromUser,
            user2: UserSummary(from: currentUser),
            duoBio: "",
            createdAt: Date()
        )

        self.currentUser?.duoId = duo.id
        self.currentDuo = duo
        pendingInvites.removeAll { $0.id == invite.id }
    }

    func declineInvite(_ invite: DuoInvite) {
        pendingInvites.removeAll { $0.id == invite.id }
    }

    func leaveDuo() {
        currentUser?.duoId = nil
        currentDuo = nil
    }

    // MARK: - Swiping
    func swipe(_ action: SwipeAction, on duo: Duo) {
        discoveryDuos.removeAll { $0.id == duo.id }

        if action == .like || action == .superLike {
            // Check for match (in real app, this would be server-side)
            let isMatch = Bool.random() // Simulated

            if isMatch {
                let match = Match(
                    id: UUID(),
                    duo1Id: currentDuo?.id ?? UUID(),
                    duo2Id: duo.id,
                    duo1: currentDuo,
                    duo2: duo,
                    createdAt: Date(),
                    lastMessageAt: nil,
                    lastMessageSummary: nil,
                    unreadCount: 0
                )
                matches.insert(match, at: 0)
            }
        }
    }

    // MARK: - Messaging
    func sendMessage(to matchId: UUID, content: String, type: MessageType = .text) {
        guard let currentUser = currentUser,
              let matchIndex = matches.firstIndex(where: { $0.id == matchId }) else { return }

        let messageSummary = MessageSummary(
            id: UUID(),
            senderId: currentUser.id,
            senderName: currentUser.firstName,
            content: content,
            messageType: type,
            createdAt: Date()
        )

        matches[matchIndex].lastMessageSummary = messageSummary
        matches[matchIndex].lastMessageAt = Date()
    }

    // MARK: - Mock Data
    private func loadMockData() {
        // Create mock users for discovery
        let mockUsers: [(String, Gender, [String])] = [
            ("Alex", .male, ["Travel", "Music", "Fitness"]),
            ("Jordan", .female, ["Foodie", "Movies", "Art"]),
            ("Sam", .male, ["Gaming", "Tech", "Coffee"]),
            ("Taylor", .female, ["Yoga", "Nature", "Reading"]),
            ("Casey", .nonBinary, ["Photography", "Hiking", "Dogs"]),
            ("Riley", .female, ["Dancing", "Nightlife", "Fashion"]),
            ("Morgan", .male, ["Sports", "Beach", "Brunch"]),
            ("Quinn", .female, ["Cooking", "Wine", "Travel"])
        ]

        var mockDuos: [Duo] = []

        for i in stride(from: 0, to: mockUsers.count, by: 2) {
            guard i + 1 < mockUsers.count else { break }

            let user1Data = mockUsers[i]
            let user2Data = mockUsers[i + 1]

            let user1 = createMockUserSummary(name: user1Data.0, gender: user1Data.1, interestNames: user1Data.2)
            let user2 = createMockUserSummary(name: user2Data.0, gender: user2Data.1, interestNames: user2Data.2)

            let duo = Duo(
                id: UUID(),
                user1Id: user1.id,
                user2Id: user2.id,
                user1: user1,
                user2: user2,
                duoBio: "Just two friends looking for our perfect match! We love adventures and good vibes.",
                createdAt: Date()
            )

            mockDuos.append(duo)
        }

        discoveryDuos = mockDuos

        // Create mock pending invites
        let inviteUser = createMockUserSummary(name: "Jamie", gender: .female, interestNames: ["Music", "Travel"])
        pendingInvites = [
            DuoInvite(
                id: UUID(),
                fromUserId: inviteUser.id,
                fromUser: inviteUser,
                toUserId: UUID(),
                toUser: nil,
                status: .pending,
                createdAt: Date().addingTimeInterval(-3600)
            )
        ]
    }

    private func createMockUserSummary(name: String, gender: Gender, interestNames: [String]) -> UserSummary {
        let interests = interestNames.compactMap { name in
            Interest.allInterests.first { $0.name == name }
        }

        let age = Int.random(in: 21...28)

        return UserSummary(
            id: UUID(),
            firstName: name,
            age: age,
            photos: [
                Photo(url: "https://picsum.photos/400/600?random=\(Int.random(in: 1...1000))", order: 0, isMain: true),
                Photo(url: "https://picsum.photos/400/600?random=\(Int.random(in: 1...1000))", order: 1),
                Photo(url: "https://picsum.photos/400/600?random=\(Int.random(in: 1...1000))", order: 2)
            ],
            bio: "Living life one adventure at a time",
            university: ["NYU", "Columbia", "UCLA", "Stanford"].randomElement(),
            interests: interests,
            prompts: [
                ProfilePrompt(prompt: .idealDoubleDate, answer: "Trying a new restaurant and then hitting up a fun bar!")
            ]
        )
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
