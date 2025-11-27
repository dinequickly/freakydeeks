import Foundation
import SwiftUI

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var firstName: String
    var birthday: Date
    var gender: Gender
    var genderPreference: GenderPreference
    var photos: [Photo]
    var bio: String
    var prompts: [ProfilePrompt]
    var university: String?
    var major: String?
    var interests: [Interest]
    var duoId: UUID?  // Reference by ID only to avoid circular reference
    var location: UserLocation
    var createdAt: Date

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User Summary (lightweight, for embedding in other models)
struct UserSummary: Identifiable, Codable, Equatable {
    let id: UUID
    var firstName: String
    var age: Int
    var photos: [Photo]
    var bio: String
    var university: String?
    var interests: [Interest]
    var prompts: [ProfilePrompt]

    init(from user: User) {
        self.id = user.id
        self.firstName = user.firstName
        self.age = user.age
        self.photos = user.photos
        self.bio = user.bio
        self.university = user.university
        self.interests = user.interests
        self.prompts = user.prompts
    }

    init(id: UUID, firstName: String, age: Int, photos: [Photo], bio: String, university: String?, interests: [Interest], prompts: [ProfilePrompt] = []) {
        self.id = id
        self.firstName = firstName
        self.age = age
        self.photos = photos
        self.bio = bio
        self.university = university
        self.interests = interests
        self.prompts = prompts
    }
}

// MARK: - Gender
enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-binary"
    case other = "Other"
}

// MARK: - Gender Preference
enum GenderPreference: String, Codable, CaseIterable {
    case men = "Men"
    case women = "Women"
    case everyone = "Everyone"
}

// MARK: - User Location
enum UserLocation: String, Codable, CaseIterable {
    case london = "london"
    case chicago = "chicago"

    var displayName: String {
        switch self {
        case .london: return "London"
        case .chicago: return "Chicago"
        }
    }

    var searchLocation: String {
        switch self {
        case .london: return "Spitalfields, London"
        case .chicago: return "University of Chicago, Chicago"
        }
    }
}

// MARK: - Photo
struct Photo: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var url: String
    var order: Int
    var isMain: Bool

    init(id: UUID = UUID(), url: String, order: Int, isMain: Bool = false) {
        self.id = id
        self.url = url
        self.order = order
        self.isMain = isMain
    }
}

// MARK: - Profile Prompt
struct ProfilePrompt: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var prompt: PromptType
    var answer: String

    init(id: UUID = UUID(), prompt: PromptType, answer: String) {
        self.id = id
        self.prompt = prompt
        self.answer = answer
    }
}

enum PromptType: String, Codable, CaseIterable {
    case idealDoubleDate = "My ideal double date is..."
    case funFact = "A fun fact about me..."
    case lookingFor = "Together we're looking for..."
    case perfectWeekend = "Our perfect weekend..."
    case dealBreaker = "A deal breaker for us..."
    case weClickedBecause = "We clicked because..."
    case togetherWere = "Together we're..."
    case bestMemory = "Our best memory together..."
}

// MARK: - Interest
struct Interest: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var emoji: String

    init(id: UUID = UUID(), name: String, emoji: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }

    static let allInterests: [Interest] = [
        Interest(name: "Travel", emoji: "✈️"),
        Interest(name: "Music", emoji: "🎵"),
        Interest(name: "Fitness", emoji: "💪"),
        Interest(name: "Foodie", emoji: "🍕"),
        Interest(name: "Movies", emoji: "🎬"),
        Interest(name: "Gaming", emoji: "🎮"),
        Interest(name: "Reading", emoji: "📚"),
        Interest(name: "Art", emoji: "🎨"),
        Interest(name: "Sports", emoji: "⚽"),
        Interest(name: "Photography", emoji: "📷"),
        Interest(name: "Cooking", emoji: "👨‍🍳"),
        Interest(name: "Dancing", emoji: "💃"),
        Interest(name: "Hiking", emoji: "🥾"),
        Interest(name: "Yoga", emoji: "🧘"),
        Interest(name: "Coffee", emoji: "☕"),
        Interest(name: "Wine", emoji: "🍷"),
        Interest(name: "Dogs", emoji: "🐕"),
        Interest(name: "Cats", emoji: "🐱"),
        Interest(name: "Fashion", emoji: "👗"),
        Interest(name: "Tech", emoji: "💻"),
        Interest(name: "Nature", emoji: "🌿"),
        Interest(name: "Beach", emoji: "🏖️"),
        Interest(name: "Nightlife", emoji: "🌃"),
        Interest(name: "Brunch", emoji: "🥞")
    ]
}

// MARK: - Duo
struct Duo: Identifiable, Codable, Equatable {
    let id: UUID
    var user1Id: UUID
    var user2Id: UUID
    var user1: UserSummary?  // Use lightweight summary to avoid recursion
    var user2: UserSummary?
    var duoBio: String
    var createdAt: Date

    var combinedInterests: [Interest] {
        let interests1 = user1?.interests ?? []
        let interests2 = user2?.interests ?? []
        return Array(Set(interests1 + interests2))
    }

    static func == (lhs: Duo, rhs: Duo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Duo Invite
struct DuoInvite: Identifiable, Codable {
    let id: UUID
    var fromUserId: UUID
    var fromUser: UserSummary?  // Use lightweight summary
    var toUserId: UUID
    var toUser: UserSummary?
    var status: InviteStatus
    var createdAt: Date
}

enum InviteStatus: String, Codable {
    case pending
    case accepted
    case declined
}

// MARK: - Message Summary (for embedding in Match)
struct MessageSummary: Identifiable, Codable {
    let id: UUID
    var senderId: UUID
    var senderName: String
    var content: String
    var messageType: MessageType
    var createdAt: Date
}

// MARK: - Match
struct Match: Identifiable, Codable {
    let id: UUID
    var duo1Id: UUID
    var duo2Id: UUID
    var duo1: Duo?
    var duo2: Duo?
    var createdAt: Date
    var lastMessageAt: Date?
    var lastMessageSummary: MessageSummary?  // Use summary instead of full Message
    var unreadCount: Int

    var otherDuo: Duo? {
        duo2
    }
}

// MARK: - Message
struct Message: Identifiable, Codable {
    let id: UUID
    var matchId: UUID
    var senderId: UUID
    var senderSummary: UserSummary?  // Use lightweight summary
    var content: String
    var messageType: MessageType
    var createdAt: Date
    var isRead: Bool
}

enum MessageType: String, Codable {
    case text
    case dateSuggestion
    case icebreaker
    case image
}

// MARK: - Swipe Action
enum SwipeAction {
    case like
    case pass
    case superLike
}

// MARK: - Discovery Preferences
struct DiscoveryPreferences: Codable {
    var minAge: Int
    var maxAge: Int
    var maxDistance: Int // in miles
    var showMe: GenderPreference

    static let `default` = DiscoveryPreferences(
        minAge: 18,
        maxAge: 35,
        maxDistance: 25,
        showMe: .everyone
    )
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var newMatches: Bool
    var messages: Bool
    var duoInvites: Bool
    var likes: Bool
    var appUpdates: Bool

    static let `default` = NotificationSettings(
        newMatches: true,
        messages: true,
        duoInvites: true,
        likes: true,
        appUpdates: false
    )
}

// MARK: - App Notification
struct AppNotification: Identifiable {
    let id: UUID
    var type: NotificationType
    var title: String
    var message: String
    var relatedId: UUID?
    var isRead: Bool
    var createdAt: Date
}

enum NotificationType {
    case newMatch
    case newMessage
    case duoInvite
    case duoInviteAccepted
    case someoneLikedYou
    case system
}
