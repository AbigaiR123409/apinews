Lab 1 · Integración segura de una API REST (NewsAPI)

Objetivo
Consumir la API pública NewsAPI desde una aplicación Flutter de forma segura, aplicando buenas prácticas de desarrollo: manejo de secretos con .env, consumo HTTPS, sanitización de texto, manejo de errores, retry exponencial y cache defensiva.

Tecnologías y dependencias
    Framework: Flutter SDK 3.x
    Lenguaje: Dart
    Paquetes usados:
    http → consumo de API REST con HTTPS
    flutter_dotenv → manejo de secretos (.env)
    shared_preferences → cache local (modo offline)

Archivo pubspec.yaml:
    dependencies:
    flutter:
        sdk: flutter
    http: ^1.2.0
    flutter_dotenv: ^5.1.0
    shared_preferences: ^2.3.2

Manejo de secretos

El archivo .env contiene la clave privada de NewsAPI:
NEWS_API_KEY=........................

Este archivo no se sube al repositorio (añadido a .gitignore).
Se carga en el main.dart con: await dotenv.load(fileName: ".env");
La clave se lee mediante: dotenv.env['NEWS_API_KEY']

Consumo de la API REST
Se utiliza el endpoint de NewsAPI:
https://newsapi.org/v2/everything?q=apple&language=es&sortBy=popularity&apiKey=


Ejemplo de solicitud
final uri = Uri.https('newsapi.org', '/v2/everything', {
  'q': 'apple',
  'language': 'es',
  'sortBy': 'popularity',
  'apiKey': dotenv.env['NEWS_API_KEY'],
});
final resp = await http.get(uri).timeout(const Duration(seconds: 8));

Lógica del servicio (news_service.dart)
El servicio implementa:
    HTTPS obligatorio (Uri.https)
    Timeout controlado (8 segundos)
    Manejo de errores (401, 429, 404, timeout)
    Retry exponencial: 3 intentos con tiempos 1s, 2s y 4s
    Cache defensiva: guarda última respuesta local con shared_preferences
    Sanitización OWASP: elimina etiquetas HTML del texto mostrado


Interfaz de usuario (news_screen.dart)
Pantalla con manejo de estados mediante FutureBuilder:
Estado	   Descripción
Cargando   Muestra CircularProgressIndicator() mientras se hace la petición.
Éxito	   Lista de noticias con título, descripción e imagen.
Error	   Mensaje con descripción del error (timeout, red, etc.).
Vacío	   Muestra “No hay noticias disponibles.”

Incluye campo de búsqueda para cambiar el tema (apple, tecnología, deportes, etc.).


Cache defensiva
Si hay conexión → se descargan y guardan las noticias en cache local (shared_preferences).
Si no hay conexión → se muestran las últimas noticias guardadas.
Esto garantiza resiliencia y disponibilidad (modo offline).

Retry exponencial
Cuando la red falla:
    Se reintenta tras 1 segundo
    Luego tras 2 segundos
    Finalmente tras 4 segundos
Si todos los intentos fallan, se carga el cache local.

Prueba con Postman
Se verificó el funcionamiento del endpoint antes de consumirlo desde Flutter.
Método: GET
Evidencia (Postman mostrando status: ok y artículos):
(Usa la ruta según donde guardes la imagen)
![Evidencia Postman](evidencias/news.png)