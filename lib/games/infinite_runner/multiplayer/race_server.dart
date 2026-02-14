library;

// Conditional export:
// - On native platforms (Android, iOS, desktop) → real WebSocket server
//   that runs on dart:io / shelf.
// - On web → a no-op stub with the same public API so the code compiles and
//   the lobby can show a "hosting requires the native app" message.
export 'race_server_stub.dart' if (dart.library.io) 'race_server_io.dart';
