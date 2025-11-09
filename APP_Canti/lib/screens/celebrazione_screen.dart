import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/canti_list.dart';
import '../data/canoni_list.dart';
import 'canti_viewer.dart';

class CelebrazioneScreen extends StatelessWidget {
  final String titolo;
  final String tipo;
  final DateTime data;
  final Map<String, dynamic> cantiMap;

  const CelebrazioneScreen({
    super.key,
    required this.titolo,
    required this.tipo,
    required this.data,
    required this.cantiMap,
  });

  // Funzione helper per trovare Canto o Canone completo dalla lista
  dynamic _findItemByNumber(dynamic numero) {
    if (numero is int) {
      try {
        return canti.firstWhere((c) => c.numero == numero);
      } catch (e) {
        return null;
      }
    } else if (numero is String) {
      try {
        return canoni.firstWhere((c) => c.numero == numero);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Formatta il numero per la visualizzazione
  String _formatNumero(dynamic numero) {
    if (numero is int) return '#$numero';
    if (numero is String) return numero; // Canone tipo "C01"
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final orario =
        '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

    final List<Widget> cantiWidgets = [];

    if (tipo != 'Penitenziale') {
      const List<String> momentiOrdinati = [
        'Ingresso',
        'Gloria',
        'Alleluia',
        'Offertorio',
        'Santo',
        'Comunione',
        'Congedo',
      ];

      for (final momento in momentiOrdinati) {
        final cantoData = cantiMap[momento];
        if (cantoData != null && cantoData['numero'] != null) {
          final numero = cantoData['numero'];
          final itemCompleto = _findItemByNumber(numero);
          if (itemCompleto == null) continue;

          cantiWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.music_note),
                label: Text(
                  '$momento: ${_formatNumero(itemCompleto.numero)} - ${itemCompleto.titolo}',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  final startPage = itemCompleto.inizioPagina;
                  final endPage = itemCompleto.finePagina;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CantoPdfPage(
                        pdfPath: 'assets/canti_per_app.pdf',
                        startPage: startPage,
                        endPage: endPage,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } else {
      // Penitenziale: ordine salvato in Firestore
      final List<Map<String, dynamic>> penitenziali =
          (cantiMap['penitenziale'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

      for (int i = 0; i < penitenziali.length; i++) {
        final cantoData = penitenziali[i];
        final numero = cantoData['numero'];
        final itemCompleto = _findItemByNumber(numero);
        final titoloCanto = cantoData['titolo'] ?? itemCompleto?.titolo ?? 'Senza titolo';

        final startPage = itemCompleto?.inizioPagina ?? 1;
        final endPage = itemCompleto?.finePagina ?? 10;

        cantiWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.music_note),
              label: Text(
                  'Canto ${i + 1}: ${_formatNumero(numero)} - $titoloCanto'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CantoPdfPage(
                      pdfPath: 'assets/canti_per_app.pdf',
                      startPage: startPage,
                      endPage: endPage,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(titolo.isNotEmpty ? titolo : tipo)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tempo Liturgico: $tipo', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Orario: $orario', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text(
              'Canti della celebrazione:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(child: ListView(children: cantiWidgets)),
          ],
        ),
      ),
    );
  }
}
