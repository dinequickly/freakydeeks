import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressView(currentStep: appState.onboardingStep)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Content
                TabView(selection: $appState.onboardingStep) {
                    OnboardingBasicsView()
                        .tag(OnboardingStep.basics)

                    OnboardingPhotosView()
                        .tag(OnboardingStep.photos)

                    OnboardingProfileView()
                        .tag(OnboardingStep.profile)

                    OnboardingDuoView()
                        .tag(OnboardingStep.duo)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: appState.onboardingStep)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Progress View
struct OnboardingProgressView: View {
    let currentStep: OnboardingStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.pink : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Step 1: Basics
struct OnboardingBasicsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDatePicker = false

    private var isValid: Bool {
        !appState.onboardingFirstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Basics")
                        .font(.largeTitle.bold())

                    Text("Let's start with some basics about you")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // First Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("First name")
                        .font(.headline)

                    TextField("Your first name", text: $appState.onboardingFirstName)
                        .textFieldStyle(OnboardingTextFieldStyle())
                }

                // Birthday
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birthday")
                        .font(.headline)

                    Button {
                        showDatePicker.toggle()
                    } label: {
                        HStack {
                            Text(appState.onboardingBirthday, style: .date)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.pink)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if showDatePicker {
                        DatePicker(
                            "Birthday",
                            selection: $appState.onboardingBirthday,
                            in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                    }
                }

                // Gender
                VStack(alignment: .leading, spacing: 8) {
                    Text("I am a...")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            SelectionButton(
                                title: gender.rawValue,
                                isSelected: appState.onboardingGender == gender
                            ) {
                                appState.onboardingGender = gender
                            }
                        }
                    }
                }

                // Gender Preference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Show me...")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GenderPreference.allCases, id: \.self) { preference in
                            SelectionButton(
                                title: preference.rawValue,
                                isSelected: appState.onboardingGenderPreference == preference
                            ) {
                                appState.onboardingGenderPreference = preference
                            }
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingNextButton(title: "Continue", isEnabled: isValid) {
                appState.onboardingStep = .photos
            }
        }
    }
}

// MARK: - Step 2: Photos
struct OnboardingPhotosView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var selectedImageIndex: Int?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var isValid: Bool {
        appState.onboardingPhotos.count >= 3
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Photos")
                        .font(.largeTitle.bold())

                    Text("Add at least 3 photos of yourself")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // Photo Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        PhotoSlotView(
                            image: index < appState.onboardingPhotos.count ? appState.onboardingPhotos[index] : nil,
                            index: index,
                            onTap: {
                                selectedImageIndex = index
                                showImagePicker = true
                            },
                            onDelete: {
                                if index < appState.onboardingPhotos.count {
                                    appState.onboardingPhotos.remove(at: index)
                                }
                            }
                        )
                    }
                }

                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Label("Drag to reorder", systemImage: "arrow.up.arrow.down")
                    Label("Face clearly visible", systemImage: "face.smiling")
                    Label("No group photos for first pic", systemImage: "person.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button("Back") {
                    appState.onboardingStep = .basics
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                OnboardingNextButton(title: "Continue", isEnabled: isValid) {
                    appState.onboardingStep = .profile
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $appState.onboardingPhotos, selectedIndex: selectedImageIndex)
        }
    }
}

// MARK: - Photo Slot View
struct PhotoSlotView: View {
    let image: UIImage?
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture(perform: onTap)

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .offset(x: 8, y: -8)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 150)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.title2)
                            if index == 0 {
                                Text("Main")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.pink)
                    }
                    .onTapGesture(perform: onTap)
            }
        }
    }
}

// MARK: - Step 3: Profile
struct OnboardingProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPromptPicker = false

    private var isValid: Bool {
        !appState.onboardingBio.trimmingCharacters(in: .whitespaces).isEmpty &&
        appState.onboardingInterests.count >= 3
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Profile")
                        .font(.largeTitle.bold())

                    Text("Tell us about yourself")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // Bio
                VStack(alignment: .leading, spacing: 8) {
                    Text("About me")
                        .font(.headline)

                    TextEditor(text: $appState.onboardingBio)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }

                // Prompts
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Prompts")
                            .font(.headline)
                        Spacer()
                        Button("Add") {
                            showPromptPicker = true
                        }
                        .foregroundColor(.pink)
                    }

                    if appState.onboardingPrompts.isEmpty {
                        Text("Add prompts to show your personality")
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ForEach(appState.onboardingPrompts) { prompt in
                            PromptCard(prompt: prompt) {
                                appState.onboardingPrompts.removeAll { $0.id == prompt.id }
                            }
                        }
                    }
                }

                // University & Major
                VStack(alignment: .leading, spacing: 8) {
                    Text("Education (optional)")
                        .font(.headline)

                    TextField("University", text: $appState.onboardingUniversity)
                        .textFieldStyle(OnboardingTextFieldStyle())

                    TextField("Major", text: $appState.onboardingMajor)
                        .textFieldStyle(OnboardingTextFieldStyle())
                }

                // Interests
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interests (pick at least 3)")
                        .font(.headline)

                    InterestPicker(selectedInterests: $appState.onboardingInterests)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button("Back") {
                    appState.onboardingStep = .photos
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                OnboardingNextButton(title: "Continue", isEnabled: isValid) {
                    appState.onboardingStep = .duo
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showPromptPicker) {
            PromptPickerView(prompts: $appState.onboardingPrompts)
        }
    }
}

// MARK: - Step 4: Duo
struct OnboardingDuoView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.pink.gradient)

                    Text("Find Your Duo")
                        .font(.largeTitle.bold())

                    Text("Dating is better with friends! Team up with a bestie and match with other duos for epic double dates.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                // How it works
                VStack(alignment: .leading, spacing: 16) {
                    Text("How it works")
                        .font(.headline)

                    DuoExplainerRow(
                        icon: "1.circle.fill",
                        title: "Invite a friend",
                        description: "Send an invite to your bestie to form a duo"
                    )

                    DuoExplainerRow(
                        icon: "2.circle.fill",
                        title: "Create your duo profile",
                        description: "Combine your vibes into one awesome profile"
                    )

                    DuoExplainerRow(
                        icon: "3.circle.fill",
                        title: "Match with other duos",
                        description: "Swipe on other duos and plan double dates"
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    Task {
                        await appState.completeOnboarding()
                    }
                } label: {
                    Label("Invite a Friend", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink.gradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    Task {
                        await appState.completeOnboarding()
                    }
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Duo Explainer Row
struct DuoExplainerRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.pink)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views
struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? Color.pink : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
                )
        }
    }
}

struct OnboardingNextButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEnabled ? Color.clear : Color.gray.opacity(0.3))
                .backgroundStyle(isEnabled ? AnyShapeStyle(.pink.gradient) : AnyShapeStyle(Color.clear))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Interest Picker
struct InterestPicker: View {
    @Binding var selectedInterests: [Interest]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Interest.allInterests) { interest in
                InterestTag(
                    interest: interest,
                    isSelected: selectedInterests.contains(interest)
                ) {
                    if selectedInterests.contains(interest) {
                        selectedInterests.removeAll { $0.id == interest.id }
                    } else {
                        selectedInterests.append(interest)
                    }
                }
            }
        }
    }
}

struct InterestTag: View {
    let interest: Interest
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(interest.emoji)
                Text(interest.name)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.pink.opacity(0.2) : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .pink : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Prompt Card
struct PromptCard: View {
    let prompt: ProfilePrompt
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prompt.prompt.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Text(prompt.answer)
                .font(.subheadline)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Prompt Picker View
struct PromptPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var prompts: [ProfilePrompt]
    @State private var selectedPrompt: PromptType?
    @State private var answer: String = ""

    var body: some View {
        NavigationStack {
            List {
                if let selected = selectedPrompt {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selected.rawValue)
                                .font(.headline)

                            TextField("Your answer...", text: $answer, axis: .vertical)
                                .lineLimit(3...6)

                            Button("Save") {
                                prompts.append(ProfilePrompt(prompt: selected, answer: answer))
                                dismiss()
                            }
                            .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    Section("Choose a prompt") {
                        ForEach(PromptType.allCases, id: \.self) { prompt in
                            Button {
                                selectedPrompt = prompt
                            } label: {
                                Text(prompt.rawValue)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                if let index = parent.selectedIndex, index < parent.images.count {
                    parent.images[index] = image
                } else {
                    parent.images.append(image)
                }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppState())
}
