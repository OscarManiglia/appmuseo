import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Add this import for DatabaseService

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
  
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Accedi per visualizzare il tuo profilo';
        });
        return;
      }
      
      // Recupera i dati dell'utente direttamente dal server usando solo l'ID utente
      final response = await http.get(
        Uri.parse('http://192.168.178.95/museo7/api/get_user_profile.php?user_id=$userId'),
      );
      
      print('Debug - API response: ${response.body}');
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final user = data['user'];
        final nome = user['Nome'] as String? ?? '';
        final cognome = user['Cognome'] as String? ?? '';
        final email = user['Email'] as String? ?? '';
        
        print('Debug - API data: Nome=$nome, Cognome=$cognome, Email=$email');
        
        // Salva i dati in SharedPreferences per uso futuro
        final fullName = '$nome $cognome'.trim();
        await prefs.setString('userName', fullName);
        await prefs.setString('userEmail', email);
        
        setState(() {
          _userName = fullName;
          _userEmail = email;
          _isLoading = false;
        });
        print('Debug - Set state with API data: $_userName, $_userEmail');
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Errore nel recupero dei dati';
          _isLoading = false;
        });
        print('Debug - API error: $_errorMessage');
      }
    } catch (e) {
      print('Debug - Exception: $e');
      setState(() {
        _errorMessage = 'Errore nel caricamento dei dati: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, 
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/login');
                        },
                        child: const Text('Accedi'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nome',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Email',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              final userId = prefs.getInt('userId')?.toString();
                              
                              if (userId != null) {
                                // Update logged status in database
                                final response = await http.post(
                                  Uri.parse('http://192.168.178.95/museo7/api/update_logged_status.php'),
                                  body: {
                                    'user_id': userId,
                                    'logged': '0',  // 0 for False
                                  },
                                );
                                
                                // Check response for debugging
                                print('Logout response: ${response.body}');
                                
                                // Verify if the update was successful
                                final data = json.decode(response.body);
                                if (data['success'] != true) {
                                  throw Exception('Failed to update logged status: ${data['error']}');
                                }
                              }
                              
                              // Clear local storage
                              await prefs.clear();
                              
                              // Add mounted check before using BuildContext
                              if (!mounted) return;
                              
                              // Navigate to login screen
                              Navigator.pushReplacementNamed(context, '/login');
                            } catch (e) {
                              print('Error during logout: $e');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Errore durante il logout: $e')),
                              );
                            }
                          },
                          child: const Text('Logout'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}