import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  // Base URL for API endpoints
  final String baseUrl = 'http://192.168.178.95/museo7/api';

  // Get user ID from shared preferences
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Update user logged status in database
  Future<bool> updateUserLoggedStatus(String userId, bool isLogged) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_logged_status.php'),
        body: {
          'user_id': userId,
          'logged': isLogged ? '1' : '0',  // Using 1/0 instead of True/False
        },
      );
      
      print('Logout response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Exception in update status request: $e');
      return false;
    }
  }
}