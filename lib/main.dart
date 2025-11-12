import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'news_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Cambia esta línea si aún dice "assets/.env"
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NewsScreen(),
    );
  }
}
