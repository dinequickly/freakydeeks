import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            // Account section
            Section("Account") {
                NavigationLink(destination: AccountSettingsView()) {
                    Label("Account Settings", systemImage: "person.circle")
                }

                NavigationLink(destination: PrivacySettingsView()) {
                    Label("Privacy", systemImage: "lock.shield")
                }

                NavigationLink(destination: LinkedAccountsView()) {
                    Label("Linked Accounts", systemImage: "link")
                }
            }

            // Discovery section
            Section("Discovery") {
                NavigationLink(destination: DiscoverySettingsView()) {
                    Label("Discovery Preferences", systemImage: "slider.horizontal.3")
                }

                NavigationLink(destination: LocationSettingsView()) {
                    Label("Location", systemImage: "location")
                }
            }

            // Notifications section
            Section("Notifications") {
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notification Preferences", systemImage: "bell")
                }
            }

            // Support section
            Section("Support") {
                NavigationLink(destination: HelpCenterView()) {
                    Label("Help Center", systemImage: "questionmark.circle")
                }

                NavigationLink(destination: SafetyTipsView()) {
                    Label("Safety Tips", systemImage: "shield.checkered")
                }

                Button {
                    // Open email
                } label: {
                    Label("Contact Us", systemImage: "envelope")
                }
            }

            // Legal section
            Section("Legal") {
                NavigationLink(destination: TermsOfServiceView()) {
                    Label("Terms of Service", systemImage: "doc.text")
                }

                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                NavigationLink(destination: CommunityGuidelinesView()) {
                    Label("Community Guidelines", systemImage: "person.3")
                }
            }

            // Account actions section
            Section {
                Button {
                    showLogoutAlert = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.primary)
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            }

            // App info
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                // Logout
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Delete account
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

// MARK: - Account Settings View
struct AccountSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = "user@example.com"
    @State private var phone = ""

    var body: some View {
        Form {
            Section("Email") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section("Phone Number") {
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }

            Section("Password") {
                NavigationLink("Change Password") {
                    ChangePasswordView()
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
            }

            Section {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm Password", text: $confirmPassword)
            }

            Section {
                Button("Update Password") {
                    // Update password
                }
                .disabled(newPassword.isEmpty || newPassword != confirmPassword)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @State private var showOnlineStatus = true
    @State private var showLastActive = true
    @State private var showDistance = true
    @State private var showReadReceipts = true

    var body: some View {
        Form {
            Section {
                Toggle("Show Online Status", isOn: $showOnlineStatus)
                Toggle("Show Last Active", isOn: $showLastActive)
                Toggle("Show Distance", isOn: $showDistance)
                Toggle("Read Receipts", isOn: $showReadReceipts)
            }

            Section("Blocked Users") {
                NavigationLink("Blocked Users") {
                    BlockedUsersView()
                }
            }

            Section("Data") {
                NavigationLink("Download My Data") {
                    DownloadDataView()
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Blocked Users View
struct BlockedUsersView: View {
    var body: some View {
        List {
            Text("No blocked users")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Download Data View
struct DownloadDataView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 60))
                .foregroundStyle(.pink.gradient)

            Text("Download Your Data")
                .font(.title2.bold())

            Text("Request a copy of all your data. This may take up to 48 hours.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                // Request data
            } label: {
                Text("Request Download")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.pink.gradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Download Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Linked Accounts View
struct LinkedAccountsView: View {
    @State private var instagramLinked = false
    @State private var spotifyLinked = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "camera")
                        .foregroundColor(.purple)
                    Text("Instagram")
                    Spacer()
                    if instagramLinked {
                        Text("Connected")
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Connect") {
                            // Connect Instagram
                        }
                    }
                }

                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.green)
                    Text("Spotify")
                    Spacer()
                    if spotifyLinked {
                        Text("Connected")
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Connect") {
                            // Connect Spotify
                        }
                    }
                }
            }
        }
        .navigationTitle("Linked Accounts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Discovery Settings View
struct DiscoverySettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Age Range") {
                VStack(alignment: .leading) {
                    Text("Minimum Age: \(appState.discoveryPreferences.minAge)")
                    Slider(
                        value: Binding(
                            get: { Double(appState.discoveryPreferences.minAge) },
                            set: { appState.discoveryPreferences.minAge = Int($0) }
                        ),
                        in: 18...50,
                        step: 1
                    )
                }

                VStack(alignment: .leading) {
                    Text("Maximum Age: \(appState.discoveryPreferences.maxAge)")
                    Slider(
                        value: Binding(
                            get: { Double(appState.discoveryPreferences.maxAge) },
                            set: { appState.discoveryPreferences.maxAge = Int($0) }
                        ),
                        in: Double(appState.discoveryPreferences.minAge)...60,
                        step: 1
                    )
                }
            }

            Section("Distance") {
                VStack(alignment: .leading) {
                    Text("Maximum Distance: \(appState.discoveryPreferences.maxDistance) miles")
                    Slider(
                        value: Binding(
                            get: { Double(appState.discoveryPreferences.maxDistance) },
                            set: { appState.discoveryPreferences.maxDistance = Int($0) }
                        ),
                        in: 1...100,
                        step: 1
                    )
                }
            }

            Section("Show Me") {
                Picker("Gender Preference", selection: $appState.discoveryPreferences.showMe) {
                    ForEach(GenderPreference.allCases, id: \.self) { preference in
                        Text(preference.rawValue).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Discovery")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Location Settings View
struct LocationSettingsView: View {
    @State private var locationEnabled = true

    var body: some View {
        Form {
            Section {
                Toggle("Enable Location", isOn: $locationEnabled)
            } footer: {
                Text("Location is used to show you duos nearby. You can disable it, but you won't see distance information.")
            }

            Section("Current Location") {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("New York, NY")
                    Spacer()
                    Button("Update") {
                        // Update location
                    }
                }
            }
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Toggle("New Matches", isOn: $appState.notificationSettings.newMatches)
                Toggle("Messages", isOn: $appState.notificationSettings.messages)
                Toggle("Duo Invites", isOn: $appState.notificationSettings.duoInvites)
                Toggle("Likes (Premium)", isOn: $appState.notificationSettings.likes)
                Toggle("App Updates", isOn: $appState.notificationSettings.appUpdates)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Help Center View
struct HelpCenterView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("How does DuoDating work?") { HelpArticleView(title: "How does DuoDating work?") }
                NavigationLink("How to create a duo") { HelpArticleView(title: "How to create a duo") }
                NavigationLink("Matching with other duos") { HelpArticleView(title: "Matching with other duos") }
            }

            Section("Account") {
                NavigationLink("How to edit my profile") { HelpArticleView(title: "How to edit my profile") }
                NavigationLink("Changing my preferences") { HelpArticleView(title: "Changing my preferences") }
            }

            Section("Safety") {
                NavigationLink("How to report a user") { HelpArticleView(title: "How to report a user") }
                NavigationLink("Blocking users") { HelpArticleView(title: "Blocking users") }
            }
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpArticleView: View {
    let title: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title2.bold())

                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
                    .foregroundStyle(.secondary)

                Text("Getting Started")
                    .font(.headline)

                Text("Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Safety Tips View
struct SafetyTipsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SafetyTipCard(
                    icon: "video.fill",
                    title: "Video Chat First",
                    description: "Get to know your matches through video chat before meeting in person."
                )

                SafetyTipCard(
                    icon: "mappin.and.ellipse",
                    title: "Meet in Public",
                    description: "Always meet your matches in public places for the first few dates."
                )

                SafetyTipCard(
                    icon: "person.2.fill",
                    title: "Tell Someone",
                    description: "Let a friend or family member know about your plans when meeting someone new."
                )

                SafetyTipCard(
                    icon: "car.fill",
                    title: "Arrange Your Own Transport",
                    description: "Have your own way to get home. Don't depend on your date for transportation."
                )

                SafetyTipCard(
                    icon: "exclamationmark.shield.fill",
                    title: "Report Suspicious Behavior",
                    description: "If something feels off, trust your instincts and report the user."
                )
            }
            .padding()
        }
        .navigationTitle("Safety Tips")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SafetyTipCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.pink)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content goes here...")
                .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content goes here...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Community Guidelines View
struct CommunityGuidelinesView: View {
    var body: some View {
        ScrollView {
            Text("Community Guidelines content goes here...")
                .padding()
        }
        .navigationTitle("Community Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}
