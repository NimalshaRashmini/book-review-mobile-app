import 'package:flutter/material.dart';
import 'screens/review_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove the debug banner
      title: 'Book Reviews',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Use Material 3 for modern design
        scaffoldBackgroundColor:
            const Color.fromARGB(255, 135, 192, 231), // Ensure white background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 125, 188, 240),
          foregroundColor: Color.fromARGB(255, 9, 52, 93),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue, // Blue FAB
          foregroundColor: Colors.white, // White icon
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      home: ReviewListScreen(), // Navigate to the review list screen
    );
  }
}
