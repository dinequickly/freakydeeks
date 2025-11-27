# OneShot iOS App - Setup Guide

## 🚀 Getting Started

This guide will walk you through setting up the OneShot iOS app with Supabase backend.

## Prerequisites

- Xcode 15.0+ (macOS Sonoma or later)
- iOS 17.0+ deployment target
- Supabase account (free tier works)
- Google Cloud account (for Google Sign-In)

## Step 1: Database Setup

### 1.1 Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Fill in details:
   - **Name:** OneShot
   - **Database Password:** (generate strong password and save it)
   - **Region:** Choose closest to your target users
4. Wait ~2 minutes for project creation

### 1.2 Run Database Migrations
1. In Supabase Dashboard, go to **SQL Editor**
2. Click "New Query"
3. Open `Database/Migrations/001_initial_schema.sql` from this repo
4. Copy and paste the entire contents
5. Click **Run** (or Cmd+Enter)
6. Verify success (should see "Success. No rows returned")
7. Repeat for `002_row_level_security.sql`

### 1.3 Set Up Storage
1. Go to **Storage** in Supabase Dashboard
2. Click **New bucket**
3. Enter bucket name: `user-photos`
4. Set to **PUBLIC** (important!)
5. Click **Create**
6. Go back to **SQL Editor**
7. Run `Database/Migrations/003_storage_policies.sql`

### 1.4 Configure Authentication

#### Email/Password (Already enabled by default)
1. Go to **Authentication → Providers**
2. Verify **Email** is enabled
3. Optionally customize email templates:
   - Authentication → Email Templates
   - Customize Confirm Signup, Reset Password, etc.

#### Google Sign-In
1. In Supabase Dashboard: **Authentication → Providers**
2. Find **Google** and click to expand
3. Enable the toggle
4. You'll need to provide:
   - Google Client ID
   - Google Client Secret

To get these credentials:

**Create Google OAuth Credentials:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project or select existing
3. Go to **APIs & Services → Credentials**
4. Click **+ CREATE CREDENTIALS → OAuth client ID**
5. Select **iOS** as application type
6. Fill in:
   - **Name:** OneShot iOS
   - **Bundle ID:** `com.yourcompany.oneshot` (must match your Xcode bundle ID)
7. Click **Create**
8. Also create a **Web application** OAuth client:
   - Name: OneShot Web
   - Authorized redirect URIs:
     - `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
     (replace YOUR_PROJECT_REF with your Supabase project reference)
9. Copy the **Client ID** and **Client Secret** from Web client
10. Paste into Supabase Google provider settings
11. Save

### 1.5 Save Your Credentials
Go to **Settings → API** and copy:
- **Project URL:** `https://xxxxx.supabase.co`
- **anon/public key:** Long string starting with `eyJ...`

Keep these safe - you'll need them next!

## Step 2: iOS App Setup

### 2.1 Add Swift Package Dependencies

1. Open `oneshot.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies**
3. Add the following packages:

**Supabase Swift SDK:**
```
https://github.com/supabase/supabase-swift
```
- Version: Latest (2.0.0+)
- Add to target: `oneshot`

**Google Sign-In:**
```
https://github.com/google/GoogleSignIn-iOS
```
- Version: Latest (7.0.0+)
- Add to target: `oneshot`

**Kingfisher (for image loading):**
```
https://github.com/onevcat/Kingfisher
```
- Version: Latest (7.0.0+)
- Add to target: `oneshot`

4. Wait for packages to resolve and download

### 2.2 Configure Environment Variables

1. Open `oneshot/oneshot/Config/Environment.swift`
2. Replace placeholder values:

```swift
static let supabaseURL = "https://YOUR_PROJECT_REF.supabase.co"
static let supabaseAnonKey = "YOUR_ANON_KEY_HERE"
static let googleClientID = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
```

**Finding Google Client ID:**
- Use the iOS OAuth client ID from Google Cloud Console
- Format: `123456789-abc123.apps.googleusercontent.com`

**Finding Reversed Client ID:**
- Take your iOS Client ID
- Reverse it: `com.googleusercontent.apps.123456789-abc123`

### 2.3 Configure URL Schemes

1. In Xcode, select your project in Navigator
2. Select the **oneshot** target
3. Go to **Info** tab
4. Expand **URL Types**
5. Add two URL schemes:

**Scheme 1: App Deep Linking**
- **Identifier:** `com.yourcompany.oneshot`
- **URL Schemes:** `oneshot`
- **Role:** Editor

**Scheme 2: Google Sign-In**
- **Identifier:** `com.google.oauth`
- **URL Schemes:** `YOUR_REVERSED_CLIENT_ID`
  (e.g., `com.googleusercontent.apps.123456789-abc123`)
- **Role:** Editor

### 2.4 Update Info.plist

1. Open `Info.plist` as source code (right-click → Open As → Source Code)
2. Add before `</dict>`:

```xml
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>oneshot</string>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos to upload profile pictures</string>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take profile pictures</string>
```

### 2.5 Update Bundle Identifier

1. In Xcode, select your project
2. Select **oneshot** target
3. Go to **Signing & Capabilities**
4. Set **Bundle Identifier** to match what you used in Google Cloud
   - Example: `com.yourcompany.oneshot`
5. Select your **Team**
6. Enable **Automatically manage signing**

## Step 3: Verify Setup

### 3.1 Build the Project
1. Select a simulator or device
2. Press **Cmd+B** to build
3. Verify no build errors

### 3.2 Test Database Connection
The app will validate configuration on launch. Check the Xcode console for:
```
✅ Supabase client initialized
```

If you see warnings about Environment.swift not being configured, go back to Step 2.2.

## Step 4: First Run

### 4.1 Create Test User (Optional)
Before running the app, create a test user in Supabase:

1. Go to **Authentication → Users** in Supabase Dashboard
2. Click **Add user**
3. Choose **Create new user**
4. Enter:
   - Email: test@example.com
   - Password: Test123456!
   - Email Confirm: Yes
5. Click **Create user**

### 4.2 Run the App
1. Press **Cmd+R** to run
2. App should open to Login/Signup screen
3. Try creating account or logging in

## Troubleshooting

### Build Errors

**"No such module 'Supabase'"**
- Go to File → Packages → Resolve Package Versions
- Clean build folder (Cmd+Shift+K)
- Rebuild (Cmd+B)

**"Could not find module 'GoogleSignIn'"**
- Same as above
- Verify package was added to target

### Runtime Errors

**"Invalid Supabase URL"**
- Check Environment.swift has correct URL
- URL should start with https://
- No trailing slash

**"Network request failed"**
- Check internet connection
- Verify Supabase project is running (not paused)
- Check project URL is correct

**Google Sign-In not working**
- Verify URL scheme matches reversed client ID exactly
- Check Info.plist has GIDClientID
- Verify OAuth client is iOS type in Google Cloud
- Check bundle ID matches Google Cloud configuration

### Database Issues

**"Row Level Security policy violation"**
- Verify you ran 002_row_level_security.sql
- Check policies in Supabase Dashboard → Authentication → Policies

**"Photos not uploading"**
- Verify storage bucket exists and is named "user-photos"
- Check bucket is set to PUBLIC
- Verify 003_storage_policies.sql was run

## Next Steps

1. **Test the onboarding flow** - Create new account and complete profile
2. **Test duo creation** - Invite another test user (create second user in Supabase)
3. **Test discovery** - Add test data to see swiping work
4. **Test matching** - Have two duos swipe right on each other
5. **Test chat** - Send messages between matched duos

## Adding Test Data

Want to test the discovery feature? Add sample duos:

1. Go to **SQL Editor** in Supabase
2. Run this query to create test users and pairs:

```sql
-- See Database/test_data.sql for sample data insertion queries
```

## Development Tips

- Use **Table Editor** in Supabase to view/edit data
- Use **Database → Logs** to see queries
- Use **Authentication → Users** to manage test users
- Enable **Auth → Settings → Email Auth → Confirm email** to skip email verification during testing

## Production Checklist

Before launching:
- [ ] Change database password
- [ ] Enable email confirmation
- [ ] Set up custom email templates
- [ ] Configure rate limiting
- [ ] Set up monitoring/alerts
- [ ] Review and test all RLS policies
- [ ] Set up proper error logging
- [ ] Configure backup strategy
- [ ] Set up staging environment
- [ ] Test with real devices (not just simulator)

## Support

- **Supabase Docs:** https://supabase.com/docs
- **Supabase Discord:** https://discord.supabase.com
- **Google Sign-In Docs:** https://developers.google.com/identity/sign-in/ios

## Security Notes

⚠️ **IMPORTANT:** Never commit `Environment.swift` with real credentials to a public repository!

- Add `Config/Environment.swift` to `.gitignore`
- Use environment variables for CI/CD
- Rotate keys if accidentally exposed
- Use separate projects for dev/staging/production
