import SwiftUI

struct ThingsToDoView: View {
    @ObservedObject var placesService = ServiceContainer.shared.placesService
    @State private var selectedCategory: PlaceCategory = .cheapEats
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Location Header
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Spitalfields, London")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                
                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PlaceCategory.allCases) {
                            category in
                            CategoryPill(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Content
                ZStack {
                    if placesService.isLoading {
                        ProgressView("Finding the best spots...")
                    } else if let error = placesService.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if error.contains("API Key") || error.contains("Missing") {
                                Text("Please add your Google Places API Key in\nEnvironment.swift")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button("Retry") {
                                selectCategory(selectedCategory)
                            }
                        }
                    } else if placesService.places.isEmpty {
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No places found")
                                .foregroundColor(.gray)
                        }
                    } else {
                        List(placesService.places) {
                            place in
                            PlaceRow(place: place)
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await placesService.fetchPlaces(category: selectedCategory)
                        }
                    }
                }
            }
            .navigationTitle("Things to Do")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Load initial data only if empty
            if placesService.places.isEmpty {
                selectCategory(.cheapEats)
            }
        }
    }
    
    private func selectCategory(_ category: PlaceCategory) {
        selectedCategory = category
        Task {
            await placesService.fetchPlaces(category: category)
        }
    }
}

// MARK: - Subviews

struct CategoryPill: View {
    let category: PlaceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? category.color : Color(uiColor: .secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct PlaceRow: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                    
                    Text(place.formattedAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if let rating = place.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption.weight(.bold))
                        if let count = place.userRatingCount {
                            Text("(\(count))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            
            HStack {
                if let types = place.types {
                    Text(types.prefix(2).map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: " • "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let mapsUri = place.googleMapsUri, let url = URL(string: mapsUri) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "map")
                            Text("Maps")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ThingsToDoView()
}
