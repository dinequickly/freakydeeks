import Foundation
import UIKit
import Supabase

/// Service responsible for photo upload, download, and management
@MainActor
class PhotoService {
    // MARK: - Properties

    private let supabase = SupabaseConfig.shared
    private let maxImageSize: CGFloat = 2048 // Max dimension in pixels
    private let compressionQuality: CGFloat = 0.8 // JPEG compression quality

    // MARK: - Photo Upload

    /// Upload a photo to Supabase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The user's ID (for folder organization)
    ///   - photoId: Unique ID for the photo
    ///   - orderIndex: Order/position of the photo
    ///   - isMain: Whether this is the main profile photo
    /// - Returns: Photo model with database ID and URLs
    func uploadPhoto(
        image: UIImage,
        userId: UUID,
        photoId: UUID = UUID(),
        orderIndex: Int,
        isMain: Bool = false
    ) async throws -> Photo {
        // 1. Validate image size
        let sizeInMB = estimateImageSize(image)
        guard sizeInMB <= Double(AppEnvironment.maxPhotoSizeMB) else {
            throw PhotoError.fileTooLarge(sizeInMB)
        }

        // 2. Resize and compress image
        guard let processedImage = resizeImage(image, maxDimension: maxImageSize) else {
            throw PhotoError.processingFailed("Failed to resize image")
        }

        guard let imageData = processedImage.jpegData(compressionQuality: compressionQuality) else {
            throw PhotoError.processingFailed("Failed to compress image")
        }

        print("📸 Uploading photo: \(imageData.count / 1024)KB")

        do {
            // 3. Upload to Supabase Storage
            let storagePath = try await supabase.uploadPhoto(
                userId: userId,
                photoId: photoId,
                imageData: imageData,
                fileExtension: "jpg"
            )

            // 4. Get public URL
            let publicURL = try supabase.buildPhotoURL(path: storagePath)

            // 5. Create database record
            let photoRecord: [String: AnyEncodable] = [
                "id": AnyEncodable(photoId.uuidString),
                "user_id": AnyEncodable(userId.uuidString),
                "url": AnyEncodable(publicURL.absoluteString),
                "storage_path": AnyEncodable(storagePath),
                "order_index": AnyEncodable(orderIndex),
                "is_main": AnyEncodable(isMain)
            ]

            try await supabase.client
                .from("user_photos")
                .insert(photoRecord)
                .execute()

            print("✅ Photo uploaded successfully: \(photoId)")

            // 6. Return Photo model
            return Photo(
                id: photoId,
                url: publicURL.absoluteString,
                order: orderIndex,
                isMain: isMain
            )

        } catch {
            print("❌ Photo upload error: \(error)")
            throw PhotoError.uploadFailed(error.localizedDescription)
        }
    }

    /// Upload multiple photos
    /// - Parameters:
    ///   - images: Array of UIImages to upload
    ///   - userId: The user's ID
    ///   - startingOrder: Starting order index (default: 0)
    /// - Returns: Array of uploaded Photo models
    func uploadPhotos(
        images: [UIImage],
        userId: UUID,
        startingOrder: Int = 0
    ) async throws -> [Photo] {
        var photos: [Photo] = []

        for (index, image) in images.enumerated() {
            let photo = try await uploadPhoto(
                image: image,
                userId: userId,
                orderIndex: startingOrder + index,
                isMain: index == 0 && startingOrder == 0
            )
            photos.append(photo)
        }

        return photos
    }

    // MARK: - Photo Deletion

    /// Delete a photo from both storage and database
    /// - Parameters:
    ///   - photoId: The photo's database ID
    ///   - storagePath: The photo's storage path
    func deletePhoto(photoId: UUID, storagePath: String?) async throws {
        do {
            // 1. Delete from database (trigger will handle storage cleanup)
            try await supabase.client
                .from("user_photos")
                .delete()
                .eq("id", value: photoId.uuidString)
                .execute()

            // 2. Optionally delete from storage manually if needed
            if let path = storagePath {
                try? await supabase.deletePhoto(path: path)
            }

            print("✅ Photo deleted: \(photoId)")

        } catch {
            print("❌ Photo deletion error: \(error)")
            throw PhotoError.deleteFailed(error.localizedDescription)
        }
    }

    /// Delete all photos for a user
    /// - Parameter userId: The user's ID
    func deleteAllPhotos(userId: UUID) async throws {
        do {
            try await supabase.client
                .from("user_photos")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            print("✅ All photos deleted for user: \(userId)")

        } catch {
            print("❌ Delete all photos error: \(error)")
            throw PhotoError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Photo Retrieval

    /// Get all photos for a user
    /// - Parameter userId: The user's ID
    /// - Returns: Array of Photo models
    func getPhotos(userId: UUID) async throws -> [Photo] {
        do {
            let response: [PhotoDTO] = try await supabase.client
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
            print("❌ Get photos error: \(error)")
            throw PhotoError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Photo Update

    /// Update photo metadata (order, isMain)
    /// - Parameters:
    ///   - photoId: The photo's ID
    ///   - orderIndex: New order index (optional)
    ///   - isMain: New isMain status (optional)
    func updatePhoto(
        photoId: UUID,
        orderIndex: Int? = nil,
        isMain: Bool? = nil
    ) async throws {
        var updates: [String: AnyEncodable] = [:]

        if let order = orderIndex {
            updates["order_index"] = AnyEncodable(order)
        }

        if let main = isMain {
            updates["is_main"] = AnyEncodable(main)
        }

        guard !updates.isEmpty else { return }

        do {
            try await supabase.client
                .from("user_photos")
                .update(updates)
                .eq("id", value: photoId.uuidString)
                .execute()

            print("✅ Photo updated: \(photoId)")

        } catch {
            print("❌ Photo update error: \(error)")
            throw PhotoError.updateFailed(error.localizedDescription)
        }
    }

    /// Reorder photos for a user
    /// - Parameters:
    ///   - photoIds: Array of photo IDs in desired order
    ///   - userId: The user's ID
    func reorderPhotos(photoIds: [UUID], userId: UUID) async throws {
        for (index, photoId) in photoIds.enumerated() {
            try await updatePhoto(
                photoId: photoId,
                orderIndex: index,
                isMain: index == 0
            )
        }
        print("✅ Photos reordered for user: \(userId)")
    }

    // MARK: - Image Processing

    /// Resize image to fit within max dimension while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Only resize if image is larger than max dimension
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    /// Estimate image size in MB
    private func estimateImageSize(_ image: UIImage) -> Double {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return 0
        }
        return Double(data.count) / 1_048_576 // Convert bytes to MB
    }
}

// MARK: - Photo DTO (Data Transfer Object)

struct PhotoDTO: Codable {
    let id: UUID
    let userId: UUID
    let url: String
    let storagePath: String?
    let orderIndex: Int
    let isMain: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case url
        case storagePath = "storage_path"
        case orderIndex = "order_index"
        case isMain = "is_main"
        case createdAt = "created_at"
    }
}

// MARK: - Photo Errors

enum PhotoError: LocalizedError {
    case fileTooLarge(Double)
    case invalidFormat
    case processingFailed(String)
    case uploadFailed(String)
    case deleteFailed(String)
    case fetchFailed(String)
    case updateFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileTooLarge(let sizeMB):
            return "Photo is too large (\(String(format: "%.1f", sizeMB))MB). Maximum size is \(AppEnvironment.maxPhotoSizeMB)MB"
        case .invalidFormat:
            return "Invalid photo format. Please use JPEG or PNG"
        case .processingFailed(let message):
            return "Photo processing failed: \(message)"
        case .uploadFailed(let message):
            return "Photo upload failed: \(message)"
        case .deleteFailed(let message):
            return "Photo deletion failed: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch photos: \(message)"
        case .updateFailed(let message):
            return "Photo update failed: \(message)"
        }
    }
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let val as String:
            try container.encode(val)
        case let val as Int:
            try container.encode(val)
        case let val as Double:
            try container.encode(val)
        case let val as Bool:
            try container.encode(val)
        case let val as [Any]:
            try container.encode(val.map { AnyEncodable($0) })
        case let val as [String: Any]:
            try container.encode(val.mapValues { AnyEncodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyEncodable cannot encode \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
