import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  bool _isLoading = true;
  List<dynamic> _tickets = [];
  
  @override
  void initState() {
    super.initState();
    _loadTickets();
  }
  
  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        // Handle not logged in
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      
      final response = await http.get(
        Uri.parse('http://localhost/museo7/api/get_user_tickets.php'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _tickets = data['tickets'];
            _isLoading = false;
          });
        } else {
          _showErrorSnackBar(data['message']);
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showErrorSnackBar('Errore del server');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Errore: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I Miei Biglietti'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(
                  child: Text(
                    'Non hai ancora acquistato biglietti',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          _showTicketDetails(ticket);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Museo: ${ticket['museum_name']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Data: ${_formatDate(ticket['data_visita'])}'),
                              Text('Ora: ${_formatTime(ticket['ora_visita'])}'),
                              Text('Biglietto ID: ${ticket['ticket_id']}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTickets,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  String _formatTime(String timeStr) {
    return timeStr;
  }
  
  void _showTicketDetails(dynamic ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Biglietto per ${ticket['museum_name']}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: ticket['qr_data'],
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                _buildTicketInfo('ID Biglietto', ticket['ticket_id']),
                _buildTicketInfo('Museo', ticket['museum_name']),
                _buildTicketInfo('Data', _formatDate(ticket['data_visita'])),
                _buildTicketInfo('Ora', _formatTime(ticket['ora_visita'])),
                _buildTicketInfo('Bambini', ticket['num_biglietti_bambini']),
                _buildTicketInfo('Giovani', ticket['num_biglietti_giovani']),
                _buildTicketInfo('Adulti', ticket['num_biglietti_adulti']),
                _buildTicketInfo('Senior', ticket['num_biglietti_senior']),
                _buildTicketInfo('Prezzo Totale', '€${ticket['prezzo_totale']}'),
                _buildTicketInfo('Data Acquisto', _formatDate(ticket['purchase_date'])),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Chiudi'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTicketInfo(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value.toString()),
        ],
      ),
    );
  }
}