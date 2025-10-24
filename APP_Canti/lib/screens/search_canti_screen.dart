import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/canti_list.dart';
import '../data/canoni_list.dart';
import 'canti_viewer.dart';

final List<Color> pastelColors = [
  Colors.red.shade100,
  Colors.green.shade100,
  Colors.blue.shade100,
  Colors.orange.shade100,
  Colors.purple.shade100,
  Colors.yellow.shade100,
  Colors.teal.shade100,
  Colors.pink.shade100,
];

class SearchCantiScreen extends StatefulWidget {
  const SearchCantiScreen({super.key});

  @override
  State<SearchCantiScreen> createState() => _SearchCantiScreenState();
}

class _SearchCantiScreenState extends State<SearchCantiScreen> {
  String query = '';
  String momentoSelezionato = 'Tutti';

  final List<String> availableMoments = [
    'Tutti',
    'Ingresso',
    'Gloria',
    'Alleluia',
    'Offertorio',
    'Comunione',
    'Congedo',
    'Canone',
    'Natale',
    'Pasqua',
    'Momenti di Preghiera',
  ];

  @override
  Widget build(BuildContext context) {
    final allItems = <dynamic>[
      ...canti,
      ...canoni,
    ];

    final filteredCanti = allItems.where((item) {
      final queryLower = query.toLowerCase();

      // Controllo titolo
      final titleMatch = item.titolo.toLowerCase().contains(queryLower);

      // Controllo numero (solo per i canti)
      final numberMatch = (item is Canto) && item.numero.toString().contains(queryLower);

      // Canone: momento fisso "Canone"
      if (item is! Canto) {
        return titleMatch && (momentoSelezionato == 'Tutti' || momentoSelezionato == 'Canone');
      }

      // Canto: filtra per momento
      bool momentMatch = momentoSelezionato == 'Tutti' ||
          item.momento1 == momentoSelezionato ||
          (item.momento2 != null && item.momento2 == momentoSelezionato) ||
          (item.momento3 != null && item.momento3 == momentoSelezionato);

      // Restituisce true se titolo o numero corrispondono, e il momento corrisponde
      return (titleMatch || numberMatch) && momentMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Canti'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtra per momento',
            onPressed: () => _apriFiltroMomenti(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Inserisci il titolo o il numero del canto...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCanti.length,
              itemBuilder: (context, index) {
                final item = filteredCanti[index];

                final List<String> cantoMoments = [];
                if (item is Canto) {
                  if (item.momento1.isNotEmpty) cantoMoments.add(item.momento1);
                  if (item.momento2 != null && item.momento2!.isNotEmpty) cantoMoments.add(item.momento2!);
                  if (item.momento3 != null && item.momento3!.isNotEmpty) cantoMoments.add(item.momento3!);
                } else {
                  cantoMoments.add('Canone');
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: (item is Canto) ? Colors.indigo.shade100 : Colors.deepOrange.shade100,
                    child: Text(
                      (item is Canto) ? item.numero.toString() : item.numero,
                      style: TextStyle(
                        color: (item is Canto) ? Colors.indigo : Colors.deepOrangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(item.titolo),
                  subtitle: cantoMoments.isNotEmpty
                      ? Wrap(
                          spacing: 6,
                          children: cantoMoments.map((m) {
                            final color = pastelColors[m.hashCode % pastelColors.length];
                            return Chip(
                              label: Text(
                                m,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                              backgroundColor: color,
                            );
                          }).toList(),
                        )
                      : null,
                  onTap: () async {
                    final assetPath = 'assets/canti_per_app.pdf';

                    if (kIsWeb) {
                      final uri = Uri.parse(assetPath);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, webOnlyWindowName: '_blank');
                        return;
                      }
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CantoPdfPage(
                          pdfPath: assetPath,
                          startPage: item.inizioPagina,
                          endPage: item.finePagina,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _apriFiltroMomenti(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Seleziona momento liturgico',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableMoments.length,
                  itemBuilder: (context, index) {
                    final m = availableMoments[index];
                    final isSelected = momentoSelezionato == m;
                    return ListTile(
                      title: Text(m),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                      onTap: () {
                        setState(() => momentoSelezionato = m);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
