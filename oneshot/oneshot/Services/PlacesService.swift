import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct Place: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let formattedAddress: String
    let rating: Double?
    let userRatingCount: Int?
    let priceLevel: String?
    let types: [String]?
    let websiteUri: String?
    let googleMapsUri: String?
}

enum PlaceCategory: String, CaseIterable, Identifiable {
    case cheapEats = "Cheap Eats"
    case fancyDining = "Fancy Dining"
    case movies = "Movies"
    case bars = "Bars"

    var id: String { rawValue }

    var query: String {
        switch self {
        case .cheapEats: return "Cheap restaurants"
        case .fancyDining: return "Expensive restaurants"
        case .movies: return "Movie theater"
        case .bars: return "Bars"
        }
    }
    
    var icon: String {
        switch self {
        case .cheapEats: return "takeoutbag.and.cup.and.straw.fill"
        case .fancyDining: return "fork.knife"
        case .movies: return "popcorn.fill"
        case .bars: return "wineglass.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cheapEats: return .orange
        case .fancyDining: return .purple
        case .movies: return .red
        case .bars: return .blue
        }
    }
}

// MARK: - Service

@MainActor
class PlacesService: ObservableObject {
    private let session = URLSession.shared
    // Switch to Legacy API endpoint
    private let baseURL = "https://maps.googleapis.com/maps/api/place/textsearch/json"

    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchPlaces(category: PlaceCategory) async {
        isLoading = true
        errorMessage = nil
        
        let apiKey = AppEnvironment.googlePlacesAPIKey
        
        guard !apiKey.contains("YOUR_") else {
            self.errorMessage = "API Key Missing"
            self.isLoading = false
            return
        }

        // Construct URL components for GET request (Legacy API uses GET)
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: "\(category.query) in Spitalfields, London"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Legacy API is GET
        
        // Add Bundle ID header for restricted API keys
        if let bundleId = Bundle.main.bundleIdentifier {
            request.addValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }

        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("❌ Places API Error (Status: \(statusCode))")
                if let str = String(data: data, encoding: .utf8) {
                    print("❌ Response Body: \(str)")
                }
                self.errorMessage = "Server Error (\(statusCode))"
                throw URLError(.badServerResponse)
            }

            // Decode Legacy Response
            let result = try JSONDecoder().decode(LegacyPlacesResponse.self, from: data)
            
            // Check for API-level error messages (Legacy API returns 200 even for some errors)
            if let status = result.status, status != "OK" && status != "ZERO_RESULTS" {
                 print("❌ API Status: \(status)")
                 print("❌ Error Message: \(result.error_message ?? "Unknown")")
                 self.errorMessage = "API Error: \(status)"
                 self.places = []
            } else {
                self.places = result.results?.map { $0.toPlace() } ?? []
            }
            
        } catch {
            print("Error fetching places: \(error)")
            if self.errorMessage == nil {
                self.errorMessage = error.localizedDescription
            }
        }
        
        self.isLoading = false
    }
}

// MARK: - Helper Structs for Decoding (Legacy API)

private struct LegacyPlacesResponse: Codable {
    let results: [LegacyGooglePlace]?
    let status: String?
    let error_message: String?
}

private struct LegacyGooglePlace: Codable {
    let place_id: String
    let name: String
    let formatted_address: String?
    let rating: Double?
    let user_ratings_total: Int?
    let price_level: Int? // Legacy uses Int for price level
    let types: [String]?
    
    // Legacy API doesn't return these directly in search, we construct maps link manually
    var googleMapsUri: String {
        "https://www.google.com/maps/place/?q=place_id:\(place_id)"
    }

    func toPlace() -> Place {
        // Convert numeric price level to string ($ symbols)
        let priceString: String?
        if let level = price_level {
            priceString = String(repeating: "$", count: level)
        } else {
            priceString = nil
        }
        
        return Place(
            id: place_id,
            name: name,
            formattedAddress: formatted_address ?? "",
            rating: rating,
            userRatingCount: user_ratings_total,
            priceLevel: priceString,
            types: types,
            websiteUri: nil, // Not available in basic search
            googleMapsUri: googleMapsUri
        )
    }
}
