import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
  final String _baseUrl = 'newsapi.org';
  final String _endpoint = '/v2/everything';
  final String? _apiKey = dotenv.env['NEWS_API_KEY'];

  Future<List<Map<String, dynamic>>> fetchNews({String query = 'apple'}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key no configurada en .env');
    }

    final uri = Uri.https(_baseUrl, _endpoint, {
      'q': query.trim().isEmpty ? 'news' : query,
      'sortBy': 'popularity',
      'language': 'es',
      'apiKey': _apiKey,
    });

    try {
      final data = await _fetchWithRetry(uri);
      await _saveToCache(data); // Guardar cache
      return _sanitizeArticles(data);
    } catch (e) {
      // Si falla, intentar leer del cache
      final cached = await _loadFromCache();
      if (cached != null) {
        return _sanitizeArticles(cached);
      }
      rethrow;
    }
  }

  /// Lógica con reintentos exponenciales
  Future<Map<String, dynamic>> _fetchWithRetry(Uri uri) async {
    const maxRetries = 3;
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        final resp = await http.get(uri).timeout(const Duration(seconds: 8));

        if (resp.statusCode == 200) {
          return json.decode(resp.body);
        } else if (resp.statusCode == 429) {
          throw Exception('Límite de peticiones alcanzado (HTTP 429)');
        } else if (resp.statusCode == 401) {
          throw Exception('Error de autenticación (HTTP 401)');
        } else {
          throw Exception('Error HTTP ${resp.statusCode}');
        }
      } on TimeoutException {
        lastError = Exception('Timeout (intento ${attempt + 1})');
      } catch (e) {
        lastError = Exception('Fallo de red: $e');
      }

      attempt++;
      await Future.delayed(Duration(seconds: 1 << (attempt - 1))); // 1, 2, 4s
    }

    throw lastError ?? Exception('Error desconocido tras varios intentos');
  }

  /// Guardar JSON en cache
  Future<void> _saveToCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_news', json.encode(data));
    await prefs.setString('cached_at', DateTime.now().toIso8601String());
  }

  /// Leer JSON del cache si existe
  Future<Map<String, dynamic>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cached_news');
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }

  /// Limpieza y transformación
  List<Map<String, dynamic>> _sanitizeArticles(Map<String, dynamic> data) {
    if (data['articles'] == null || data['articles'].isEmpty) {
      throw Exception('No hay noticias disponibles');
    }

    final sanitized = (data['articles'] as List)
        .map((a) {
          String? imageUrl = a['urlToImage'];
          if (imageUrl != null) {
            if (imageUrl.startsWith('http://')) {
              final httpsVersion = imageUrl.replaceFirst('http://', 'https://');
              imageUrl =
                  'https://images.weserv.nl/?url=${Uri.encodeComponent(httpsVersion)}';
            }
          }
          return {
            'title': (a['title'] ?? '').toString().replaceAll(RegExp(r'<[^>]*>'), ''),
            'description': (a['description'] ?? '').toString().replaceAll(RegExp(r'<[^>]*>'), ''),
            'urlToImage': imageUrl,
            'url': a['url'],
          };
        })
        .toList();

    return sanitized;
  }
}
