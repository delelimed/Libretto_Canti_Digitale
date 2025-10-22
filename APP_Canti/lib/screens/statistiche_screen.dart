import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/canti_list.dart';

class StatisticheScreen extends StatefulWidget {
  const StatisticheScreen({super.key});

  @override
  State<StatisticheScreen> createState() => _StatisticheScreenState();
}

class _StatisticheScreenState extends State<StatisticheScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _inserimenti = [];
  bool _mostraCanti = true;

  Map<String, Map<String, String>> _utentiMap = {}; // uid -> {nome, cognome}
  String _personaSelezionata = 'Tutti';

  @override
  void initState() {
    super.initState();
    _loadInserimenti();
  }

  Future<void> _loadInserimenti() async {
    final celebSnapshot = await _firestore.collection('coro_celebrazioni').get();
    final utentiSnapshot = await _firestore.collection('coro_users').get();

    final Map<String, Map<String, String>> utentiMap = {};
    for (var doc in utentiSnapshot.docs) {
      final data = doc.data();
      utentiMap[doc.id] = {
        'nome': data['nome'] ?? '',
        'cognome': data['cognome'] ?? '',
      };
    }

    final List<Map<String, dynamic>> temp = [];
    for (var doc in celebSnapshot.docs) {
      final data = doc.data();
      final cantiMap = Map<String, dynamic>.from(data['canti'] ?? {});

      cantiMap.forEach((momento, canto) {
        if (momento == 'penitenziale' && canto is List) {
          for (var c in canto) {
            if (c['numero'] != null && c['titolo'] != null) {
              temp.add({
                'numero': c['numero'],
                'titolo': c['titolo'],
                'utenteUid': data['uid'],
                'data': (data['data'] as Timestamp).toDate(),
              });
            }
          }
        } else if (canto['numero'] != null && canto['titolo'] != null) {
          temp.add({
            'numero': canto['numero'],
            'titolo': canto['titolo'],
            'utenteUid': data['uid'],
            'data': (data['data'] as Timestamp).toDate(),
          });
        }
      });
    }

    setState(() {
      _inserimenti = temp;
      _utentiMap = utentiMap;
      _isLoading = false;
    });
  }

  int _conteggioCanto(int numero) {
    if (_personaSelezionata == 'Tutti') {
      return _inserimenti.where((e) => e['numero'] == numero).length;
    } else {
      return _inserimenti
          .where((e) => e['numero'] == numero && e['utenteUid'] == _personaSelezionata)
          .length;
    }
  }

  Map<String, List<Map<String, dynamic>>> _cantiPerUtente(String uid) {
    final userCanti = _inserimenti.where((e) => e['utenteUid'] == uid).toList();
    final Map<String, List<Map<String, dynamic>>> mappa = {};
    for (var e in userCanti) {
      final titolo = e['titolo'];
      if (!mappa.containsKey(titolo)) mappa[titolo] = [];
      mappa[titolo]!.add(e);
    }
    return mappa;
  }

  String _formattaData(DateTime date) {
    final d = date.toLocal();
    final giorno = d.day.toString().padLeft(2, '0');
    final mese = d.month.toString().padLeft(2, '0');
    final anno = d.year.toString();
    return '$giorno/$mese/$anno';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistiche')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final utenti = _inserimenti.map((e) => e['utenteUid']).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              setState(() => _personaSelezionata = value);
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'Tutti', child: Text('Tutti')),
              ...utenti.map<PopupMenuEntry<String>>((uid) {
                final nome = _utentiMap[uid]?['nome'] ?? uid;
                final cognome = _utentiMap[uid]?['cognome'] ?? '';
                return PopupMenuItem<String>(
                  value: uid,
                  child: Text('$nome $cognome'),
                );
              }).toList(),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _mostraCanti = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mostraCanti ? Colors.green : Colors.grey,
                    ),
                    child: const Text('Canti'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _mostraCanti = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_mostraCanti ? Colors.orange : Colors.grey,
                    ),
                    child: const Text('Utenti'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _mostraCanti
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...canti.map((canto) {
                          final count = _conteggioCanto(canto.numero);
                          return ListTile(
                            title: Text(canto.titolo),
                            trailing: Text('$count volte'),
                          );
                        }).toList(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: utenti.map((uid) {
                        final nome = _utentiMap[uid]?['nome'] ?? uid;
                        final cognome = _utentiMap[uid]?['cognome'] ?? '';
                        final cantiUtente = _cantiPerUtente(uid);
                        return ExpansionTile(
                          title: Text('$nome $cognome (${cantiUtente.length})'),
                          children: cantiUtente.entries.map((entry) {
                            final titoloCanto = entry.key;
                            final listaInserimenti = entry.value;
                            return ExpansionTile(
                              title: Text('$titoloCanto (${listaInserimenti.length})'),
                              children: listaInserimenti.map((e) {
                                final data = e['data'] as DateTime;
                                return ListTile(
                                  title: Text(_formattaData(data)),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
