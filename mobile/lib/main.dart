import 'package:flutter/material.dart';
import 'package:mobile/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDontCook',
      theme: ThemeData.light(),
      initialRoute: '/',
      onGenerateRoute: generateRoute,
    );
  }
}
