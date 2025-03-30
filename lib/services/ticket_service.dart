import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class TicketService {
  static Future<Map<String, dynamic>> generateTicket(
      int userId, int museumId, String ticketType, double price) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.178.95/museo7/api/purchase_ticket.php'),
        body: {
          'user_id': userId.toString(),
          'museum_id': museumId.toString(),
          'ticket_type': ticketType,
          'price': price.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'ticket_id': data['ticket_id'],
            'purchase_date': data['purchase_date'],
            'qr_data': data['qr_data'],
          };
        } else {
          return {'success': false, 'message': data['message']};
        }
      } else {
        return {'success': false, 'message': 'Server error'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Widget generateQRCode(String data, {double size = 200.0}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
    );
  }
}