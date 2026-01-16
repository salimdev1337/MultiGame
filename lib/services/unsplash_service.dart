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
    // debug: 'UNSPLASH SERVICE: Getting random image'
    if (_cachedImageUrl != null && _cacheTime != null) {
      final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
      if (_cacheTime!.isAfter(hourAgo)) {
        // debug: 'Using cached image: $_cachedImageUrl'
        return _cachedImageUrl!;
      }
    }

    // debug: 'Fetching new image from Unsplash API...'
    try {
      final url = Uri.parse('$_baseUrl/photos/random').replace(
        queryParameters: {
          'query': 'tunisia landmark',
          'orientation': 'square',
          'client_id': ApiConfig.unsplashAccessKey,
        },
      );
      // debug: 'API URL: $url'
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['urls']['regular'];
        // debug: 'Successfully fetched image from Unsplash'
        // debug: 'Image URL: $imageUrl'

        _cachedImageUrl = imageUrl;
        _cacheTime = DateTime.now();

        return imageUrl;
      } else {
        // debug: 'Unsplash API error: ${response.statusCode}'
        throw Exception('Unsplash API error: ${response.statusCode}');
      }
    } catch (e) {
      // debug: 'Error fetching from Unsplash: $e'
      return _getFallbackImage();
    }
  }

  String _getFallbackImage() {
    // Using reliable placeholder image services
    final fallbackImages = [
      'https://picsum.photos/800/800?random=1',
      'https://picsum.photos/800/800?random=2',
      'https://picsum.photos/800/800/?random=3',
      'https://picsum.photos/800/800/?random=4',
    ];

    final randomIndex = DateTime.now().millisecond % fallbackImages.length;
    // debug: 'Using fallback image: ${fallbackImages[randomIndex]}'
    return fallbackImages[randomIndex];
  }

  void clearCache() {
    _cachedImageUrl = null;
    _cacheTime = null;
  }
}
