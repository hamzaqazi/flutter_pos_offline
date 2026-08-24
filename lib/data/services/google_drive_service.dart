import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

/// Service for backing up / restoring app data to the user's own Google Drive.
///
/// The app signs the user into their Google account, keeps them signed in
/// across launches, and stores full JSON backups in a dedicated
/// "Codynest POS Backups" folder in their Drive. Only the newest
/// [maxDriveBackups] backups are kept — uploading a new one deletes the
/// oldest once the limit is exceeded.
///
/// Uses the `drive.file` scope, so the app can only see and manage the
/// backup files it created — it never gains access to the rest of the
/// user's Drive.
///
/// ─────────────────────────────────────────────────────────────────────
/// ⚠️ SETUP REQUIRED (one-time, in Google Cloud Console):
///   1. Open the Firebase/Google Cloud project used by this app and enable
///      the "Google Drive API".
///   2. Create OAuth 2.0 credentials:
///        • An "Android" client — package name `com.example.ad_shop_pos`
///          (or your real applicationId) + the app's SHA-1 signing
///          certificate fingerprint.
///        • A "Web application" client — copy its Client ID into
///          [kGoogleServerClientId] below.
///   3. Add the OAuth consent screen scopes and add test users (or publish).
/// Without this, sign-in will fail with a configuration error.
/// ─────────────────────────────────────────────────────────────────────
class GoogleDriveService {
  GoogleDriveService._();

  /// Web OAuth client ID from Google Cloud Console. Required on Android so
  /// Google Sign-In can mint access tokens for the Drive scope.
  /// Leave empty to fall back to the platform default (google-services.json).
  static const String kGoogleServerClientId =
      '21334425002-a7oubp20qt1kcpnlahmffrjrvfbm51v4.apps.googleusercontent.com';

  /// Drive scope: access only to files this app creates.
  static const String _driveScope =
      'https://www.googleapis.com/auth/drive.file';

  /// Name of the Drive folder that holds our backups.
  static const String _folderName = 'Codynest POS Backups';

  /// Max backups to retain in Drive. Oldest is deleted when exceeded.
  static const int maxDriveBackups = 2;

  // ─── Hive persistence ────────────────────────────────────────
  static const _box = 'settings';
  static const _keyDriveEnabled = 'driveBackup_enabled';
  static const _keyDriveEmail = 'driveBackup_email';
  static const _keyDriveName = 'driveBackup_name';
  static const _keyDrivePhoto = 'driveBackup_photo';
  static const _keyLastDriveBackup = 'driveBackup_lastBackup';

  static Box get _settings => Hive.box(_box);

  static bool _initialized = false;
  static GoogleSignInAccount? _account;

  // ─── State getters ───────────────────────────────────────────

  /// Whether the user opted in to also upload auto-backups to Drive.
  static bool get isEnabled =>
      _settings.get(_keyDriveEnabled, defaultValue: false) as bool;

  /// Whether a Google account is currently connected.
  static bool get isSignedIn => _account != null || accountEmail.isNotEmpty;

  /// Email of the connected account (persisted; available before init).
  static String get accountEmail =>
      _settings.get(_keyDriveEmail, defaultValue: '') as String;

  /// Display name of the connected account.
  static String get accountName =>
      _settings.get(_keyDriveName, defaultValue: '') as String;

  /// Photo URL of the connected account (may be empty).
  static String get accountPhoto =>
      _settings.get(_keyDrivePhoto, defaultValue: '') as String;

  /// ISO8601 of last successful Drive upload.
  static String get lastDriveBackupIso =>
      _settings.get(_keyLastDriveBackup, defaultValue: '') as String;

  static DateTime? get lastDriveBackupDate {
    final s = lastDriveBackupIso;
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String get lastDriveBackupAgo {
    final dt = lastDriveBackupDate;
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static Future<void> setEnabled(bool enabled) async {
    await _settings.put(_keyDriveEnabled, enabled);
  }

  // ─── Initialization & auth ───────────────────────────────────

  /// Initialize Google Sign-In and attempt a silent restore of a previous
  /// session so the user stays signed in across launches. Safe to call
  /// multiple times.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: kGoogleServerClientId.isEmpty
            ? null
            : kGoogleServerClientId,
      );

      GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _account = event.user;
            _persistAccount(event.user);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _account = null;
            _clearPersistedAccount();
          }
        },
        onError: (e) {
          debugPrint('⚠️ GoogleDrive auth event error: $e');
        },
      );

      // Silently restore the previous session (fires a sign-in event on success).
      await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('⚠️ GoogleDrive init failed: $e');
    }
  }

  /// Interactive sign-in. Returns true on success.
  static Future<bool> signIn() async {
    try {
      await ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        debugPrint('⚠️ GoogleDrive: authenticate() unsupported on platform');
        return false;
      }
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const [_driveScope],
      );
      _account = account;
      _persistAccount(account);
      // Ensure Drive scope is granted up front.
      final headers = await account.authorizationClient.authorizationHeaders(
        const [_driveScope],
        promptIfNecessary: true,
      );
      if (headers == null) {
        debugPrint('⚠️ GoogleDrive: Drive scope not granted');
        return false;
      }
      return true;
    } on GoogleSignInException catch (e) {
      debugPrint('⚠️ GoogleDrive sign-in error: ${e.code} ${e.description}');
      return false;
    } catch (e) {
      debugPrint('⚠️ GoogleDrive sign-in error: $e');
      return false;
    }
  }

  /// Sign out (keeps the Google account but disconnects this app session).
  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('⚠️ GoogleDrive sign-out error: $e');
    }
    _account = null;
    _clearPersistedAccount();
  }

  static void _persistAccount(GoogleSignInAccount account) {
    _settings.put(_keyDriveEmail, account.email);
    _settings.put(_keyDriveName, account.displayName ?? '');
    _settings.put(_keyDrivePhoto, account.photoUrl ?? '');
  }

  static void _clearPersistedAccount() {
    _settings.delete(_keyDriveEmail);
    _settings.delete(_keyDriveName);
    _settings.delete(_keyDrivePhoto);
  }

  // ─── Drive API plumbing ──────────────────────────────────────

  /// Build an authenticated Drive API client, or null if unavailable.
  static Future<drive.DriveApi?> _driveApi() async {
    await ensureInitialized();
    // Cold start: the account may not be restored yet even though a previous
    // session exists. Try a silent restore before giving up.
    if (_account == null && accountEmail.isNotEmpty) {
      try {
        await GoogleSignIn.instance.attemptLightweightAuthentication();
      } catch (_) {}
    }
    final account = _account;
    if (account == null) {
      debugPrint('⚠️ GoogleDrive: not signed in');
      return null;
    }
    final headers = await account.authorizationClient.authorizationHeaders(
      const [_driveScope],
      promptIfNecessary: true,
    );
    if (headers == null) {
      debugPrint('⚠️ GoogleDrive: authorization headers unavailable');
      return null;
    }
    return drive.DriveApi(_AuthClient(headers));
  }

  /// Find (or create) the backups folder, returning its Drive file ID.
  static Future<String?> _folderId(drive.DriveApi api) async {
    try {
      final existing = await api.files.list(
        q:
            "mimeType='application/vnd.google-apps.folder' "
            "and name='$_folderName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name)',
      );
      final files = existing.files ?? [];
      if (files.isNotEmpty) return files.first.id;

      final folder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await api.files.create(folder, $fields: 'id');
      return created.id;
    } catch (e) {
      debugPrint('⚠️ GoogleDrive folder error: $e');
      return null;
    }
  }

  // ─── Public operations ───────────────────────────────────────

  /// Upload a JSON backup to Drive. Keeps only [maxDriveBackups] newest
  /// backups, deleting the oldest when the limit is exceeded.
  /// Returns true on success.
  static Future<bool> uploadBackup(String jsonStr, {String? filename}) async {
    final api = await _driveApi();
    if (api == null) return false;
    try {
      final folderId = await _folderId(api);
      if (folderId == null) return false;

      final name =
          filename ??
          'cloud_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-').substring(0, 22)}.json';

      final bytes = utf8.encode(jsonStr);
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );
      final metadata = drive.File()
        ..name = name
        ..parents = [folderId];

      await api.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id,name,createdTime,size',
      );

      await _settings.put(
        _keyLastDriveBackup,
        DateTime.now().toIso8601String(),
      );

      await _pruneOldBackups(api, folderId);
      debugPrint('✅ Uploaded backup to Drive: $name');
      return true;
    } catch (e) {
      debugPrint('🔥 GoogleDrive upload failed: $e');
      return false;
    }
  }

  /// Delete the oldest backups beyond [maxDriveBackups].
  static Future<void> _pruneOldBackups(
    drive.DriveApi api,
    String folderId,
  ) async {
    try {
      final list = await api.files.list(
        q: "'$folderId' in parents and trashed=false and mimeType='application/json'",
        spaces: 'drive',
        orderBy: 'createdTime desc',
        $fields: 'files(id,name,createdTime)',
      );
      final files = list.files ?? [];
      if (files.length <= maxDriveBackups) return;
      for (var i = maxDriveBackups; i < files.length; i++) {
        final id = files[i].id;
        if (id == null) continue;
        try {
          await api.files.delete(id);
          debugPrint('🗑️ Deleted old Drive backup: ${files[i].name}');
        } catch (e) {
          debugPrint('⚠️ Failed to delete Drive backup: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ GoogleDrive prune failed: $e');
    }
  }

  /// List backups currently stored in Drive, newest first.
  static Future<List<DriveBackupInfo>> listBackups() async {
    final api = await _driveApi();
    if (api == null) return [];
    try {
      final folderId = await _folderId(api);
      if (folderId == null) return [];
      final list = await api.files.list(
        q: "'$folderId' in parents and trashed=false and mimeType='application/json'",
        spaces: 'drive',
        orderBy: 'createdTime desc',
        $fields: 'files(id,name,createdTime,size)',
      );
      return (list.files ?? [])
          .where((f) => f.id != null)
          .map(
            (f) => DriveBackupInfo(
              id: f.id!,
              name: f.name ?? 'backup.json',
              createdTime: f.createdTime,
              sizeBytes: int.tryParse(f.size ?? '') ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('⚠️ GoogleDrive list failed: $e');
      return [];
    }
  }

  /// Download and parse a backup's JSON content by Drive file ID.
  static Future<Map<String, dynamic>?> downloadBackup(String fileId) async {
    final api = await _driveApi();
    if (api == null) return null;
    try {
      final media =
          await api.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      final content = utf8.decode(bytes);
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data['app'] != 'ad_shop_pos') return null;
      return data;
    } catch (e) {
      debugPrint('⚠️ GoogleDrive download failed: $e');
      return null;
    }
  }

  /// Delete a backup from Drive by file ID.
  static Future<bool> deleteBackup(String fileId) async {
    final api = await _driveApi();
    if (api == null) return false;
    try {
      await api.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('⚠️ GoogleDrive delete failed: $e');
      return false;
    }
  }
}

/// Metadata about a backup stored in Google Drive.
class DriveBackupInfo {
  final String id;
  final String name;
  final DateTime? createdTime;
  final int sizeBytes;

  const DriveBackupInfo({
    required this.id,
    required this.name,
    required this.createdTime,
    required this.sizeBytes,
  });

  String get formattedDate {
    final dt = createdTime?.toLocal();
    if (dt == null) return 'Unknown';
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    final kb = (sizeBytes / 1024).round();
    if (kb < 1024) return '$kb KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

/// http.Client that injects Google auth headers on every request.
class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
