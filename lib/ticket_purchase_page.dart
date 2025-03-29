import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Add this import at the top of the file
import 'checkout_page.dart';

class TicketPurchasePage extends StatefulWidget {
  final Map<String, dynamic> museum;

  const TicketPurchasePage({super.key, required this.museum});

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  
  // Counters for ticket types
  int childCount = 0;
  int youthCount = 0;
  int adultCount = 1;
  int seniorCount = 0;

  // Get formatted date
  String get formattedDate {
    return "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}";
  }

  // Get formatted time
  String get formattedTime {
    return "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
  }

  // Calculate total price
  double get totalPrice {
    return ((childCount * (widget.museum['childPrice'] ?? 0.0)) +
           (youthCount * (widget.museum['youthPrice'] ?? 0.0)) +
           (adultCount * (widget.museum['adultPrice'] ?? 0.0)) +
           (seniorCount * (widget.museum['seniorPrice'] ?? 0.0))).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acquista Biglietto'),
        leading: IconButton(
          icon: const Icon(MdiIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Museum name
              Text(
                widget.museum['name'] ?? 'Museo',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Date selection
              const Text(
                'Data visita:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(MdiIcons.menuDown),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Time selection
              const Text(
                'Orario visita:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null && picked != selectedTime) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(MdiIcons.menuDown),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Ticket types
              const Text(
                'Tipologie di biglietti:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Child tickets
              _buildTicketTypeRow(
                'Bambini (0-13)', 
                '€${widget.museum['childPrice']?.toStringAsFixed(2) ?? '0.00'}',
                childCount,
                (value) => setState(() => childCount = value),
              ),
              const SizedBox(height: 16),
              
              // Youth tickets
              _buildTicketTypeRow(
                'Giovani (13-26)', 
                '€${widget.museum['youthPrice']?.toStringAsFixed(2) ?? '0.00'}',
                youthCount,
                (value) => setState(() => youthCount = value),
              ),
              const SizedBox(height: 16),
              
              // Adult tickets
              _buildTicketTypeRow(
                'Adulti', 
                '€${widget.museum['adultPrice']?.toStringAsFixed(2) ?? '0.00'}',
                adultCount,
                (value) => setState(() => adultCount = value),
              ),
              const SizedBox(height: 16),
              
              // Senior tickets
              _buildTicketTypeRow(
                'Senior (65+)', 
                '€${widget.museum['seniorPrice']?.toStringAsFixed(2) ?? '0.00'}',
                seniorCount,
                (value) => setState(() => seniorCount = value),
              ),
              
              const SizedBox(height: 32),
              
              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Totale:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '€${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Purchase button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout, // Use the method instead of inline code
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Acquista',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Keep only one of these methods and remove the other
  Widget _buildTicketTypeRow(String title, String price, int count, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(MdiIcons.minusCircleOutline),
              onPressed: count > 0 ? () => onChanged(count - 1) : null,
              color: Colors.grey,
            ),
            SizedBox(
              width: 30,
              child: Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(MdiIcons.plusCircleOutline),
              onPressed: () => onChanged(count + 1),
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
  
  // Delete the duplicate _buildTicketRow method
  
  // Keep this method and use it in the ElevatedButton's onPressed
  void _proceedToCheckout() {
    // Check if at least one ticket is selected
    if (totalTickets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona almeno un biglietto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  
    // Remove this unused variable
    // final tickets = {
    //   'child': childCount,
    //   'youth': youthCount,
    //   'adult': adultCount,
    //   'senior': seniorCount,
    // };
  
    // Fix the navigation to CheckoutPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          museum: widget.museum, // Use widget.museum instead of selectedMuseum
          visitDate: selectedDate,
          visitTime: selectedTime,
          tickets: {
            'child': childCount,
            'youth': youthCount,
            'adult': adultCount,
            'senior': seniorCount,
          },
          totalPrice: totalPrice, // Use totalPrice getter instead of calculateTotal()
        ),
      ),
    );
  }
  
  // Add this getter to calculate total tickets
  int get totalTickets {
    return childCount + youthCount + adultCount + seniorCount;
  }
}