import '../services/api_exception.dart';

/// Centralized error message sanitizer.
/// Prevents raw exception strings (ApiException, SocketException, etc.)
/// from leaking to the user UI.
///
/// Usage:
///   catch (e) {
///     AppToast.error(context, ErrorSanitizer.message(e, fallback: l10n.signInFailed));
///   }
class ErrorSanitizer {
  ErrorSanitizer._();

  /// Extracts a clean, user-friendly message from any exception.
  ///
  /// For [ApiException]: returns the inner [message] field (already human-readable
  /// from the backend). For everything else: returns [fallback].
  ///
  /// If [fallback] is not provided, returns a generic "Something went wrong" string.
  static String message(Object error, {String? fallback}) {
    final defaultMsg = fallback ?? 'Something went wrong. Please try again.';

    if (error is ApiException) {
      // The ApiException.message field contains the backend's human-readable
      // message (e.g. "Email already exists", "Invalid code").
      // Only use it if it doesn't look like a raw technical string.
      final msg = error.message;
      if (_isTechnical(msg)) {
        return defaultMsg;
      }
      return msg;
    }

    // For all other exceptions (SocketException, PlatformException, etc.)
    // never show the raw toString() — use the fallback.
    return defaultMsg;
  }

  /// Checks if a message looks like a raw technical/exception string
  /// that should never be shown to users.
  static bool _isTechnical(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('platformexception') ||
        lower.contains('connection refused') ||
        lower.contains('os error') ||
        lower.contains('errno') ||
        lower.contains('stack trace') ||
        lower.startsWith('error:') ||
        lower.contains('null check') ||
        lower.contains('type \'') ||
        lower.contains('nosuchmethoderror');
  }
}
