# Codynest POS — Google Play Release Guide

Step-by-step, in the order you actually have to do it. Sections 0–1 are the things that
will get you **rejected or blocked**; sections 2–6 are the Play Console clicks.

---

## 0. What you're signing up for (2026 rules, current as of today)

| Requirement | Current rule |
|---|---|
| Developer account fee | $25 USD one-time ([register](https://play.google.com/console/signup)) |
| Target API level | **Android 16 (API 36)** for all new apps — enforced since **31 Aug 2026**. API 35 is no longer accepted for new submissions. |
| Format | **Android App Bundle (.aab)** — APKs are not accepted for new apps |
| 64-bit | `arm64-v8a` must be included (Flutter does this by default ✅) |
| New personal accounts | If your Play Console account was created **after 13 Nov 2023**, you must run a **closed test with ≥12 opted-in testers for 14 consecutive days** before you can even apply for production access. Organisation accounts and older personal accounts are exempt. |
| Developer verification | Google is rolling out mandatory developer identity verification (started 30 Sep 2026 in BR/ID/SG/TH). Make sure your Play Console account details + ID verification are complete so you're not caught out. |
| Realistic timeline | 1 day to build → 1 day of Play Console forms → **14 days closed testing (if applicable)** → 1–7 days review → live |

---

## 1. Fix these in the repo BEFORE you build

### 1.1 Application ID — `com.example.*` is on Play's restricted list ⛔

`android/app/build.gradle.kts` currently has:

```kotlin
namespace = "com.example.ad_shop_pos"
applicationId = "com.example.ad_shop_pos"
```

Change both to your real, permanent ID (**you can never change it after publishing** — it
becomes your Play URL). Suggested: `com.codynest.pos`

```kotlin
namespace = "com.codynest.pos"
applicationId = "com.codynest.pos"
```

Then also:
```bash
# rename the Kotlin package folder to match
mv android/app/src/main/kotlin/com/example/ad_shop_pos android/app/src/main/kotlin/com/codynest
mv android/app/src/main/kotlin/com/codynest/ad_shop_pos android/app/src/main/kotlin/com/codynest/pos
# fix the package declaration inside MainActivity.kt
```
`MainActivity.kt` lives in that folder — its `package com.example.ad_shop_pos` line must become
`package com.codynest.pos`.

**Firebase follow-up (easy to forget, breaks Drive backup):**
1. Firebase console → Project settings → Your apps → Android app → change package name to `com.codynest.pos`.
2. Re-download `google-services.json` → replace `android/app/google-services.json`.
3. After your first upload to Play, Play re-signs the app (Play App Signing). Copy the **SHA-1**
   from *Play Console → Setup → App integrity* and add it to Firebase (Project settings →
   SHA certificate fingerprints). Without it, **Google Sign-In / Drive backup fails for every
   user who installs from Play**.

### 1.2 Signing — you're currently shipping a debug key ⛔

`build.gradle.kts` has `signingConfig = signingConfigs.getByName("debug")` in the release block.
Play rejects debug-signed bundles, and a debug key can't be used for updates.

```bash
# run once, from the android/ folder (Windows: use a path like C:\Users\you\upload-keystore.jks)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (this exact file — it is git-ignored, so only
the committed template `android/key.properties.example` travels with the repo):
```properties
storeFile=codynest-upload.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```
`storeFile` may be a bare filename or an absolute path — the build looks for the
keystore in `android/app/`, `android/`, the repo root and your home folder, so
`codynest-upload.jks` works no matter where you dropped it.

Add to `android/app/build.gradle.kts` (above `android { }`):
```kotlin
val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
```
…and inside `android { }`:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = false
        isShrinkResources = false
    }
}
```

Add to `.gitignore` (never commit these):
```
key.properties
**/*.jks
**/*.keystore
```
**Back up `upload-keystore.jks` + passwords in a password manager.** Lose it and you can
never publish another update for this app.

### 1.3 Target SDK 36

Set it explicitly instead of relying on the Flutter default:
```kotlin
compileSdk = 36
defaultConfig {
    targetSdk = 36
    minSdk = 24          // or flutter.minSdkVersion
}
```
Install *Android SDK Platform 36* in Android Studio → SDK Manager first.

### 1.4 Clean up permissions (`android/app/src/main/AndroidManifest.xml`)

Current file requests `ACCESS_FINE_LOCATION` + `BLUETOOTH_SCAN`. On Android 12+ you only need
location if you derive location from BLE — you pair a thermal printer, you don't. Play flags
unused location permissions and can reject them.

```xml
<uses-permission android:name="android.permission.CAMERA" />
<!-- legacy BT, only needed up to Android 11 -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<!-- Android 12+: declare we never derive location from scans -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.INTERNET" />
<!-- remove ACCESS_FINE_LOCATION entirely -->

<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```
`required="false"` matters for POS tablets without a camera — otherwise Play hides your app
from them. Also drop `Permission.location` from the runtime request list in
`lib/modules/settings/settings_page.dart` (~line 1726).

### 1.5 Reviewer access — the #1 silent killer for this app ⛔

`lib/main.dart` → if not activated the user is pushed to `ActivationScreen`, and
`_isValidPakistaniPhone()` only accepts Pakistani numbers. A Play reviewer (usually outside PK)
can enter the app, see the activation wall, be told their number is invalid, and **never reach
the POS features** → rejected as "not functional / restricted access".

Do at least two of these:
- **Relax validation** to any 8–15 digit phone (or make phone optional for the trial).
- **Add a demo/reviewer escape hatch**: a small "Explore demo data" link on the activation
  screen that launches the app with sample products and no license.
- **Reviewer notes**: give them a working license key + exact steps.

### 1.6 Privacy policy — required, and currently missing ⛔

There is no privacy policy link anywhere in the app (`grep -i privacy lib/` → nothing).
Play requires the URL in the store listing, and Google also expects it **inside the app**.

1. Publish it at `https://codynest.com/privacy-policy` (mention: offline-first local storage,
   camera use for product photos/barcodes, Bluetooth for receipt printers, Google Drive backup
   stored in the user's own Drive, device ID + license key stored in Firebase for licensing,
   no ads, no data selling, how to request deletion, contact email).
2. Add an "About & Privacy" tile in Settings that opens it with `url_launcher`

    (you already use `url_launcher` and have a `lib/app/widgets/premium_gate.dart` pattern
    for WhatsApp links you can copy).

### 1.7 Auto-backup path will silently fail on Android 11+ (bug, not policy)

`lib/data/services/auto_backup_service.dart` writes to
`/storage/emulated/0/Documents/Codynest POS/Backups`. With targetSdk 36 that write is blocked
(scoped storage) — backups will fail on every modern device, and reviewers/testers may report
"backup doesn't work".

Fix before launch: use `getExternalStorageDirectory()` + `Android/` app-specific dir, or export
through SAF (`file_picker`'s `saveFile`) like the Drive download flow already does.

### 1.8 Data Safety + account deletion

Your app has **no user accounts** (license key + device trial), so the "account deletion"
requirement doesn't bite — but you must still fill the Data Safety form honestly:

| Data type | Answer |
|---|---|
| Device or other IDs (device ID for licensing/trial) | Collected → transmitted in transit → **processed ephemerally** / not shared with third parties |
| App info & performance | Not collected (you have no Analytics/Crashlytics) |
| Photos (product images) | Collected → stored **on device only**, not sent to servers |
| Files (backups) | Only if the user backs up; goes to **the user's own Google Drive** |
| Location, contacts, SMS, financial info | Not collected |

Add a **"Delete all my data"** action in Settings (the app already has
`ImportService._clearAllData()` you can reuse) and say so in the privacy policy.

---

## 2. Build and verify the release bundle

```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons      # regenerate launcher icons from lib/assets/images/CN_POS_LOGO.png
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Verify before uploading (needs Android SDK build-tools):
```bash
# target SDK must be 36
$ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer manifest target-sdk \
  build/app/outputs/bundle/release/app-release.aab
# no debuggable flag, correct package, 64-bit present
$ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer manifest application-id \
  build/app/outputs/bundle/release/app-release.aab
```

Update the version in `pubspec.yaml` before each upload (`version: 1.0.0+2` → versionCode 2).
Version codes must strictly increase, forever.

---

## 3. Create the app in Play Console

1. [Play Console](https://play.google.com/console) → **Create app**
   - App name: `Codynest POS` (≤30 chars ✅)
   - Default language: English (US), App or game: **App**, Free or paid: **Free**
   - Category: **Business**, Tags: Point of Sale / Inventory
2. Accept the developer agreement, complete the **verification** steps (email, phone, ID if asked).
3. Complete every card under **Policy → App content** — the app cannot be reviewed until all are green:
   - **Data safety** → fill per 1.8; add the privacy policy URL
   - **App access** → *"All functionality is available without special access"* → if you keep
     the activation gate, declare it and give the demo credentials/notes here
   - **Ads** → "My app contains no ads"
   - **Content rating** → complete the IARC questionnaire (no violence/sex; you'll get Everyone / 3+)
   - **Target audience** → **18+ is not required**; select "Not targeted to children"; if you pick
     13–15/16–17 you inherit extra rules — simplest is 18+ or "all audiences" with no kids targeting
   - **Government apps / Financial features** → "No" (you're a billing tool, not lending/banking)
   - **Health / VPN / etc.** → No
   - **News, COVID, Made for Kids** → No

---

## 4. Store listing (Main store listing page)

Prepare these assets first:

| Asset | Spec | Notes |
|---|---|---|
| App icon | 512×512 PNG, 32-bit, no alpha issues | already generated by `flutter_launcher_icons` |
| Feature graphic | **1024×500** PNG/JPEG | required — put it at the top of the listing |
| Phone screenshots | **min 2**, recommend 5–6; 16:9 or 9:16, 320–3840 px | Dashboard, Products, Cart/checkout, Invoice preview, Settings/backup |
| Tablet screenshots (7″/10″) | optional but recommended for a POS app | most POS users are on tablets |
| Short description | ≤ 80 chars | e.g. "Offline POS, inventory & invoicing for small shops" |
| Full description | ≤ 4000 chars | feature bullets, offline-first, thermal printing, Drive backup, no keyword stuffing |
| Website / email / phone | required contact details | add `https://codynest.com` + support email |
| Store settings → App category | Business | |

Screenshot tip: use a clean demo shop dataset — no real customers' phone numbers, no real invoices.

---

## 5. Testing tracks → production

1. **Internal testing** (optional, instant): Testing → Internal testing → Create new release →
   upload the `.aab` → add your own Gmail as tester → install and smoke-test via the opt-in link.
   *Do this first — it catches signing/Play-App-Signing problems in 10 minutes.*
2. **Closed testing** (mandatory for new personal accounts):
   - Testing → Closed testing → Create track → upload `.aab` → add ≥12 tester emails
     (use a Google Group with **15–20** people as a buffer against dropouts).
   - Every tester must open the opt-in link, tap **Become a tester**, and install from that
     same Google account. Invited-but-not-installed does not count.
   - Keep ≥12 opted in for **14 consecutive days**. The clock starts once the release is
     approved *and* the 12th tester opts in.
   - Meanwhile: fix whatever they report, upload a new bundle to the same track (does **not**
     reset the 14 days).
3. After 14 days: **Publishing overview → Production → Request production access** → fill the
   3-part application (describe your closed test honestly: how you recruited testers, what
   feedback you got, what you fixed). Stated review time: usually ≤ 7 days.
4. Once granted: Production → Create new release → upload the final `.aab`, add release notes,
   choose rollout (start at 20% staged rollout for a day, then 100%) → **Send for review**.

---

## 6. After you go live

- **Add Play's SHA-1 to Firebase** (Setup → App integrity in Play Console) or Google Sign-In /
  Drive backup will fail for all Play installs.
- Watch **Android vitals** for ANRs/crashes for the first 48h — a spike can get you suspended.
- Every update: bump `versionCode` in `pubspec.yaml`, rebuild `.aab`, upload to production.
- Keep the privacy policy and Data Safety form in sync with whatever you ship.

---

## Appendix — pre-submission checklist (from your audit skill, condensed)

- [ ] `applicationId` is real (not `com.example.*`) and matches Firebase
- [ ] Signed with your own upload key, keystore backed up, not in git
- [ ] `targetSdk = 36`, `compileSdk = 36`, built as `.aab`
- [ ] Location permission removed, `neverForLocation` set, camera `required="false"`
- [ ] Reviewer can use the app without a license / Pakistani phone (demo mode or notes)
- [ ] Privacy policy URL live **and** linked inside the app
- [ ] Data Safety form filled, "Delete my data" available in Settings
- [ ] Auto-backup path fixed for scoped storage
- [ ] Feature graphic 1024×500 + ≥2 real screenshots (no fake data / no real customer data)
- [ ] App content declarations all completed (Play shows a green tick per card)
- [ ] Closed test running with 12+ testers (if your account requires it)
- [ ] Firebase SHA-1 from Play App Signing added
