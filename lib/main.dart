import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/profile_screen.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Museo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        'register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileScreen(),
        '/tickets': (context) => const TicketsScreen(),
        '/my_tickets': (context) => const TicketsScreen(),
      },
    );
  }
}
