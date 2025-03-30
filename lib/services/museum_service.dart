import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class MuseumService {
  final Logger _logger = Logger('MuseumService');
  // Modifica questa riga per usare l'indirizzo IP del tuo computer
  final String baseUrl = 'http://192.168.178.95/museo7/api';

  // Modifica il tipo di ritorno da List<Museum> a List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> fetchMuseums() async {
    try {
      _logger.info('Fetching museums from: $baseUrl/get_museums.php');
      
      final response = await http.get(
        Uri.parse('$baseUrl/get_museums.php'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.severe('Connection timeout');
          throw Exception('Connection timeout');
        },
      );
      
      _logger.info('Response status code: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Add error handling for JSON parsing
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          _logger.severe('JSON parsing error: ${response.body}');
          throw Exception('Invalid response format: $e');
        }
        
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['museums'].map((museum) => {
            'id': museum['id'],
            'name': museum['Nome'],
            'description': museum['Descrizione'],
            'hours': museum['Orari'],
            'closed': museum['Chiuso'], 
            'coordinates': museum['Coordinate_Maps'],
            'imageUrl': museum['URL_immagine'],
            'childPrice': double.parse(museum['Bambini']),
            'youthPrice': double.parse(museum['Giovani']),
            'adultPrice': double.parse(museum['Adulti']),
            'seniorPrice': double.parse(museum['Senior']),
          }));
        } else {
          throw Exception('Failed to load museums: ${data['message']}');
        }
      } else if (response.statusCode == 500) {
        _logger.severe('Server error (500): ${response.body}');
        throw Exception('Server error: Please check your PHP logs for details');
      } else {
        throw Exception('Failed to load museums: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching museums: $e');
      rethrow;
    }
  }

  // Metodo per ottenere un museo specifico per ID
  Future<Map<String, dynamic>> fetchMuseumById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_museum.php?id=$id'),
      );
    
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.info('API Response: ${response.body}'); // Add this debug line
        
        if (data['success']) {
          final museum = {
            'id': data['museum']['id'],
            'name': data['museum']['Nome'],
            'description': data['museum']['Descrizione'],
            'hours': data['museum']['Orari'],
            'closed': data['museum']['Chiuso'],
            'coordinates': data['museum']['Coordinate_Maps'],
            'imageUrl': data['museum']['URL_immagine'],
            'childPrice': double.parse(data['museum']['Bambini']),
            'youthPrice': double.parse(data['museum']['Giovani']),
            'adultPrice': double.parse(data['museum']['Adulti']),
            'seniorPrice': double.parse(data['museum']['Senior']),
          };
          _logger.info('Processed museum data: $museum'); // Add this debug line
          return museum;
        } else {
          throw Exception('Failed to load museum: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load museum: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error fetching museum by ID: $e');
      rethrow;
    }
  }
}