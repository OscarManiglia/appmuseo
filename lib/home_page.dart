import 'package:flutter/material.dart';
import 'custom_navbar.dart';
import 'package:logging/logging.dart';
import 'museum_detail_page.dart';
import 'services/museum_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final Logger _logger = Logger('HomePageState');
  final MuseumService _museumService = MuseumService();
  List<Map<String, dynamic>> museums = [];
  String errorMessage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Configure logger to print to console
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
    fetchMuseums();
  }

  Future<void> fetchMuseums() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final fetchedMuseums = await _museumService.fetchMuseums();
      
      setState(() {
        museums = fetchedMuseums;
        isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error in HomePage: $e');
      setState(() {
        errorMessage = 'Errore: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musei'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : museums.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage.isEmpty 
                            ? 'Nessun museo disponibile al momento' 
                            : errorMessage,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchMuseums,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔄', style: TextStyle(fontSize: 24, color: Colors.black)),
                            SizedBox(width: 8),
                            Text('Riprova', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: museums.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _logger.info('Navigating to museum details: ${museums[index]}');
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MuseumDetailPage(
                              museum: museums[index],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3,          // Dà più spazio all'immagine
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: Image.network(
                                  museums[index]['imageUrl'],
                                  fit: BoxFit.cover,  // Cambiato a cover per riempire meglio lo spazio
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,          // Spazio proporzionale per il testo
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  museums[index]['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
                    );
                    },
                  ),
      bottomNavigationBar: const CustomNavbar(),
    );
  }
}

// Use local SQLite database instead of MySQL
// First add sqflite package to pubspec.yaml
// sqflite: ^2.3.0
// path_provider: ^2.1.1

// Then implement local database solution