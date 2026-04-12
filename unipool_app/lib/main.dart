import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unipool/screens/auth_screen.dart';
import 'package:unipool/screens/home_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';
import 'package:unipool/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await authService.init();
  runApp(const UnipoolApp());
}

class UnipoolApp extends StatelessWidget {
  const UnipoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniPool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authService.isAuthenticated ? const HomeScreen() : const AuthScreen(),
    );
  }
}
