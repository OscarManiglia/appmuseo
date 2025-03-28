import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ticket_confirmation_page.dart';
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
  String paymentMethod = 'card'; // Default to card payment
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _processPayment() async {
    // Validate form fields
    if (paymentMethod == 'card') {
      if (_cardNumberController.text.isEmpty ||
          _expiryDateController.text.isEmpty ||
          _cvvController.text.isEmpty ||
          _cardHolderController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Tutti i campi sono obbligatori';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Sessione scaduta. Effettua nuovamente il login.';
          _isLoading = false;
        });
        return;
      }

      // Formatta la data e l'ora per l'API
      final dateFormat = DateFormat('yyyy-MM-dd');
      final formattedDate = dateFormat.format(widget.visitDate);
      final formattedTime = '${widget.visitTime.hour.toString().padLeft(2, '0')}:${widget.visitTime.minute.toString().padLeft(2, '0')}:00';

      // Prepara i dati per l'acquisto
      final response = await http.post(
        Uri.parse('http://10.0.2.2/museo7/api/purchase_ticket.php'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'id_museo': widget.museum['id'].toString(),
          'data_visita': formattedDate,
          'ora_visita': formattedTime,
          'num_biglietti_bambini': widget.tickets['child'].toString(),
          'num_biglietti_giovani': widget.tickets['youth'].toString(),
          'num_biglietti_adulti': widget.tickets['adult'].toString(),
          'num_biglietti_anziani': widget.tickets['senior'].toString(),
          'prezzo_totale': widget.totalPrice.toString(),
        },
      );

      final data = json.decode(response.body);
      _logger.info('Payment response: $data');

      if (data['success']) {
        // Naviga alla pagina di conferma del biglietto
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TicketConfirmationPage(
              ticketId: data['ticket']['id'],
              museum: widget.museum,
              visitDate: widget.visitDate,
              visitTime: widget.visitTime,
              tickets: widget.tickets,
              totalPrice: widget.totalPrice,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Errore durante l\'acquisto del biglietto';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error processing payment: $e');
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
        title: const Text('Checkout'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riepilogo Ordine',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Museo: ${widget.museum['Nome']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Data: ${_formatDate(widget.visitDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ora: ${_formatTime(widget.visitTime)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Ticket summary
                    if (widget.tickets['child']! > 0)
                      _buildTicketRow('Bambini', widget.tickets['child']!, widget.museum['childPrice'] ?? 0.0),
                    if (widget.tickets['youth']! > 0)
                      _buildTicketRow('Giovani', widget.tickets['youth']!, widget.museum['youthPrice'] ?? 0.0),
                    if (widget.tickets['adult']! > 0)
                      _buildTicketRow('Adulti', widget.tickets['adult']!, widget.museum['adultPrice'] ?? 0.0),
                    if (widget.tickets['senior']! > 0)
                      _buildTicketRow('Anziani', widget.tickets['senior']!, widget.museum['seniorPrice'] ?? 0.0),
                    
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Totale',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '€${widget.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment method selection
            const Text(
              'Metodo di Pagamento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Credit card option
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(MdiIcons.creditCard),
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
            
            // PayPal option
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(MdiIcons.creditCardOutline), // Changed from MdiIcons.paypal to an available icon
                  const SizedBox(width: 8),
                  const Text('PayPal'),
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
            
            const SizedBox(height: 16),
            
            // Payment details form
            if (paymentMethod == 'card')
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dettagli Carta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Card number
                      TextField(
                        controller: _cardNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Numero Carta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(MdiIcons.creditCard),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      
                      // Expiry date and CVV
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expiryDateController,
                              decoration: const InputDecoration(
                                labelText: 'Data Scadenza (MM/YY)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _cvvController,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Cardholder name
                      TextField(
                        controller: _cardHolderController,
                        decoration: const InputDecoration(
                          labelText: 'Titolare Carta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(MdiIcons.account),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (paymentMethod == 'paypal')
              const Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Verrai reindirizzato a PayPal per completare il pagamento dopo aver cliccato su "Conferma Pagamento".',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Confirm payment button
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Conferma Pagamento',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketRow(String type, int count, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$type ($count)',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '€${(count * price).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}