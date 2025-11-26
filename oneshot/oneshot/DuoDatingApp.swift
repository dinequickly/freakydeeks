import SwiftUI

// Note: Main entry point is in oneshotApp.swift

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingContainerView()
            } else if appState.currentDuo == nil {
                DuoRequiredView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.isOnboardingComplete)
    }
}

// MARK: - Duo Required View
struct DuoRequiredView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.pink.gradient)

                Text("Find Your Duo")
                    .font(.largeTitle.bold())

                Text("You need a duo partner to start swiping!\nInvite a friend or accept an invite.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Spacer()

                NavigationLink(destination: DuoManagementView()) {
                    Label("Set Up Your Duo", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink.gradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
