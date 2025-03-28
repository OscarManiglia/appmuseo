import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'services/museum_service.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'ticket_purchase_page.dart';

class MuseumDetailPage extends StatefulWidget {
  final Map<String, dynamic> museum;

  const MuseumDetailPage({super.key, required this.museum});

  @override
  State<MuseumDetailPage> createState() => _MuseumDetailPageState();
}

class _MuseumDetailPageState extends State<MuseumDetailPage> {
  final MuseumService _museumService = MuseumService();
  final Logger _logger = Logger('MuseumDetailPage');
  Map<String, dynamic> museumDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    museumDetails = widget.museum;
    // Load additional details to ensure we have all fields
    loadAdditionalDetails();
  }
  
  // Metodo per caricare dettagli aggiuntivi
  Future<void> loadAdditionalDetails() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final details = await _museumService.fetchMuseumById(widget.museum['id']);
      setState(() {
        museumDetails = details;
        isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading additional details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openMap() async {
    try {
      final coordinates = museumDetails['coordinates'] ?? '';
      
      // Verifica se le coordinate sono vuote
      if (coordinates.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coordinate non disponibili per questo museo')),
        );
        return;
      }
      
      // Formatta l'URL in modo corretto - prova con un formato più semplice
      final url = 'https://www.google.com/maps?q=${Uri.encodeComponent(coordinates)}';
      _logger.info('Tentativo di aprire la mappa con URL: $url');
      
      // Verifica se l'URL può essere aperto
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Prova con un URL alternativo
        final altUrl = 'geo:0,0?q=${Uri.encodeComponent(coordinates)}';
        _logger.info('Tentativo con URL alternativo: $altUrl');
        
        final Uri altUri = Uri.parse(altUrl);
        if (await canLaunchUrl(altUri)) {
          await launchUrl(altUri);
        } else {
          _logger.severe("Impossibile aprire l'URL: $url e $altUrl");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossibile aprire la mappa. Verifica che sia installata un\'app per le mappe.')),
          );
        }
      }
    } catch (e) {
      _logger.severe("Errore durante l'apertura della mappa: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Museo'),
        leading: IconButton(
          icon: const Icon(MdiIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immagine del museo
                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Image.network(
                      museumDetails['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(MdiIcons.imageOff, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  
                  // Titolo del museo
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      museumDetails['name'], // Changed from museum to museumDetails
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Descrizione
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      museumDetails['description'], // Changed from museum to museumDetails
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Orari
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orari:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          museumDetails['hours'], // Changed from museum to museumDetails
                          style: const TextStyle(fontSize: 16),
                        ),
                        
                        // Only show closure days if not null or empty
                        if (museumDetails['closed'] != null && museumDetails['closed'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Giorni di chiusura:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            museumDetails['closed'],
                            style: const TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Prezzi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prezzi:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPriceRow('Bambini', museumDetails['childPrice']), // Changed from museum to museumDetails
                        _buildPriceRow('Giovani', museumDetails['youthPrice']), // Changed from museum to museumDetails
                        _buildPriceRow('Adulti', museumDetails['adultPrice']), // Changed from museum to museumDetails
                        _buildPriceRow('Senior', museumDetails['seniorPrice']), // Changed from museum to museumDetails
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pulsante per visualizzare sulla mappa
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(MdiIcons.map),
                        label: const Text('Visualizza sulla mappa'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _openMap,
                      ),
                    ),
                  ),
                  
                  // Pulsante per acquistare biglietti
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(MdiIcons.ticketOutline),
                        label: const Text('Acquista biglietti'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TicketPurchasePage(museum: museumDetails),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
  
  Widget _buildPriceRow(String category, dynamic price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category),
          Text(
            '€${price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  // Remove the duplicate _openMap method and unused _launchWebsite method
}