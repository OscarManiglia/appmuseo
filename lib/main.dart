import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Import your screens
import 'login_page.dart';
import 'home_page.dart';
import 'screens/profile_screen.dart';
// Import other necessary screens

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if user is already logged in
  final bool isLoggedIn = await checkUserLoggedIn();
  
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkUserLoggedIn() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId != null) {
      // Check if user is logged in the database
      final response = await http.post(
        Uri.parse('http://192.168.178.95/museo7/api/check_logged_status.php'),
        body: {
          'user_id': userId.toString(),
        },
      );
      
      final data = json.decode(response.body);
      return data['logged'] == true;
    }
    return false;
  } catch (e) {
    print('Error checking login status: $e');
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Museo App',
      theme: ThemeData(
        // Your theme data
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileScreen(),
        // Add other routes as needed
      },
    );
  }
}
