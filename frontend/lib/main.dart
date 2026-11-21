import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MliPrestamosApp());
}

class MliPrestamosApp extends StatelessWidget {
  const MliPrestamosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLI Préstamos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}