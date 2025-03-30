import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> museum;
  final DateTime visitDate;
  final TimeOfDay visitTime;
  final Map<String, int> tickets;
  final double totalPrice;

  const CheckoutPage({
    super.key, 
    required this.museum, 
    required this.visitDate, 
    required this.visitTime, 
    required this.tickets,
    required this.totalPrice,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Logger _logger = Logger('CheckoutPage');
  String paymentMethod = 'paypal'; // Default to PayPal
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Check login status when page loads
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');
    
    // Use logger instead of print
    _logger.info('isLoggedIn: $isLoggedIn');
    _logger.info('userId: $userId');
    _logger.info('token: $token');
    
    if (!isLoggedIn || userId == null || token == null) {
      setState(() {
        _errorMessage = 'Informazioni di login mancanti. Effettua nuovamente il login.';
      });
    }
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
  
    try {
      // Get user information from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('token');
      
      if (userId == null) {
        setState(() {
          _errorMessage = 'Informazioni di login mancanti. Effettua nuovamente il login.';
          _isLoading = false;
        });
        return;
      }
  
      // Format date and time for API
      final formattedDate = "${widget.visitDate.year}-${widget.visitDate.month.toString().padLeft(2, '0')}-${widget.visitDate.day.toString().padLeft(2, '0')}";
      final formattedTime = "${widget.visitTime.hour.toString().padLeft(2, '0')}:${widget.visitTime.minute.toString().padLeft(2, '0')}";
  
      // Prepare payment data
      final Map<String, dynamic> paymentData = {
        'user_id': userId,
        'museum_id': widget.museum['id'],
        'visit_date': formattedDate,
        'visit_time': formattedTime,
        'num_bambini': widget.tickets['child'] ?? 0,
        'num_giovani': widget.tickets['youth'] ?? 0,
        'num_adulti': widget.tickets['adult'] ?? 0,
        'num_anziani': widget.tickets['senior'] ?? 0,
        'prezzo_totale': widget.totalPrice,
        'payment_method': paymentMethod,
      };
      
      // Add token if available
      if (token != null) {
        paymentData['token'] = token;
      }
      
      // Make API call
      final response = await http.post(
        Uri.parse('http://192.168.178.95/museo7/api/purchase_ticket.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paymentData),
      );
      
      // Check if response is valid JSON
      if (response.body.isEmpty) {
        throw Exception('Risposta vuota dal server');
      }
      
      try {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Payment successful
          if (!mounted) return;
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acquisto completato con successo!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate to Home screen and clear the navigation stack
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/home', 
            (route) => false, // This removes all previous routes
          );
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Errore durante il pagamento';
            _isLoading = false;
          });
        }
      } catch (e) {
        throw Exception('Errore nel parsing della risposta JSON: ${e.toString()}. Risposta: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Si è verificato un errore: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Riepilogo Ordine',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),                            
                            Text('Museo: ${widget.museum['nome'] ?? widget.museum['name'] ?? 'Sconosciuto'}'),
                            Text('Data: ${DateFormat('dd/MM/yyyy').format(widget.visitDate)}'),
                            Text('Ora: ${widget.visitTime.format(context)}'),
                            const Divider(),
                            if (widget.tickets['child']! > 0)
                              Text('Bambini (${widget.tickets['child']}): €${(widget.tickets['child']! * widget.museum['childPrice']).toStringAsFixed(2)}'),
                            if (widget.tickets['youth']! > 0)
                              Text('Giovani (${widget.tickets['youth']}): €${(widget.tickets['youth']! * widget.museum['youthPrice']).toStringAsFixed(2)}'),
                            if (widget.tickets['adult']! > 0)
                              Text('Adulti (${widget.tickets['adult']}): €${(widget.tickets['adult']! * widget.museum['adultPrice']).toStringAsFixed(2)}'),
                            if (widget.tickets['senior']! > 0)
                              Text('Senior (${widget.tickets['senior']}): €${(widget.tickets['senior']! * widget.museum['seniorPrice']).toStringAsFixed(2)}'),
                            const Divider(),
                            Text(
                              'Totale: €${widget.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Metodo di Pagamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Payment methods
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.credit_card),
                          SizedBox(width: 8),
                          Text('Carta di Credito/Debito'),
                        ],
                      ),
                      value: 'card',
                      groupValue: paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          paymentMethod = value!;
                        });
                      },
                    ),
                    
                    // PayPal payment option
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(MdiIcons.creditCardOutline),
                          SizedBox(width: 8),
                          Text('PayPal'),
                        ],
                      ),
                      value: 'paypal',
                      groupValue: paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          paymentMethod = value!;
                        });
                      },
                    ),
                    
                    // Payment info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Verrai reindirizzato a ${paymentMethod == 'card' ? 'pagina di pagamento sicura' : 'PayPal'} per completare il pagamento dopo aver cliccato su "Conferma Pagamento".',
                        ),
                      ),
                    ),
                    
                    if (_errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(8),
                        color: Colors.red[100],
                        child: Text(
                          'Si è verificato un errore: $_errorMessage',
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 174, 0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Conferma Pagamento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

