import 'package:flutter/material.dart';
import 'package:apinews/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _service = NewsService();
  final _queryController = TextEditingController();
  final _cityController = TextEditingController();
  List<Map<String, dynamic>> _articles = [];
  bool _loading = false;
  String? _error;

  Future<void> _loadNews() async {
    final query = _queryController.text.trim();
    final city = _cityController.text.trim();

    if (query.isEmpty && city.isEmpty) {
      setState(() => _error = 'Por favor ingresa un tema o ciudad para buscar.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final searchTerm = [query, city].where((e) => e.isNotEmpty).join(' ');
      final data = await _service.fetchNews(query: searchTerm);
      setState(() => _articles = data);
    } catch (e) {
      setState(() => _error = 'Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('📰 Últimas Noticias'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔍 Campo de tema
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Buscar tema (ej. tecnología, fútbol, salud...)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // 🏙️ Campo de ciudad
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Buscar por ciudad (ej. México, Madrid, Tokio...)',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // 🔘 Botón de búsqueda
            ElevatedButton.icon(
              onPressed: _loadNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Buscar Noticias'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🕑 Estados de carga o error
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_articles.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay noticias disponibles.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              // 📰 Lista de noticias
              Expanded(
                child: ListView.builder(
                  itemCount: _articles.length,
                  itemBuilder: (context, i) {
                    final a = _articles[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: a['urlToImage'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  a['urlToImage'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                              )
                            : const Icon(Icons.image_not_supported, size: 40),
                        title: Text(
                          a['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          a['description'] ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
