import Foundation
import Supabase

/// Service responsible for duo/pair management operations
@MainActor
class PairService {
    // MARK: - Properties

    private let supabase = SupabaseConfig.shared.client
    private let authService: AuthService
    private let userService: UserService

    // MARK: - Initialization

    init(authService: AuthService, userService: UserService) {
        self.authService = authService
        self.userService = userService
    }

    // MARK: - Pair Invites

    /// Send an invite to form a duo
    /// - Parameters:
    ///   - fromUserId: User sending the invite
    ///   - toUserId: User receiving the invite
    ///   - message: Optional message (optional)
    /// - Returns: Created DuoInvite
    func sendInvite(
        fromUserId: UUID,
        toUserId: UUID,
        message: String? = nil
    ) async throws -> DuoInvite {
        // Validate users don't already have a pair
        let fromUser = try await userService.getUser(id: fromUserId)
        if fromUser.duoId != nil {
            throw PairError.alreadyInPair
        }

        // Create properly typed struct for the insert
        struct InviteInsert: Encodable {
            let fromUserId: String
            let toUserId: String
            let message: String?
            let status: String

            enum CodingKeys: String, CodingKey {
                case fromUserId = "from_user_id"
                case toUserId = "to_user_id"
                case message
                case status
            }
        }

        let inviteData = InviteInsert(
            fromUserId: fromUserId.uuidString,
            toUserId: toUserId.uuidString,
            message: message,
            status: "pending"
        )

        do {
            let response: PairInviteDTO = try await supabase.database
                .from("pair_invites")
                .insert(inviteData)
                .select()
                .single()
                .execute()
                .value

            print("✅ Invite sent from \(fromUserId) to \(toUserId)")

            // Get user summaries
            let fromUserSummary = UserSummary(from: fromUser)
            let toUser = try await userService.getUser(id: toUserId)
            let toUserSummary = UserSummary(from: toUser)

            return DuoInvite(
                id: response.id,
                fromUserId: fromUserId,
                fromUser: fromUserSummary,
                toUserId: toUserId,
                toUser: toUserSummary,
                status: InviteStatus(rawValue: response.status) ?? .pending,
                createdAt: response.createdAt
            )

        } catch {
            print("❌ Send invite error: \(error)")
            throw PairError.inviteFailed(error.localizedDescription)
        }
    }

    /// Get pending invites for a user
    /// - Parameter userId: User's ID
    /// - Returns: Array of pending DuoInvites
    func getPendingInvites(userId: UUID) async throws -> [DuoInvite] {
        do {
            let response: [PairInviteDTO] = try await supabase.database
                .from("pair_invites")
                .select()
                .eq("to_user_id", value: userId.uuidString)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value

            var invites: [DuoInvite] = []

            for dto in response {
                let fromUser = try await userService.getUser(id: dto.fromUserId)
                let toUser = try await userService.getUser(id: dto.toUserId)

                invites.append(DuoInvite(
                    id: dto.id,
                    fromUserId: dto.fromUserId,
                    fromUser: UserSummary(from: fromUser),
                    toUserId: dto.toUserId,
                    toUser: UserSummary(from: toUser),
                    status: InviteStatus(rawValue: dto.status) ?? .pending,
                    createdAt: dto.createdAt
                ))
            }

            return invites

        } catch {
            print("❌ Get pending invites error: \(error)")
            throw PairError.fetchFailed(error.localizedDescription)
        }
    }

    /// Get sent invites for a user
    /// - Parameter userId: User's ID
    /// - Returns: Array of sent DuoInvites
    func getSentInvites(userId: UUID) async throws -> [DuoInvite] {
        do {
            let response: [PairInviteDTO] = try await supabase.database
                .from("pair_invites")
                .select()
                .eq("from_user_id", value: userId.uuidString)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value

            var invites: [DuoInvite] = []

            for dto in response {
                let fromUser = try await userService.getUser(id: dto.fromUserId)
                let toUser = try await userService.getUser(id: dto.toUserId)

                invites.append(DuoInvite(
                    id: dto.id,
                    fromUserId: dto.fromUserId,
                    fromUser: UserSummary(from: fromUser),
                    toUserId: dto.toUserId,
                    toUser: UserSummary(from: toUser),
                    status: InviteStatus(rawValue: dto.status) ?? .pending,
                    createdAt: dto.createdAt
                ))
            }

            return invites

        } catch {
            print("❌ Get sent invites error: \(error)")
            throw PairError.fetchFailed(error.localizedDescription)
        }
    }

    /// Accept a duo invite
    /// - Parameter inviteId: Invite's ID
    /// - Returns: Created Duo
    func acceptInvite(inviteId: UUID) async throws -> Duo {
        do {
            // Get invite details
            let inviteDTO: PairInviteDTO = try await supabase.database
                .from("pair_invites")
                .select()
                .eq("id", value: inviteId.uuidString)
                .single()
                .execute()
                .value

            // Create pair
            let pairData: [String: AnyEncodable] = [
                "user1_id": AnyEncodable(inviteDTO.fromUserId.uuidString),
                "user2_id": AnyEncodable(inviteDTO.toUserId.uuidString),
                "status": AnyEncodable("active"),
                "duo_bio": AnyEncodable("")
            ]

            let pairResponse: PairDTO = try await supabase.database
                .from("pairs")
                .insert(pairData)
                .select()
                .single()
                .execute()
                .value

            // Update invite status
            try await supabase.database
                .from("pair_invites")
                .update(["status": AnyEncodable("accepted")])
                .eq("id", value: inviteId.uuidString)
                .execute()

            // Update both users' current_pair_id
            try await userService.updateCurrentPair(userId: inviteDTO.fromUserId, pairId: pairResponse.id)
            try await userService.updateCurrentPair(userId: inviteDTO.toUserId, pairId: pairResponse.id)

            print("✅ Invite accepted, pair created: \(pairResponse.id)")

            // Return complete Duo
            return try await getPair(id: pairResponse.id)

        } catch {
            print("❌ Accept invite error: \(error)")
            throw PairError.inviteAcceptFailed(error.localizedDescription)
        }
    }

    /// Decline a duo invite
    /// - Parameter inviteId: Invite's ID
    func declineInvite(inviteId: UUID) async throws {
        do {
            try await supabase.database
                .from("pair_invites")
                .update(["status": AnyEncodable("declined")])
                .eq("id", value: inviteId.uuidString)
                .execute()

            print("✅ Invite declined: \(inviteId)")

        } catch {
            print("❌ Decline invite error: \(error)")
            throw PairError.inviteDeclineFailed(error.localizedDescription)
        }
    }

    /// Cancel a sent invite
    /// - Parameter inviteId: Invite's ID
    func cancelInvite(inviteId: UUID) async throws {
        do {
            try await supabase.database
                .from("pair_invites")
                .delete()
                .eq("id", value: inviteId.uuidString)
                .execute()

            print("✅ Invite cancelled: \(inviteId)")

        } catch {
            print("❌ Cancel invite error: \(error)")
            throw PairError.inviteCancelFailed(error.localizedDescription)
        }
    }

    // MARK: - Pair Management

    /// Get a pair by ID
    /// - Parameter id: Pair's ID
    /// - Returns: Duo model
    func getPair(id: UUID) async throws -> Duo {
        do {
            let pairDTO: PairDTO = try await supabase.database
                .from("pairs")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            let user1 = try await userService.getUser(id: pairDTO.user1Id)
            let user2 = try await userService.getUser(id: pairDTO.user2Id)

            return Duo(
                id: pairDTO.id,
                user1Id: pairDTO.user1Id,
                user2Id: pairDTO.user2Id,
                user1: UserSummary(from: user1),
                user2: UserSummary(from: user2),
                duoBio: pairDTO.duoBio ?? "",
                createdAt: pairDTO.createdAt
            )

        } catch {
            print("❌ Get pair error: \(error)")
            throw PairError.fetchFailed(error.localizedDescription)
        }
    }

    /// Get the current user's pair
    /// - Returns: Duo model if user has a pair
    func getCurrentPair() async throws -> Duo? {
        let userId = try authService.getCurrentUserId()
        let user = try await userService.getUser(id: userId)

        guard let pairId = user.duoId else {
            return nil
        }

        return try await getPair(id: pairId)
    }

    /// Update pair's duo bio
    /// - Parameters:
    ///   - pairId: Pair's ID
    ///   - duoBio: New duo bio
    func updateDuoBio(pairId: UUID, duoBio: String) async throws {
        do {
            try await supabase.database
                .from("pairs")
                .update(["duo_bio": AnyEncodable(duoBio)])
                .eq("id", value: pairId.uuidString)
                .execute()

            print("✅ Duo bio updated")

        } catch {
            print("❌ Update duo bio error: \(error)")
            throw PairError.updateFailed(error.localizedDescription)
        }
    }

    /// Leave a pair (dissolve duo)
    /// - Parameter pairId: Pair's ID
    func leavePair(pairId: UUID) async throws {
        do {
            // Get pair details to update both users
            let pair = try await getPair(id: pairId)

            // Remove pair from both users
            try await userService.updateCurrentPair(userId: pair.user1Id, pairId: nil)
            try await userService.updateCurrentPair(userId: pair.user2Id, pairId: nil)

            // Update pair status to inactive (don't delete for history)
            try await supabase.database
                .from("pairs")
                .update(["status": AnyEncodable("inactive")])
                .eq("id", value: pairId.uuidString)
                .execute()

            print("✅ Pair dissolved: \(pairId)")

        } catch {
            print("❌ Leave pair error: \(error)")
            throw PairError.leaveFailed(error.localizedDescription)
        }
    }

    // MARK: - Discovery

    /// Get pairs for discovery (excluding current user's pair)
    /// - Parameters:
    ///   - currentPairId: Current user's pair ID
    ///   - limit: Maximum number of pairs to return
    /// - Returns: Array of Duo models
    func getDiscoveryPairs(currentPairId: UUID, limit: Int = 20) async throws -> [Duo] {
        do {
            // Get pairs that haven't been swiped on yet
            let response: [PairDTO] = try await supabase.database
                .from("pairs")
                .select()
                .eq("status", value: "active")
                .neq("id", value: currentPairId.uuidString)
                .limit(limit)
                .execute()
                .value

            var duos: [Duo] = []

            for pairDTO in response {
                // Check if already swiped
                let swipeCount: [SwipeCheckDTO] = try await supabase.database
                    .from("swipes")
                    .select("id")
                    .eq("swiper_pair_id", value: currentPairId.uuidString)
                    .eq("swiped_pair_id", value: pairDTO.id.uuidString)
                    .limit(1)
                    .execute()
                    .value

                // Skip if already swiped
                if !swipeCount.isEmpty {
                    continue
                }

                let user1 = try await userService.getUser(id: pairDTO.user1Id)
                let user2 = try await userService.getUser(id: pairDTO.user2Id)

                duos.append(Duo(
                    id: pairDTO.id,
                    user1Id: pairDTO.user1Id,
                    user2Id: pairDTO.user2Id,
                    user1: UserSummary(from: user1),
                    user2: UserSummary(from: user2),
                    duoBio: pairDTO.duoBio ?? "",
                    createdAt: pairDTO.createdAt
                ))
            }

            return duos

        } catch {
            print("❌ Get discovery pairs error: \(error)")
            throw PairError.fetchFailed(error.localizedDescription)
        }
    }
}

// MARK: - DTOs

struct PairDTO: Codable {
    let id: UUID
    let user1Id: UUID
    let user2Id: UUID
    let duoBio: String?
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case duoBio = "duo_bio"
        case status
        case createdAt = "created_at"
    }
}

struct PairInviteDTO: Codable {
    let id: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let status: String
    let message: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case status
        case message
        case createdAt = "created_at"
    }
}

struct SwipeCheckDTO: Codable {
    let id: UUID
}

// MARK: - Pair Errors

enum PairError: LocalizedError {
    case alreadyInPair
    case inviteFailed(String)
    case inviteAcceptFailed(String)
    case inviteDeclineFailed(String)
    case inviteCancelFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case leaveFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .alreadyInPair:
            return "You are already in a duo. Leave your current duo first."
        case .inviteFailed(let message):
            return "Failed to send invite: \(message)"
        case .inviteAcceptFailed(let message):
            return "Failed to accept invite: \(message)"
        case .inviteDeclineFailed(let message):
            return "Failed to decline invite: \(message)"
        case .inviteCancelFailed(let message):
            return "Failed to cancel invite: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch pair data: \(message)"
        case .updateFailed(let message):
            return "Failed to update pair: \(message)"
        case .leaveFailed(let message):
            return "Failed to leave pair: \(message)"
        case .notFound:
            return "Pair not found"
        }
    }
}
