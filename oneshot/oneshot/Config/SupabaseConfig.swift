import Foundation
import Supabase

/// Supabase client configuration and singleton
@MainActor
class SupabaseConfig {
    // MARK: - Singleton

    static let shared = SupabaseConfig()

    // MARK: - Properties

    /// The Supabase client instance
    let client: SupabaseClient

    // MARK: - Initialization

    private init() {
        // Validate environment configuration
        _ = AppEnvironment.validate()

        // Create Supabase client with configuration
        guard let url = URL(string: AppEnvironment.supabaseURL) else {
            fatalError("Invalid Supabase URL in Environment.swift")
        }

        // Create Supabase client with auth configuration
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppEnvironment.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true // Opt-in to new behavior
                )
            )
        )

        print("✅ Supabase client initialized")
    }

    // MARK: - Convenience Accessors

    /// Quick access to auth client
    var auth: GoTrueClient {
        client.auth
    }

    /// Quick access to database client
    var database: PostgrestClient {
        client.database
    }

    /// Quick access to storage client
    var storage: SupabaseStorageClient {
        client.storage
    }

    /// Quick access to realtime client (for future use)
    var realtime: RealtimeClient {
        client.realtime
    }

    // MARK: - Storage Helpers

    /// Get the user photos storage bucket
    func userPhotosBucket() -> StorageFileApi {
        storage.from("user-photos")
    }

    /// Build a public URL for a photo
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - photoId: The photo's ID
    ///   - fileExtension: File extension (e.g., "jpg")
    /// - Returns: Public URL for the photo
    func buildPhotoURL(userId: UUID, photoId: UUID, fileExtension: String = "jpg") throws -> URL {
        let path = "\(userId.uuidString)/\(photoId.uuidString).\(fileExtension)"
        return try userPhotosBucket().getPublicURL(path: path)
    }

    /// Build a public URL from storage path
    /// - Parameter path: The storage path (e.g., "user-id/photo-id.jpg")
    /// - Returns: Public URL for the file
    func buildPhotoURL(path: String) throws -> URL {
        return try userPhotosBucket().getPublicURL(path: path)
    }
}

// MARK: - Storage Bucket Extensions

extension SupabaseConfig {
    /// Upload a photo to user's folder in storage
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - photoId: The photo's ID
    ///   - imageData: The image data (JPEG or PNG)
    ///   - fileExtension: File extension (default: "jpg")
    /// - Returns: Storage path of uploaded file
    func uploadPhoto(
        userId: UUID,
        photoId: UUID,
        imageData: Data,
        fileExtension: String = "jpg"
    ) async throws -> String {
        let path = "\(userId.uuidString)/\(photoId.uuidString).\(fileExtension)"

        let contentType = fileExtension == "jpg" ? "image/jpeg" : "image/png"

        _ = try await userPhotosBucket().upload(
            path: path,
            file: imageData,
            options: FileOptions(
                cacheControl: "3600",
                contentType: contentType,
                upsert: false
            )
        )

        return path
    }

    /// Delete a photo from storage
    /// - Parameter path: The storage path to delete
    func deletePhoto(path: String) async throws {
        _ = try await userPhotosBucket().remove(paths: [path])
    }
}

// MARK: - Error Handling

enum SupabaseError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)
    case networkError(Error)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .notAuthenticated:
            return "User is not authenticated"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
