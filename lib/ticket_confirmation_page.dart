import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:logging/logging.dart';

class TicketConfirmationPage extends StatefulWidget {
  final int ticketId;
  final Map<String, dynamic> museum;
  final DateTime visitDate;
  final TimeOfDay visitTime;
  final Map<String, int> tickets;
  final double totalPrice;

  const TicketConfirmationPage({
    super.key,
    required this.ticketId,
    required this.museum,
    required this.visitDate,
    required this.visitTime,
    required this.tickets,
    required this.totalPrice,
  });

  @override
  State<TicketConfirmationPage> createState() => _TicketConfirmationPageState();
}

class _TicketConfirmationPageState extends State<TicketConfirmationPage> {
  final Logger _logger = Logger('TicketConfirmationPage');
  bool isLoading = true;
  String? qrData;
  Map<String, dynamic>? ticketDetails;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchTicketQR();
  }

  Future<void> _fetchTicketQR() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _showErrorSnackBar('Sessione scaduta. Effettua nuovamente il login.');
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/museo7/api/generate_qr.php?ticket_id=${widget.ticketId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (data['success']) {
        setState(() {
          qrData = data['qr_data'];
          ticketDetails = data['ticket'];
          isLoading = false;
        });
      } else {
        _showErrorSnackBar(data['message'] ?? 'Errore nel recupero del biglietto');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error fetching ticket QR: $e');
      _showErrorSnackBar('Si è verificato un errore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Remove these imports:
  // import 'package:image_gallery_saver/image_gallery_saver.dart';
  // import 'package:permission_handler/permission_handler.dart';



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conferma Biglietto'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : qrData == null
              ? const Center(child: Text('Impossibile generare il QR code'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                widget.museum['Nome'] ?? 'Museo',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Visita: ${_formatDate(widget.visitDate)} - ${_formatTime(widget.visitTime)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              RepaintBoundary(
                                key: _qrKey,
                                child: QrImageView(
                                  data: qrData!,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Codice Biglietto: ${ticketDetails?['token'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              _buildTicketInfo('Biglietti Bambini', widget.tickets['child'] ?? 0),
                              _buildTicketInfo('Biglietti Giovani', widget.tickets['youth'] ?? 0),
                              _buildTicketInfo('Biglietti Adulti', widget.tickets['adult'] ?? 0),
                              _buildTicketInfo('Biglietti Anziani', widget.tickets['senior'] ?? 0),
                              const Divider(),
                              const SizedBox(height: 8),
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

                      const SizedBox(height: 16),
                      const Text(
                        'Mostra questo QR code all\'ingresso del museo per accedere.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTicketInfo(String label, int count) {
    if (count <= 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}