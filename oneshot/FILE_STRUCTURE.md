# OneShot Project - Complete File Structure

## 📋 Quick Reference

All files created for the Supabase migration are listed below with their locations and purposes.

---

## 📁 Project Structure

```
oneshot/
├── Database/
│   ├── Migrations/
│   │   ├── 001_initial_schema.sql          # Database tables and schema
│   │   ├── 002_row_level_security.sql      # RLS policies for security
│   │   └── 003_storage_policies.sql        # Storage bucket policies
│   └── README.md                            # Database setup instructions
│
├── oneshot/
│   ├── Config/
│   │   ├── Environment.swift.template       # Template for credentials
│   │   ├── Environment.swift               # Your actual credentials (gitignored)
│   │   └── SupabaseConfig.swift            # Supabase client singleton
│   │
│   ├── Services/
│   │   ├── ServiceContainer.swift          # Dependency injection container
│   │   ├── AuthService.swift               # Authentication service
│   │   ├── UserService.swift               # User profile operations
│   │   ├── PairService.swift               # Duo/pair management
│   │   ├── MatchService.swift              # Matching and messaging
│   │   └── PhotoService.swift              # Photo upload/storage
│   │
│   ├── Authentication/
│   │   ├── WelcomeView.swift               # Landing page
│   │   ├── LoginView.swift                 # Email + Google login
│   │   ├── SignUpView.swift                # Account creation
│   │   └── ForgotPasswordView.swift        # Password reset
│   │
│   ├── Models.swift                         # Existing models (to be updated)
│   ├── AppState.swift                       # Existing state (to be updated)
│   └── ... (other existing files)
│
├── .gitignore                               # Git ignore rules
├── SETUP_GUIDE.md                           # Complete setup instructions
├── PACKAGE_DEPENDENCIES.md                  # Swift package installation guide
├── MIGRATION_COMPLETE.md                    # Implementation summary
└── FILE_STRUCTURE.md                        # This file

```

---

## 📄 File Descriptions

### Database Files

| File | Purpose | When to Use |
|------|---------|-------------|
| `001_initial_schema.sql` | Creates all database tables | First SQL file to run in Supabase |
| `002_row_level_security.sql` | Adds security policies | Run after schema creation |
| `003_storage_policies.sql` | Configures photo storage | Run after creating storage bucket |
| `Database/README.md` | Setup instructions | Reference during Supabase setup |

### Configuration Files

| File | Purpose | When to Use |
|------|---------|-------------|
| `Environment.swift.template` | Template with instructions | Copy this to create Environment.swift |
| `Environment.swift` | Your actual credentials | Add your Supabase/Google credentials here |
| `SupabaseConfig.swift` | Supabase client | Already configured, no changes needed |

### Service Files

| File | Purpose | Key Methods |
|------|---------|-------------|
| `ServiceContainer.swift` | Manages all services | Access via `ServiceContainer.shared` |
| `AuthService.swift` | Authentication | `signUp()`, `signIn()`, `signInWithGoogle()` |
| `UserService.swift` | User profiles | `createUserProfile()`, `getUser()`, `updateUserProfile()` |
| `PairService.swift` | Duo management | `sendInvite()`, `acceptInvite()`, `getPair()` |
| `MatchService.swift` | Matching/messaging | `recordSwipe()`, `getMatches()`, `sendMessage()` |
| `PhotoService.swift` | Photo operations | `uploadPhoto()`, `deletePhoto()`, `getPhotos()` |

### Authentication Views

| File | Purpose | Features |
|------|---------|----------|
| `WelcomeView.swift` | Landing page | Sign up / Sign in buttons |
| `LoginView.swift` | Login screen | Email + Google Sign-In |
| `SignUpView.swift` | Sign up screen | Email registration + Google |
| `ForgotPasswordView.swift` | Password reset | Email-based reset |

### Documentation Files

| File | Purpose | Read When |
|------|---------|-----------|
| `SETUP_GUIDE.md` | Complete setup guide | Setting up Supabase & Google OAuth |
| `PACKAGE_DEPENDENCIES.md` | Package installation | Adding Swift packages to Xcode |
| `MIGRATION_COMPLETE.md` | Implementation summary | Understanding what was built |
| `FILE_STRUCTURE.md` | This file | Quick reference for file locations |

---

## 🔍 Finding Files in Xcode

### Method 1: Project Navigator
1. Show Project Navigator (⌘1)
2. Navigate folder structure shown above

### Method 2: Quick Open
1. Press ⌘⇧O (Cmd+Shift+O)
2. Type filename (e.g., "AuthService")
3. Press Enter

### Method 3: Find in Project
1. Press ⌘⇧F (Cmd+Shift+F)
2. Search for filename or code

---

## 📊 Files by Category

### Must Configure Before Running
```
oneshot/Config/Environment.swift          ← Add your credentials
oneshot/oneshot.xcodeproj                 ← Add Swift packages
Info.plist                                 ← Add URL schemes & permissions
```

### Database Setup (Run in Supabase)
```
Database/Migrations/001_initial_schema.sql
Database/Migrations/002_row_level_security.sql
Database/Migrations/003_storage_policies.sql
```

### Ready to Use (No Changes Needed)
```
oneshot/Config/SupabaseConfig.swift
oneshot/Services/*.swift (all service files)
oneshot/Authentication/*.swift (all auth views)
```

### Need Integration (Your Work)
```
oneshot/AppState.swift                    ← Replace mock data with services
oneshot/oneshotApp.swift                  ← Add authentication flow
oneshot/Onboarding/*.swift                ← Save to database
oneshot/Discover/DiscoverView.swift       ← Load from API
oneshot/Matches/MatchesView.swift         ← Load from API
oneshot/Chat/ChatView.swift               ← Load/send messages
oneshot/Duo/DuoManagementView.swift       ← Handle invites via API
oneshot/Profile/ProfileView.swift         ← Load profile from API
```

---

## 🔄 Common File Patterns

### Accessing Services
```swift
// In any view
@EnvironmentObject var services: ServiceContainer

// Or access directly
let services = ServiceContainer.shared
```

### Service Usage Pattern
```swift
Task {
    do {
        let result = try await services.userService.getUser(id: userId)
        // Handle success
    } catch {
        // Handle error
        errorMessage = error.localizedDescription
    }
}
```

### Database DTO Pattern
```swift
// Services use DTOs (Data Transfer Objects) internally
struct UserDTO: Codable {
    let id: UUID
    let firstName: String
    // ... maps to database columns
}

// Then converts to your Models
return User(
    id: dto.id,
    firstName: dto.firstName,
    // ...
)
```

---

## 🎯 Integration Checklist

Use this to track which files you've integrated:

### Configuration
- [ ] `Environment.swift` - Added credentials
- [ ] Swift Packages - Installed in Xcode
- [ ] `Info.plist` - Added URL schemes
- [ ] Bundle ID - Updated to match Google OAuth

### Database
- [ ] Ran `001_initial_schema.sql`
- [ ] Ran `002_row_level_security.sql`
- [ ] Created storage bucket
- [ ] Ran `003_storage_policies.sql`

### App Integration
- [ ] `oneshotApp.swift` - Added auth flow
- [ ] `AppState.swift` - Integrated services
- [ ] `OnboardingContainerView.swift` - Save to database
- [ ] `DiscoverView.swift` - Load pairs from API
- [ ] `MatchesView.swift` - Load matches from API
- [ ] `ChatView.swift` - Load/send messages
- [ ] `DuoManagementView.swift` - Handle invites
- [ ] `ProfileView.swift` - Load profile from API

---

## 💾 Backup Reminder

Before making changes, create a backup:

```bash
# In terminal, from project directory
git add .
git commit -m "Backup before Supabase integration"

# Or create a copy
cp -r oneshot oneshot_backup
```

---

## 📞 Quick Help

**Can't find a file?**
- Use Cmd+Shift+O and type the filename

**Want to see all service methods?**
- Open any Service file and use Cmd+Ctrl+J (jump to definition)

**Need to see database schema?**
- Open `001_initial_schema.sql`

**Forgot your credentials?**
- Supabase Dashboard → Settings → API

**Need setup steps?**
- Open `SETUP_GUIDE.md`

---

## 🎓 File Naming Conventions

- **Views:** End with `View.swift` (e.g., `LoginView.swift`)
- **Services:** End with `Service.swift` (e.g., `AuthService.swift`)
- **DTOs:** End with `DTO` (e.g., `UserDTO`)
- **Errors:** End with `Error` (e.g., `AuthError`)
- **Config:** Descriptive names (e.g., `SupabaseConfig.swift`)

---

This structure follows iOS best practices and makes the codebase maintainable and scalable. All files are logically organized and easy to navigate!
