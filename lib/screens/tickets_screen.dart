import 'dart:convert';
import 'dart:async';
import 'dart:io';
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
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadTickets();
  }
  
  // Add the _fetchUserToken method inside the class
  Future<void> _fetchUserToken(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/museo7/api/get_token.php?user_id=$userId'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connessione al server scaduta. Riprova più tardi.');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['token'] != null) {
          // Save token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          
          // Reload tickets with the new token
          _loadTickets();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Token di autorizzazione non trovato';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Errore del server: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e is SocketException) {
          _errorMessage = 'Impossibile connettersi al server. Verifica la tua connessione.';
        } else if (e is TimeoutException) {
          _errorMessage = e.message ?? 'Timeout della connessione';
        } else {
          _errorMessage = 'Errore: ${e.toString()}';
        }
      });
    }
  }
  
  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('token'); // Get token from SharedPreferences
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Accedi per visualizzare i tuoi biglietti';
        });
        return;
      }
      
      if (token == null) {
        // If token is missing, try to fetch it from the database
        await _fetchUserToken(userId);
        return;
      }
      
      // Use a more reliable URL format and add error handling
      final response = await http.get(
        Uri.parse('http://10.0.2.2/museo7/api/get_user_tickets.php?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token', // Add token to headers
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Fix TimeoutException usage
          throw TimeoutException('Connessione al server scaduta. Riprova più tardi.');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _tickets = List<Map<String, dynamic>>.from(data['tickets']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _tickets = [];
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Nessun biglietto trovato';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Errore del server: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e is SocketException) {
          _errorMessage = 'Impossibile connettersi al server. Verifica la tua connessione.';
        } else if (e is TimeoutException) {
          _errorMessage = e.message ?? 'Timeout della connessione';
        } else {
          _errorMessage = 'Errore: ${e.toString()}';
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage.contains('connettersi') || 
                          _errorMessage.contains('Timeout') ||
                          _errorMessage.contains('Connection'))
                        ElevatedButton(
                          onPressed: _loadTickets,
                          child: const Text('Riprova'),
                        ),
                    ],
                  ),
                )
              : _tickets.isEmpty
                  ? const Center(child: Text('Non hai ancora acquistato biglietti'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return _buildTicketCard(ticket);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTickets,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTicketDetails(ticket),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket['museum_name'] ?? 'Museo',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '€${ticket['prezzo_totale']}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket['data_visita']),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(ticket['ora_visita']),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if ((ticket['num_biglietti_bambini'] ?? 0) > 0)
                    _buildTicketTypeChip('Bambini: ${ticket['num_biglietti_bambini']}'),
                  if ((ticket['num_biglietti_giovani'] ?? 0) > 0)
                    _buildTicketTypeChip('Giovani: ${ticket['num_biglietti_giovani']}'),
                  if ((ticket['num_biglietti_adulti'] ?? 0) > 0)
                    _buildTicketTypeChip('Adulti: ${ticket['num_biglietti_adulti']}'),
                  if ((ticket['num_biglietti_anziani'] ?? 0) > 0)
                    _buildTicketTypeChip('Senior: ${ticket['num_biglietti_anziani']}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method for ticket type chips
  Widget _buildTicketTypeChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade800,
        ),
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
    // Generate QR data if it doesn't exist
    final qrData = ticket['token'] ?? 
                  'TICKET:${ticket['id']}:${ticket['id_museo']}:${ticket['data_visita']}';
    
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
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Data', _formatDate(ticket['data_visita'])),
                _buildDetailRow('Ora', _formatTime(ticket['ora_visita'])),
                if ((ticket['num_biglietti_bambini'] ?? 0) > 0)
                  _buildDetailRow('Bambini', '${ticket['num_biglietti_bambini']}'),
                if ((ticket['num_biglietti_giovani'] ?? 0) > 0)
                  _buildDetailRow('Giovani', '${ticket['num_biglietti_giovani']}'),
                if ((ticket['num_biglietti_adulti'] ?? 0) > 0)
                  _buildDetailRow('Adulti', '${ticket['num_biglietti_adulti']}'),
                if ((ticket['num_biglietti_anziani'] ?? 0) > 0)
                  _buildDetailRow('Senior', '${ticket['num_biglietti_anziani']}'),
                _buildDetailRow('Prezzo totale', '€${ticket['prezzo_totale']}'),
                _buildDetailRow('Data acquisto', _formatDateTime(ticket['data_acquisto'])),
                _buildDetailRow('Stato', ticket['stato'] ?? 'valido'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Chiudi'), // Move child to the end
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
 
  
  // Add the missing _buildDetailRow method
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  // Add the missing _formatDateTime method
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }
}