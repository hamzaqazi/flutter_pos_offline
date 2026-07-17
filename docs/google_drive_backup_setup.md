# Google Drive Backup — Setup Guide

The app can back up and restore data to the user's **own Google Drive** account.
The code is complete, but Google Drive access requires a one-time setup in the
Google Cloud Console before sign-in will work. Until this is done, the
"Sign in with Google" button will fail with a configuration error.

## What the feature does

- **Settings → Google Drive Backup**: sign in with a Google account. The app
  stays signed in across launches (silent re-auth on startup).
- **Upload auto-backups to Drive** toggle: when on, every scheduled auto-backup
  is also uploaded to Drive.
- **Back up to Drive now**: uploads a fresh backup immediately.
- **Restore from Drive**: lists cloud backups and restores a chosen one
  (replaces all current data, same as local restore).
- Only the **2 most recent** backups are kept in Drive. Uploading a 3rd deletes
  the oldest automatically.
- Backups live in a **"Codynest POS Backups"** folder in the user's Drive.
  The app uses the `drive.file` scope, so it can only see files it created — it
  never gains access to the rest of the user's Drive.

## Required one-time setup

1. **Enable the Drive API**
   - Go to <https://console.cloud.google.com> → select the project that owns
     `android/app/google-services.json` (currently `my-portfolio-78ae4` — use
     your real production project).
   - APIs & Services → Library → enable **Google Drive API**.

2. **Configure the OAuth consent screen**
   - APIs & Services → OAuth consent screen.
   - Add the scope `.../auth/drive.file`.
   - While in "Testing", add each Google account that will sign in as a test
     user, or publish the app for production.

3. **Create OAuth 2.0 credentials**
   - APIs & Services → Credentials → Create Credentials → OAuth client ID.
   - **Android client**: package name = your `applicationId`
     (currently `com.example.ad_shop_pos` — see
     `android/app/build.gradle.kts`), plus the SHA-1 of your signing key:
     ```
     # debug key
     keytool -list -v -keystore ~/.android/debug.keystore \
       -alias androiddebugkey -storepass android -keypass android
     ```
     Use the release keystore's SHA-1 for release builds too.
   - **Web application client**: create one, then copy its **Client ID** into
     `kGoogleServerClientId` in
     `lib/data/services/google_drive_service.dart`. This is required on Android
     so Google Sign-In can mint access tokens for the Drive scope.

4. **Refresh `google-services.json` (recommended)**
   - After creating the OAuth clients, re-download `google-services.json` from
     Firebase and replace `android/app/google-services.json`.

## Notes

- The current `applicationId` is the placeholder `com.example.ad_shop_pos`.
  If you change it to a real ID, register that package name in the Android
  OAuth client too.
- iOS additionally needs a `GoogleService-Info.plist` / URL scheme and an iOS
  OAuth client if you ship on iOS.
- Packages added: `google_sign_in ^7.2`, `googleapis ^16`, `googleapis_auth`,
  `http`.
