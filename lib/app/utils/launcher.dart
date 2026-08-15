import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Safe URL launcher utility that handles PlatformException and other errors
/// gracefully on all platforms (iOS, Android, etc.).
class Launcher {
  /// Safely launch a URL. Returns true if successful.
  static Future<bool> launch(Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        return await launchUrl(uri, mode: mode);
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Launcher.launch failed: $e');
      return false;
    }
  }

  /// Open WhatsApp with a pre-filled message.
  /// [phone] should include country code (e.g. '923153507075').
  static Future<bool> openWhatsApp(String phone, String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    final success = await launch(uri, mode: LaunchMode.externalApplication);
    if (!success) {
      // Fallback to SMS
      final smsUri = Uri.parse('sms:+$phone?body=$encodedMessage');
      return await launch(smsUri);
    }
    return success;
  }

  /// Make a phone call.
  static Future<bool> makeCall(String phone) async {
    final uri = Uri.parse('tel:+$phone');
    return await launch(uri);
  }

  /// Send an email.
  static Future<bool> sendEmail(String email, {String? subject, String? body}) async {
    final params = <String, String>{};
    if (subject != null) params['subject'] = Uri.encodeComponent(subject);
    if (body != null) params['body'] = Uri.encodeComponent(body);
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final uri = Uri.parse('mailto:$email${query.isNotEmpty ? '?$query' : ''}');
    return await launch(uri);
  }
}
