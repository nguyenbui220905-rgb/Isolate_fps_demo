import 'package:flutter/material.dart';
import 'ui/isolate_demo.dart';

void main() {
  runApp(const IsolateDemoApp());
}

class IsolateDemoApp extends StatelessWidget {
  const IsolateDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolate FPS Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const IsolateDemo(),
    );
  }
}