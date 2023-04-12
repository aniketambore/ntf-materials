import 'package:flutter/material.dart';
import 'package:noost_client/screens/screens.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noost',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
      ),
      home: const NoostFeedScreen(),
    );
  }
}
