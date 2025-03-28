import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import 'ticket_display_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int userId;
  final int museumId;
  final String ticketType;
  final double price;

  const PaymentScreen({
    Key? key,
    required this.userId,
    required this.museumId,
    required this.ticketType,
    required this.price,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  void _onPaymentSuccess() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    // Generate ticket
    final ticketResult = await TicketService.generateTicket(
      widget.userId,
      widget.museumId,
      widget.ticketType,
      widget.price,
    );
    
    // Check if widget is still mounted before updating state
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    if (ticketResult['success']) {
      // Check if widget is still mounted before using context
      if (!mounted) return;
      
      // Navigate to ticket display screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(
            ticketData: ticketResult,
          ),
        ),
      );
    } else {
      // Check if widget is still mounted before using context
      if (!mounted) return;
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${ticketResult['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment form would go here
                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: _onPaymentSuccess,
                    child: const Text('Complete Payment'),
                  ),
                ],
              ),
            ),
    );
  }
}