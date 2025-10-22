import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'aggiungi_celebrazione_screen.dart';

class GestioneCalendarioScreen extends StatefulWidget {
  const GestioneCalendarioScreen({super.key});

  @override
  State<GestioneCalendarioScreen> createState() =>
      _GestioneCalendarioScreenState();
}

class _GestioneCalendarioScreenState extends State<GestioneCalendarioScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _eventi = [];
  bool _onlyMine = true; // default: solo i miei
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1); // inizio mese
    _toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59); // fine mese
    _loadEventi();
  }

  Future<void> _loadEventi() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('coro_celebrazioni')
          .orderBy('data', descending: false)
          .get();

      _eventi = snapshot.docs.map((doc) {
        final data = doc.data();
        final dateTime = (data['data'] as Timestamp).toDate();
        return {
          'id': doc.id,
          'titolo': data['titolo'] ?? '',
          'data': dateTime,
          'tipo': data['tipo'] ?? '',
          'uid': data['uid'] ?? '',
          'canti': data['canti'] ?? {},
        };
      }).toList();

      _eventi.sort((a, b) => a['data'].compareTo(b['data']));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento eventi: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _eliminaEvento(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('coro_celebrazioni').doc(id).delete();
    _loadEventi();
  }

  Future<void> _modificaEvento(String id, Map<String, dynamic> data) async {
    final celebrazioneData = {
      ...data,
      'data': data['data'] is Timestamp
          ? (data['data'] as Timestamp).toDate()
          : data['data'],
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AggiungiCelebrazioneScreen(
          docId: id,
          celebrazioneData: celebrazioneData,
        ),
      ),
    );
    if (result == true) _loadEventi();
  }

  void _mostraDettagli(Map<String, dynamic> evento) {
    const List<String> ordineCanti = [
      'Ingresso',
      'Gloria',
      'Alleluia',
      'Offertorio',
      'Comunione',
      'Congedo',
    ];

    final data = evento['data'] as DateTime;
    final oraFormattata =
        '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

    final uidInseritore = evento['uid'] as String;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(evento['titolo'].isNotEmpty ? evento['titolo'] : evento['tipo']),
        content: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('coro_users').doc(uidInseritore).get(),
          builder: (context, snapshot) {
            String nomeCompleto = uidInseritore;
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!.exists) {
              final dataUser = snapshot.data!.data() as Map<String, dynamic>;
              final nome = dataUser['nome'] ?? '';
              final cognome = dataUser['cognome'] ?? '';
              nomeCompleto = '$nome $cognome';
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo: ${evento['tipo']}'),
                  Text('Data: ${data.day}/${data.month}/${data.year} alle $oraFormattata'),
                  const SizedBox(height: 10),
                  Text('Utente Inseritore: $nomeCompleto',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'Canti:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...ordineCanti
                      .where((tipo) => evento['canti'].containsKey(tipo))
                      .map((tipo) {
                    final c = evento['canti'][tipo];
                    if (c == null) return const SizedBox.shrink();
                    return Text(
                        '${tipo}: ${c['numero'] is String && c['numero'].startsWith('C') ? '' : '#'}${c['numero'] ?? '-'} - ${c['titolo'] ?? '-'}');
                  }).toList(),
                  if (evento['canti'].containsKey('penitenziale'))
                    ...List<Map<String, dynamic>>.from(evento['canti']['penitenziale'])
                        .asMap()
                        .entries
                        .map((entry) {
                      final idx = entry.key;
                      final c = entry.value;
                      return Text(
                          'Penitenziale Canto ${idx + 1}: ${c['numero'] is String && c['numero'].startsWith('C') ? '' : '#'}${c['numero'] ?? '-'} - ${c['titolo'] ?? '-'}');
                    }),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestione Calendario')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi Celebrazione'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AggiungiCelebrazioneScreen(),
                        ),
                      );
                      if (result == true) _loadEventi();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SwitchListTile(
                    title: const Text('Mostra solo miei inserimenti'),
                    value: _onlyMine,
                    onChanged: (val) => setState(() => _onlyMine = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null)
                              setState(() => _fromDate = picked);
                          },
                          child: Text(
                            _fromDate == null
                                ? 'Da'
                                : 'Da: ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _toDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null)
                              setState(() => _toDate = picked);
                          },
                          child: Text(
                            _toDate == null
                                ? 'A'
                                : 'A: ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reset filtri data',
                        onPressed: () => setState(() {
                          final now = DateTime.now();
                          _fromDate = DateTime(now.year, now.month, 1);
                          _toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                        }),
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      List<Map<String, dynamic>> shownEvents = _eventi;
                      if (_onlyMine && currentUid != null) {
                        shownEvents =
                            shownEvents.where((e) => e['uid'] == currentUid).toList();
                      }

                      if (_fromDate != null) {
                        shownEvents = shownEvents.where((e) {
                          final d = e['data'] as DateTime;
                          return !d.isBefore(_fromDate!);
                        }).toList();
                      }

                      if (_toDate != null) {
                        shownEvents = shownEvents.where((e) {
                          final d = e['data'] as DateTime;
                          return !d.isAfter(_toDate!);
                        }).toList();
                      }

                      if (shownEvents.isEmpty) {
                        return const Center(
                          child: Text('Nessuna celebrazione presente'),
                        );
                      }

                      return ListView.builder(
                        itemCount: shownEvents.length,
                        itemBuilder: (context, index) {
                          final evento = shownEvents[index];
                          final isOwner = evento['uid'] == currentUid;
                          final data = evento['data'] as DateTime;
                          final oraFormattata =
                              '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

                          return ListTile(
                            title: Text(
                              evento['titolo'].isNotEmpty
                                  ? evento['titolo']
                                  : evento['tipo'],
                            ),
                            subtitle: Text(
                              '${data.day}/${data.month}/${data.year} - $oraFormattata  •  ${evento['tipo']}',
                            ),
                            onTap: () => _mostraDettagli(evento),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isOwner)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () =>
                                        _modificaEvento(evento['id'], evento),
                                  ),
                                if (isOwner)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _eliminaEvento(evento['id']),
                                  ),
                              ],
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
}
