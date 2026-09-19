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
     (currently `com.codynest.pos` — see
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

- The `applicationId` is `com.codynest.pos` — it must be registered in the
  Android OAuth client together with every SHA-1 below.
- iOS additionally needs a `GoogleService-Info.plist` / URL scheme and an iOS
  OAuth client if you ship on iOS.
- Packages added: `google_sign_in ^7.2`, `googleapis ^16`, `googleapis_auth`,
  `http`.

## ⚠️ Release builds installed from Google Play (most common failure)

Google re-signs your app with the **Play App Signing** key when you upload an
AAB. That key's SHA-1 is *different* from your upload key and from the debug
key, so a build that signs in perfectly in debug fails with a configuration
error once installed from Play.

Register **all three** SHA-1s on the Android app in Firebase
(Project settings → Your apps → Android app → SHA certificate fingerprints),
then re-download `google-services.json` into `android/app/`:

| Key | Where to find the SHA-1 |
|---|---|
| Debug | `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |
| Upload (your `codynest-upload.jks`) | `keytool -list -v -keystore ~/codynest-upload.jks -alias upload` |
| **Play App Signing** | Play Console → *Codynest POS* → Setup → App integrity → App signing key certificate → **SHA-1** |

Check what's currently registered:

```bash
python3 -c "import json;d=json.load(open('android/app/google-services.json'));\
[print(c['client_info']['android_client_info'].get('package_name'),\
 [o.get('android_info',{}).get('certificate_hash') for o in c.get('oauth_client',[])]) for c in d['client']]"
```

### Error → cause

The app now shows the exact Google error under **Settings → Data & Backup →
Google Drive Backup** (selectable text, no logcat needed).

| Error | Cause | Fix |
|---|---|---|
| `ApiException: 10` / `providerConfigurationError` | SHA-1 or package name not registered for the signing key actually used | add the **Play App Signing** SHA-1, re-download `google-services.json`, rebuild |
| `ApiException: 12500` | same as above, or missing support email on the consent screen | add fingerprints + fill in the consent screen |
| `access_denied` / `403` | consent screen in **Testing** and the account isn't a test user, or Drive API disabled | add the account under OAuth consent screen → *Audience → Test users*; enable **Google Drive API** |
| `App not verified` | `drive.file` is a *sensitive* scope | keep the app in Testing with your testers listed, or submit for verification |
| `network_error` / `ApiException: 7` | connectivity or Play Services outdated | retry on a working network |

### Checklist before testing a Play build

- [ ] Drive API enabled in project `my-portfolio-78ae4`
- [ ] OAuth consent screen: scope `.../auth/drive.file` present, support email set
- [ ] Every tester's Google account listed as a **test user** (while unpublished)
- [ ] Debug + upload + **Play App Signing** SHA-1s registered in Firebase
- [ ] `android/app/google-services.json` re-downloaded after adding them
- [ ] Web client ID in `kGoogleServerClientId` matches the project
