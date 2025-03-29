import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        setState(() {
          _errorMessage = 'Sessione scaduta. Effettua nuovamente il login.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/museo7/api/get_user_tickets.php?user_id=$userId'),
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
          _errorMessage = data['message'] ?? 'Errore nel recupero dei biglietti';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Si è verificato un errore: $e';
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
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : _tickets.isEmpty
                  ? const Center(child: Text('Non hai ancora acquistato biglietti.'))
                  : ListView.builder(
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        final visitDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(ticket['data_visita']));
                        final visitTime = ticket['ora_visita'];
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket['nome_museo'] ?? 'Museo sconosciuto',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('Data: $visitDate'),
                                Text('Ora: $visitTime'),
                                Text('Stato: ${ticket['stato']}'),
                                const SizedBox(height: 8),
                                Text('Prezzo totale: €${ticket['prezzo_totale']}'),
                                const SizedBox(height: 16),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navigate to ticket detail page
                                      // Implementazione futura
                                    },
                                    child: const Text('Visualizza Dettagli'),
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