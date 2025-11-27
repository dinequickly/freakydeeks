# Swift Package Dependencies Guide

This guide walks you through adding all required Swift packages to your Xcode project.

## Required Packages

1. **Supabase Swift SDK** - Backend integration
2. **Google Sign-In** - Google OAuth authentication
3. **Kingfisher** - Image loading and caching

## Installation Instructions

### Method 1: Using Xcode (Recommended)

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Add each package below one at a time

---

### 1. Supabase Swift SDK

**URL:** `https://github.com/supabase/supabase-swift`

**Steps:**
1. Paste URL into search field
2. Select version: **Up to Next Major Version** → `2.0.0` (or latest)
3. Click **Add Package**
4. In the dialog, select these products:
   - ☑️ **Supabase** (main package)
   - ☑️ **Auth** (authentication)
   - ☑️ **PostgREST** (database)
   - ☑️ **Storage** (file storage)
   - ☑️ **Realtime** (real-time subscriptions - for future use)
5. Add to target: **oneshot**
6. Click **Add Package**

---

### 2. Google Sign-In iOS

**URL:** `https://github.com/google/GoogleSignIn-iOS`

**Steps:**
1. Paste URL into search field
2. Select version: **Up to Next Major Version** → `7.0.0` (or latest)
3. Click **Add Package**
4. In the dialog, select:
   - ☑️ **GoogleSignIn**
   - ☑️ **GoogleSignInSwift** (SwiftUI support)
5. Add to target: **oneshot**
6. Click **Add Package**

---

### 3. Kingfisher

**URL:** `https://github.com/onevcat/Kingfisher`

**Steps:**
1. Paste URL into search field
2. Select version: **Up to Next Major Version** → `7.0.0` (or latest)
3. Click **Add Package**
4. In the dialog, select:
   - ☑️ **Kingfisher**
5. Add to target: **oneshot**
6. Click **Add Package**

---

## Verify Installation

1. In Xcode Project Navigator, you should see a **Package Dependencies** section
2. It should list:
   - supabase-swift
   - GoogleSignIn-iOS
   - Kingfisher

3. Try building the project (**Cmd+B**)
   - If you see "No such module" errors, try:
     - Clean Build Folder (**Cmd+Shift+K**)
     - Resolve Package Versions (**File → Packages → Resolve Package Versions**)
     - Restart Xcode

---

## Method 2: Using Package.swift (for CLI/SPM projects)

If you're using Swift Package Manager from command line:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
],
targets: [
    .target(
        name: "oneshot",
        dependencies: [
            .product(name: "Supabase", package: "supabase-swift"),
            .product(name: "Auth", package: "supabase-swift"),
            .product(name: "PostgREST", package: "supabase-swift"),
            .product(name: "Storage", package: "supabase-swift"),
            .product(name: "Realtime", package: "supabase-swift"),
            .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            .product(name: "Kingfisher", package: "Kingfisher"),
        ]
    ),
]
```

---

## Package Versions (as of Nov 2024)

- **Supabase Swift**: 2.x.x
- **Google Sign-In**: 7.x.x
- **Kingfisher**: 7.x.x

Always use the latest stable version unless there are compatibility issues.

---

## Troubleshooting

### Package Resolution Fails

**Error:** "Failed to resolve package dependencies"

**Solution:**
1. Check your internet connection
2. Go to **File → Packages → Reset Package Caches**
3. Try again

### Build Errors After Adding Packages

**Error:** "No such module 'Supabase'" (or similar)

**Solutions:**
1. **Clean Build Folder**: Cmd+Shift+K
2. **Resolve Packages**: File → Packages → Resolve Package Versions
3. **Restart Xcode**
4. **Check Package is Added to Target**:
   - Select project in Navigator
   - Select **oneshot** target
   - Go to **General** tab
   - Scroll to **Frameworks, Libraries, and Embedded Content**
   - Verify packages are listed

### Version Conflicts

**Error:** "Package 'X' requires minimum platform version..."

**Solution:**
1. Select project in Navigator
2. Select **oneshot** target
3. Go to **General** tab
4. Check **Minimum Deployments** is iOS 17.0 or higher

### Google Sign-In Import Errors

If you see errors importing GoogleSignIn:

1. Make sure you added **both**:
   - GoogleSignIn
   - GoogleSignInSwift
2. Import in Swift files:
   ```swift
   import GoogleSignIn
   import GoogleSignInSwift
   ```

---

## Usage in Code

### Import Statements

Add these imports where needed:

```swift
// Supabase
import Supabase
import Auth
import PostgREST
import Storage

// Google Sign-In
import GoogleSignIn
import GoogleSignInSwift

// Image Loading
import Kingfisher
```

### Example: Using Kingfisher in SwiftUI

```swift
import SwiftUI
import Kingfisher

struct ProfileImageView: View {
    let url: URL

    var body: some View {
        KFImage(url)
            .placeholder {
                ProgressView()
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
    }
}
```

---

## Next Steps

After adding packages:
1. ✅ Configure `Environment.swift` with your Supabase credentials
2. ✅ Set up Google OAuth in Google Cloud Console
3. ✅ Configure URL schemes in Info.plist
4. ✅ Build and test authentication flow

---

## Resources

- **Supabase Swift Docs**: https://github.com/supabase/supabase-swift
- **Google Sign-In Docs**: https://developers.google.com/identity/sign-in/ios
- **Kingfisher Docs**: https://github.com/onevcat/Kingfisher

---

## License & Attribution

All packages are open source with their respective licenses:
- Supabase Swift: MIT License
- Google Sign-In: Apache 2.0
- Kingfisher: MIT License
