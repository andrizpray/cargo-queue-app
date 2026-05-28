/// Simple logging utility for the app
class AppLogger {
  static const String _tag = 'CargoQueue';

  static void info(String message) {
    // In production, this would use a proper logging framework
    // For now, we suppress the print warning with a comment
    // ignore: avoid_print
    print('[$_tag] INFO: $message');
  }

  static void error(String message, [dynamic error]) {
    // ignore: avoid_print
    print('[$_tag] ERROR: $message${error != null ? ' - $error' : ''}');
  }

  static void debug(String message) {
    // ignore: avoid_print
    print('[$_tag] DEBUG: $message');
  }
}
