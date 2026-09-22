import 'package:flutter/material.dart';
import 'app/core/theme/app_theme.dart';
import 'app/modules/auth/views/login_page.dart';

void main() {
  runApp(const PowerShapeApp());
}

class PowerShapeApp extends StatelessWidget {
  const PowerShapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power Shape',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginPage(),
    );
  }
}