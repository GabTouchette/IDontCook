import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDontCook',
      theme: appTheme(),
      initialRoute: '/',
      onGenerateRoute: generateRoute,
    );
  }
}
