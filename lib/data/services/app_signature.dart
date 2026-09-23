import 'package:flutter/services.dart';

/// Helper that reports the SHA-1 of the certificate that signed the
/// **installed** build.
///
/// This is the fingerprint Google Sign-In validates against the OAuth
/// "Android" client, so it is the number you must register in Firebase /
/// Google Cloud before Drive sign-in works on a given build:
///   • local `flutter run`            → debug keystore SHA-1
///   • `flutter build appbundle`      → your upload key SHA-1
///   • installed from Google Play     → **Play App Signing** SHA-1
///
/// Returns `null` on any platform other than Android or if the lookup fails.
class AppSignature {
  AppSignature._();

  static const MethodChannel _channel = MethodChannel('com.codynest.pos/signing');

  /// Cached value — the signature never changes for the lifetime of the app.
  static String? _cached;

  /// SHA-1 fingerprint of the running build (40 lowercase hex chars), or null.
  static Future<String?> get sha1 async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final value = await _channel.invokeMethod<String>('getSigningSha1');
      _cached = value;
      return value;
    } on PlatformException catch (_) {
      return null;
    } on MissingPluginException catch (_) {
      return null;
    }
  }
}
