import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(CollectHubApp());
}

class CollectHubApp extends StatelessWidget {
  const CollectHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CollectHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Text',
        appBarTheme: AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: SplashScreen(),
    );
  }
}