import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'celebrazione_screen.dart';

class CelebrazioniGiornaliereScreen extends StatefulWidget {
  const CelebrazioniGiornaliereScreen({super.key});

  @override
  State<CelebrazioniGiornaliereScreen> createState() =>
      _CelebrazioniGiornaliereScreenState();
}

class _CelebrazioniGiornaliereScreenState
    extends State<CelebrazioniGiornaliereScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _celebrazioni = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCelebrazioni();
  }

  Future<void> _loadCelebrazioni() async {
    setState(() => _isLoading = true);
    try {
      final startOfDay =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0);
      final endOfDay =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59);

      final snapshot = await _firestore
          .collection('coro_celebrazioni')
          .where('data',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('data')
          .get();

      _celebrazioni = snapshot.docs.map((doc) {
        final data = doc.data();
        final dateTime = (data['data'] as Timestamp).toDate();
        return {
          'id': doc.id,
          'titolo': data['titolo'] ?? '',
          'tipo': data['tipo'] ?? '',
          'data': dateTime,
          'cantiMap': data['canti'] as Map<String, dynamic>? ?? {},
        };
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento celebrazioni: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _mostraAvviso(BuildContext context, Map<String, dynamic> celeb) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Attenzione',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Ricordati dove ti trovi, cosa stai facendo e Chi stai incontrando.\n\n'
          'Non distrarti al cellulare, usalo solo per i canti.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CelebrazioneScreen(
                    titolo: celeb['titolo'].isNotEmpty
                        ? celeb['titolo']
                        : celeb['tipo'],
                    tipo: celeb['tipo'],
                    data: celeb['data'],
                    cantiMap: (celeb['cantiMap'] as Map<String, dynamic>),
                  ),
                ),
              );
            },
            child: const Text(
              'Ho capito, lo farò',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scegliData(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      await _loadCelebrazioni();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Celebrazioni del Giorno'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Seleziona data',
            onPressed: () => _scegliData(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _celebrazioni.isEmpty
              ? const Center(child: Text('Nessuna celebrazione per questa data'))
              : ListView.builder(
                  itemCount: _celebrazioni.length,
                  itemBuilder: (context, index) {
                    final celeb = _celebrazioni[index];
                    final date = celeb['data'] as DateTime;
                    final orario =
                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    final titolo = celeb['titolo'].isNotEmpty
                        ? celeb['titolo']
                        : celeb['tipo'];

                    return ListTile(
                      title: Text(titolo),
                      subtitle: Text('$orario - ${celeb['tipo']}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _mostraAvviso(context, celeb),
                    );
                  },
                ),
    );
  }
}
