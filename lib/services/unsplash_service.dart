import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:puzzle/config/api_config.dart';

class UnsplashService {
  static const String _baseUrl = 'https://api.unsplash.com';

  // Cache to store images and reduce API calls
  static String? _cachedImageUrl;
  static DateTime? _cacheTime;

  // Get a random Tunisian image
  Future<String> getRandomTunisianImage() async {
    if (_cachedImageUrl != null && _cacheTime != null) {
      final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
      if (_cacheTime!.isAfter(hourAgo)) {
        return _cachedImageUrl!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/photos/random'
          '?query=tunisia+landmark+architecture'
          '&orientation=square'
          '&client_id=${ApiConfig.unsplashAccessKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['urls']['regular'];

        _cachedImageUrl = imageUrl;
        _cacheTime = DateTime.now();

        return imageUrl;
      } else {
        throw Exception('Unsplash API error: ${response.statusCode}');
      }
    } catch (e) {
      return _getFallbackImage();
    }
  }

  String _getFallbackImage() {
    return 'assets/images/fallback_puzzle.jpg';
  }

  void clearCache() {
    _cachedImageUrl = null;
    _cacheTime = null;
  }
}
