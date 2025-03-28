import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ticket_service.dart';
import 'dart:convert';

class TicketDisplayScreen extends StatelessWidget {
  final Map<String, dynamic> ticketData;

  const TicketDisplayScreen({Key? key, required this.ticketData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qrData = ticketData['qr_data'];
    final ticketInfo = json.decode(qrData);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ticket'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Museum Ticket',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TicketService.generateQRCode(qrData, size: 250),
                      const SizedBox(height: 20),
                      _buildTicketInfo('Ticket ID', ticketInfo['ticket_id']),
                      _buildTicketInfo('Museum', ticketInfo['museum_id'].toString()),
                      _buildTicketInfo('Type', ticketInfo['ticket_type']),
                      _buildTicketInfo('Purchase Date', ticketInfo['purchase_date']),
                      _buildTicketInfo('Valid Until', ticketInfo['valid_until']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ticketInfo['ticket_id']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ticket ID copied to clipboard')),
                  );
                },
                child: const Text('Copy Ticket ID'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Add functionality to save or share the ticket
                },
                child: const Text('Save Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}