import SwiftUI

/// Welcome/landing screen shown to unauthenticated users
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // App logo/icon
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.pink.gradient)
                        .padding(.bottom, 8)

                    // App name
                    Text("OneShot")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    // Tagline
                    Text("Double dating made simple")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    // Call to action
                    VStack(spacing: 16) {
                        // Sign Up button
                        Button {
                            showSignUp = true
                        } label: {
                            Label("Create Account", systemImage: "person.badge.plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.pink.gradient)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Login button
                        Button {
                            showLogin = true
                        } label: {
                            Label("Sign In", systemImage: "arrow.right.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white)
                                .foregroundColor(.pink)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.pink, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
                    .environmentObject(ServiceContainer.shared.authService)
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(ServiceContainer.shared.authService)
                    .environmentObject(appState)
            }
        }
    }
}

#Preview {
    WelcomeView()
}
