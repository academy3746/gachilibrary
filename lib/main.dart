import 'package:flutter/material.dart';
import 'package:gachilibrary/features/webview/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5A6A8),
          primary: const Color(0xFFF5D2D2),
        ),
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: MainScreen.routeName,
      routes: {
        MainScreen.routeName: (context) => const MainScreen(),
      },
    );
  }
}
