import Foundation
import Supabase

/// Service responsible for user profile operations
@MainActor
class UserService {
    // MARK: - Properties

    private let supabase = SupabaseConfig.shared.client
    private let authService: AuthService

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - User Creation

    /// Create a complete user profile (called during onboarding)
    /// - Parameters:
    ///   - userId: The authenticated user's ID
    ///   - firstName: User's first name
    ///   - birthday: User's birthday
    ///   - gender: User's gender
    ///   - genderPreference: User's gender preference
    ///   - bio: User's bio
    ///   - university: User's university (optional)
    ///   - major: User's major (optional)
    /// - Returns: Created User model
    func createUserProfile(
        userId: UUID,
        firstName: String,
        birthday: Date,
        gender: Gender,
        genderPreference: GenderPreference,
        bio: String,
        university: String?,
        major: String?
    ) async throws -> User {
        // Create a properly typed struct for the update
        struct UserProfileUpdate: Encodable {
            let firstName: String
            let birthday: String
            let gender: String
            let genderPreference: String
            let bio: String
            let university: String?
            let major: String?

            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case birthday
                case gender
                case genderPreference = "gender_preference"
                case bio
                case university
                case major
            }
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]

        let birthdayString = isoFormatter.string(from: birthday)

        let update = UserProfileUpdate(
            firstName: firstName,
            birthday: birthdayString,
            gender: gender.rawValue,
            genderPreference: genderPreference.rawValue,
            bio: bio,
            university: university,
            major: major
        )

        print("🔍 Attempting to update user profile:")
        print("   User ID: \(userId)")
        print("   Name: \(firstName)")
        print("   Birthday: \(birthdayString)")
        print("   Gender: \(gender.rawValue)")
        print("   Bio: \(bio)")

        do {
            let response = try await supabase
                .from("users")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()

            print("✅ Update response status: \(response.response.statusCode)")
            print("✅ User profile created: \(firstName)")

            // Fetch and return complete user
            return try await getUser(id: userId)

        } catch {
            print("❌ Create profile error: \(error)")
            print("❌ Error details: \(String(describing: error))")
            throw UserError.createFailed(error.localizedDescription)
        }
    }

    // MARK: - User Retrieval

    /// Get a user by ID
    /// - Parameter id: User's ID
    /// - Returns: User model
    func getUser(id: UUID) async throws -> User {
        do {
            let userDTO: UserDTO = try await supabase
                .from("users")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            // Fetch related data
            let photos = try await getPhotos(userId: id)
            let interests = try await getInterests(userId: id)
            let prompts = try await getPrompts(userId: id)

            return User(
                id: userDTO.id,
                firstName: userDTO.firstName ?? "",
                birthday: userDTO.birthday ?? Date(),
                gender: Gender(rawValue: userDTO.gender ?? "") ?? .other,
                genderPreference: GenderPreference(rawValue: userDTO.genderPreference ?? "") ?? .everyone,
                photos: photos,
                bio: userDTO.bio ?? "",
                prompts: prompts,
                university: userDTO.university,
                major: userDTO.major,
                interests: interests,
                duoId: userDTO.currentPairId,
                createdAt: userDTO.createdAt
            )

        } catch {
            print("❌ Get user error: \(error)")
            throw UserError.fetchFailed(error.localizedDescription)
        }
    }

    /// Get the current authenticated user
    /// - Returns: Current User model
    func getCurrentUser() async throws -> User {
        let userId = try authService.getCurrentUserId()
        return try await getUser(id: userId)
    }

    // MARK: - User Updates

    /// Update user profile fields
    /// - Parameters:
    ///   - userId: User's ID
    ///   - firstName: New first name (optional)
    ///   - bio: New bio (optional)
    ///   - university: New university (optional)
    ///   - major: New major (optional)
    func updateUserProfile(
        userId: UUID,
        firstName: String? = nil,
        bio: String? = nil,
        university: String? = nil,
        major: String? = nil
    ) async throws {
        var updates: [String: AnyEncodable] = [:]

        if let name = firstName {
            updates["first_name"] = AnyEncodable(name)
        }
        if let userBio = bio {
            updates["bio"] = AnyEncodable(userBio)
        }
        if let uni = university {
            updates["university"] = AnyEncodable(uni)
        }
        if let maj = major {
            updates["major"] = AnyEncodable(maj)
        }

        guard !updates.isEmpty else { return }

        do {
            try await supabase
                .from("users")
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()

            print("✅ User profile updated")

        } catch {
            print("❌ Update profile error: \(error)")
            throw UserError.updateFailed(error.localizedDescription)
        }
    }

    /// Update user's current pair ID
    /// - Parameters:
    ///   - userId: User's ID
    ///   - pairId: New pair ID (nil to remove)
    func updateCurrentPair(userId: UUID, pairId: UUID?) async throws {
        let updates: [String: AnyEncodable] = [
            "current_pair_id": AnyEncodable(pairId?.uuidString ?? NSNull())
        ]

        do {
            try await supabase
                .from("users")
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()

            print("✅ User pair updated")

        } catch {
            print("❌ Update pair error: \(error)")
            throw UserError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Photos

    private func getPhotos(userId: UUID) async throws -> [Photo] {
        do {
            let response: [PhotoDTO] = try await supabase
                .from("user_photos")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("order_index")
                .execute()
                .value

            return response.map { dto in
                Photo(
                    id: dto.id,
                    url: dto.url,
                    order: dto.orderIndex,
                    isMain: dto.isMain
                )
            }
        } catch {
            // Return empty array if no photos found (not an error condition)
            print("ℹ️ No photos found for user: \(userId)")
            return []
        }
    }

    // MARK: - Interests

    /// Get user's interests
    private func getInterests(userId: UUID) async throws -> [Interest] {
        do {
            let response: [InterestDTO] = try await supabase
                .from("interests")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            return response.map { dto in
                Interest(
                    id: dto.id,
                    name: dto.name,
                    emoji: dto.emoji
                )
            }
        } catch {
            // Return empty array if no interests found
            print("ℹ️ No interests found for user: \(userId)")
            return []
        }
    }

    /// Add interests to user profile
    /// - Parameters:
    ///   - userId: User's ID
    ///   - interests: Array of interests to add
    func addInterests(userId: UUID, interests: [Interest]) async throws {
        let records = interests.map { interest in
            [
                "id": AnyEncodable(interest.id.uuidString),
                "user_id": AnyEncodable(userId.uuidString),
                "name": AnyEncodable(interest.name),
                "emoji": AnyEncodable(interest.emoji)
            ]
        }

        do {
            try await supabase
                .from("interests")
                .insert(records)
                .execute()

            print("✅ Interests added: \(interests.count)")

        } catch {
            print("❌ Add interests error: \(error)")
            throw UserError.updateFailed(error.localizedDescription)
        }
    }

    /// Remove all interests and add new ones
    /// - Parameters:
    ///   - userId: User's ID
    ///   - interests: New array of interests
    func updateInterests(userId: UUID, interests: [Interest]) async throws {
        // Delete existing interests
        try await supabase
            .from("interests")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Add new interests
        if !interests.isEmpty {
            try await addInterests(userId: userId, interests: interests)
        }
    }

    // MARK: - Profile Prompts

    /// Get user's profile prompts
    private func getPrompts(userId: UUID) async throws -> [ProfilePrompt] {
        do {
            let response: [ProfilePromptDTO] = try await supabase
                .from("profile_prompts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            return response.map { dto in
                ProfilePrompt(
                    id: dto.id,
                    prompt: PromptType(rawValue: dto.promptType) ?? .funFact,
                    answer: dto.answer
                )
            }
        } catch {
            // Return empty array if no prompts found
            print("ℹ️ No prompts found for user: \(userId)")
            return []
        }
    }

    /// Add profile prompts
    /// - Parameters:
    ///   - userId: User's ID
    ///   - prompts: Array of prompts to add
    func addPrompts(userId: UUID, prompts: [ProfilePrompt]) async throws {
        let records = prompts.map { prompt in
            [
                "id": AnyEncodable(prompt.id.uuidString),
                "user_id": AnyEncodable(userId.uuidString),
                "prompt_type": AnyEncodable(prompt.prompt.rawValue),
                "answer": AnyEncodable(prompt.answer)
            ]
        }

        do {
            try await supabase
                .from("profile_prompts")
                .insert(records)
                .execute()

            print("✅ Prompts added: \(prompts.count)")

        } catch {
            print("❌ Add prompts error: \(error)")
            throw UserError.updateFailed(error.localizedDescription)
        }
    }

    /// Update profile prompts (replace all)
    /// - Parameters:
    ///   - userId: User's ID
    ///   - prompts: New array of prompts
    func updatePrompts(userId: UUID, prompts: [ProfilePrompt]) async throws {
        // Delete existing prompts
        try await supabase
            .from("profile_prompts")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Add new prompts
        if !prompts.isEmpty {
            try await addPrompts(userId: userId, prompts: prompts)
        }
    }

    // MARK: - User Search

    /// Search users by email (for inviting to duo)
    /// - Parameter email: Email to search for
    /// - Returns: UserSummary if found
    func searchUserByEmail(email: String) async throws -> UserSummary? {
        do {
            let response: [UserDTO] = try await supabase
                .from("users")
                .select()
                .eq("email", value: email)
                .limit(1)
                .execute()
                .value

            guard let userDTO = response.first else {
                return nil
            }

            let photos = try await getPhotos(userId: userDTO.id)
            let interests = try await getInterests(userId: userDTO.id)
            let prompts = try await getPrompts(userId: userDTO.id)

            let age = Calendar.current.dateComponents(
                [.year],
                from: userDTO.birthday ?? Date(),
                to: Date()
            ).year ?? 0

            return UserSummary(
                id: userDTO.id,
                firstName: userDTO.firstName ?? "",
                age: age,
                photos: photos,
                bio: userDTO.bio ?? "",
                university: userDTO.university,
                interests: interests,
                prompts: prompts
            )

        } catch {
            print("❌ Search user error: \(error)")
            throw UserError.fetchFailed(error.localizedDescription)
        }
    }
}

// MARK: - DTOs (Data Transfer Objects)

struct UserDTO: Codable {
    let id: UUID
    let email: String
    let firstName: String?
    let birthday: Date?
    let gender: String?
    let genderPreference: String?
    let bio: String?
    let university: String?
    let major: String?
    let currentPairId: UUID?
    let isVerified: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case birthday
        case gender
        case genderPreference = "gender_preference"
        case bio
        case university
        case major
        case currentPairId = "current_pair_id"
        case isVerified = "is_verified"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)

        // Handle birthday - can be string or date
        if let birthdayString = try? container.decodeIfPresent(String.self, forKey: .birthday) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            birthday = formatter.date(from: birthdayString)
        } else {
            birthday = try container.decodeIfPresent(Date.self, forKey: .birthday)
        }

        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        genderPreference = try container.decodeIfPresent(String.self, forKey: .genderPreference)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        university = try container.decodeIfPresent(String.self, forKey: .university)
        major = try container.decodeIfPresent(String.self, forKey: .major)
        currentPairId = try container.decodeIfPresent(UUID.self, forKey: .currentPairId)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct InterestDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let emoji: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case emoji
    }
}

struct ProfilePromptDTO: Codable {
    let id: UUID
    let userId: UUID
    let promptType: String
    let answer: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case promptType = "prompt_type"
        case answer
    }
}

// MARK: - User Errors

enum UserError: LocalizedError {
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .createFailed(let message):
            return "Failed to create user profile: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch user data: \(message)"
        case .updateFailed(let message):
            return "Failed to update user profile: \(message)"
        case .notFound:
            return "User not found"
        case .invalidData:
            return "Invalid user data"
        }
    }
}
