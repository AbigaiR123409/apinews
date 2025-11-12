import 'package:flutter/material.dart';
import 'news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsService _service = NewsService();
  late Future<List<Map<String, dynamic>>> _futureNews;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureNews = _service.fetchNews();
  }

  void _searchNews() {
    final query = _controller.text.trim();
    setState(() {
      _futureNews = _service.fetchNews(query: query.isEmpty ? 'apple' : query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Últimas Noticias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _searchNews,
            tooltip: 'Recargar noticias',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Buscar tema (ej. tecnología, fútbol, salud...)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchNews,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _searchNews(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureNews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No hay noticias disponibles.'),
                  );
                }

                final newsList = snapshot.data!;
                return ListView.builder(
                  itemCount: newsList.length,
                  itemBuilder: (context, i) {
                    final n = newsList[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: n['urlToImage'] != null
                              ? Image.network(
                                  n['urlToImage'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported,
                                          color: Colors.grey, size: 40),
                                    );
                                  },
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.newspaper,
                                      color: Colors.grey, size: 40),
                                ),
                        ),
                        title: Text(
                          n['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          n['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _showNewsDialog(context, n),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewsDialog(BuildContext context, Map<String, dynamic> news) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(news['title'] ?? 'Noticia'),
        content: Text(
          news['url'] ?? 'Sin enlace disponible',
          style: const TextStyle(fontSize: 13, color: Colors.blueAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
