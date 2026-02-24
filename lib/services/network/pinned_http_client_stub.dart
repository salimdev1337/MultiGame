import 'package:http/http.dart' as http;

// Web / unsupported platform — SSL pinning is handled by the browser.
http.Client createPinnedHttpClient() => http.Client();
