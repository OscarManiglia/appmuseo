import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Removed unused import: package:intl/intl.dart

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({Key? key}) : super(key: key);

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Simplified null-aware assignment
      int? userId = prefs.getInt('user_id');
      userId ??= prefs.getInt('userId');
      
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        setState(() {
          _errorMessage = 'Sessione scaduta. Effettua nuovamente il login.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.178.95/museo7/api/get_user_tickets.php?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          _tickets = data['tickets'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Errore nel caricamento dei biglietti';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I Miei Biglietti'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _tickets.isEmpty
                  ? const Center(child: Text('Non hai ancora acquistato biglietti'))
                  : ListView.builder(
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Museo: ${ticket['nome_museo'] ?? 'N/A'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text('Data: ${ticket['data_visita'] ?? 'N/A'}'),
                                Text('Ora: ${ticket['ora_visita'] ?? 'N/A'}'),
                                Text('Prezzo: €${ticket['prezzo'] ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                if (ticket['qr_code'] != null)
                                  Center(
                                    child: Image.memory(
                                      base64Decode(ticket['qr_code']),
                                      width: 200,
                                      height: 200,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}