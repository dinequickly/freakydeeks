import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    ProfileHeaderView()

                    // Quick actions
                    QuickActionsSection()

                    // Profile sections
                    ProfileSectionsView()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            // Main photo
            if let photo = appState.currentUser?.photos.first {
                AsyncImage(url: URL(string: photo.url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Text(appState.currentUser?.firstName.prefix(1) ?? "")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 4))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }

            VStack(spacing: 4) {
                if let user = appState.currentUser {
                    Text("\(user.firstName), \(user.age)")
                        .font(.title2.bold())

                    if let university = user.university {
                        Text(university)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Verification badges (placeholder)
            HStack(spacing: 8) {
                Label("Verified", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: EditProfileView()) {
                QuickActionButton(
                    icon: "pencil",
                    title: "Edit Profile",
                    color: .pink
                )
            }
            .buttonStyle(.plain)

            NavigationLink(destination: ProfilePreviewView()) {
                QuickActionButton(
                    icon: "eye.fill",
                    title: "Preview",
                    color: .purple
                )
            }
            .buttonStyle(.plain)

            NavigationLink(destination: DuoManagementView()) {
                QuickActionButton(
                    icon: "person.2.fill",
                    title: "My Duo",
                    color: .orange
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Profile Sections View
struct ProfileSectionsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            // Photos section
            ProfileSection(title: "Photos") {
                NavigationLink(destination: EditPhotosView()) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(appState.currentUser?.photos ?? []) { photo in
                                AsyncImage(url: URL(string: photo.url)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 80, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            // Add more button
                            if (appState.currentUser?.photos.count ?? 0) < 6 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.tertiarySystemBackground))
                                    .frame(width: 80, height: 100)
                                    .overlay {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(.pink)
                                    }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Bio section
            ProfileSection(title: "About Me") {
                NavigationLink(destination: EditBioView()) {
                    Text(appState.currentUser?.bio ?? "Add a bio...")
                        .font(.subheadline)
                        .foregroundColor(appState.currentUser?.bio.isEmpty ?? true ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            // Prompts section
            ProfileSection(title: "Prompts") {
                NavigationLink(destination: EditPromptsView()) {
                    VStack(spacing: 8) {
                        if let prompts = appState.currentUser?.prompts, !prompts.isEmpty {
                            ForEach(prompts) { prompt in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prompt.prompt.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(prompt.answer)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        } else {
                            Text("Add prompts to show your personality")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Interests section
            ProfileSection(title: "Interests") {
                NavigationLink(destination: EditInterestsView()) {
                    if let interests = appState.currentUser?.interests, !interests.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(interests) { interest in
                                Text("\(interest.emoji) \(interest.name)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.1))
                                    .foregroundColor(.pink)
                                    .clipShape(Capsule())
                            }
                        }
                    } else {
                        Text("Add your interests")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Education section
            ProfileSection(title: "Education") {
                NavigationLink(destination: EditEducationView()) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let university = appState.currentUser?.university {
                            Label(university, systemImage: "building.columns")
                                .font(.subheadline)
                        }
                        if let major = appState.currentUser?.major {
                            Label(major, systemImage: "book")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if appState.currentUser?.university == nil && appState.currentUser?.major == nil {
                            Text("Add your education")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Profile Section
struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            NavigationLink("Photos", destination: EditPhotosView())
            NavigationLink("Bio", destination: EditBioView())
            NavigationLink("Prompts", destination: EditPromptsView())
            NavigationLink("Interests", destination: EditInterestsView())
            NavigationLink("Education", destination: EditEducationView())
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Edit Photos View
struct EditPhotosView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    if let photos = appState.currentUser?.photos, index < photos.count {
                        AsyncImage(url: URL(string: photos[index].url)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                // Delete photo
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .black.opacity(0.5))
                            }
                            .offset(x: 8, y: -8)
                        }
                    } else {
                        Button {
                            showImagePicker = true
                        } label: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 150)
                                .overlay {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                        if index == 0 {
                                            Text("Main")
                                                .font(.caption)
                                        }
                                    }
                                    .foregroundColor(.pink)
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Edit Photos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Edit Bio View
struct EditBioView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var bio: String = ""

    var body: some View {
        Form {
            Section {
                TextEditor(text: $bio)
                    .frame(minHeight: 150)
            } header: {
                Text("About Me")
            } footer: {
                Text("Write something that represents you!")
            }
        }
        .navigationTitle("Edit Bio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    appState.currentUser?.bio = bio
                    dismiss()
                }
            }
        }
        .onAppear {
            bio = appState.currentUser?.bio ?? ""
        }
    }
}

// MARK: - Edit Prompts View
struct EditPromptsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPromptPicker = false

    var body: some View {
        List {
            if let prompts = appState.currentUser?.prompts {
                ForEach(prompts) { prompt in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prompt.prompt.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(prompt.answer)
                    }
                }
                .onDelete { indexSet in
                    // Delete prompt
                }
            }

            Button {
                showPromptPicker = true
            } label: {
                Label("Add Prompt", systemImage: "plus")
            }
        }
        .navigationTitle("Edit Prompts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPromptPicker) {
            PromptPickerView(prompts: Binding(
                get: { appState.currentUser?.prompts ?? [] },
                set: { appState.currentUser?.prompts = $0 }
            ))
        }
    }
}

// MARK: - Edit Interests View
struct EditInterestsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select at least 3 interests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                InterestPicker(selectedInterests: Binding(
                    get: { appState.currentUser?.interests ?? [] },
                    set: { appState.currentUser?.interests = $0 }
                ))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Edit Interests")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Edit Education View
struct EditEducationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var university: String = ""
    @State private var major: String = ""

    var body: some View {
        Form {
            Section("University") {
                TextField("University name", text: $university)
            }

            Section("Major") {
                TextField("Your major", text: $major)
            }
        }
        .navigationTitle("Education")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    appState.currentUser?.university = university.isEmpty ? nil : university
                    appState.currentUser?.major = major.isEmpty ? nil : major
                    dismiss()
                }
            }
        }
        .onAppear {
            university = appState.currentUser?.university ?? ""
            major = appState.currentUser?.major ?? ""
        }
    }
}

// MARK: - Profile Preview View
struct ProfilePreviewView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("This is how others see you")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Mock card preview
                if let user = appState.currentUser {
                    ProfileCardPreview(user: user)
                }
            }
            .padding()
        }
        .navigationTitle("Profile Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileCardPreview: View {
    let user: User

    var body: some View {
        VStack(spacing: 0) {
            // Photo
            if let photo = user.photos.first {
                AsyncImage(url: URL(string: photo.url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Text(user.firstName.prefix(1))
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(.white)
                        }
                }
                .frame(height: 400)
                .clipped()
            }

            // Info
            VStack(alignment: .leading, spacing: 12) {
                Text("\(user.firstName), \(user.age)")
                    .font(.title2.bold())

                if let university = user.university {
                    Label(university, systemImage: "building.columns")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.subheadline)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(user.interests.prefix(5)) { interest in
                            Text("\(interest.emoji) \(interest.name)")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
