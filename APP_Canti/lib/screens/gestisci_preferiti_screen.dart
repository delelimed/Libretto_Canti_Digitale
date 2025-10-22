import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/canti_list.dart';
import '../data/canoni_list.dart';
import 'canti_viewer.dart';

class GestionePreferitiScreen extends StatefulWidget {
  const GestionePreferitiScreen({super.key});

  @override
  State<GestionePreferitiScreen> createState() => _GestionePreferitiScreenState();
}

class _GestionePreferitiScreenState extends State<GestionePreferitiScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String query = '';
  String momentoSelezionato = 'Tutti';
  bool loading = true;
  List<String> preferiti = [];

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
  void initState() {
    super.initState();
    _caricaPreferiti();
  }

  Future<void> _caricaPreferiti() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('coro_users')
          .doc(user.uid)
          .collection('Preferiti')
          .get();

      setState(() {
        preferiti = doc.docs.map((d) => d.id).toList();
        loading = false;
      });
    } catch (e) {
      print('Errore caricamento preferiti: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _togglePreferito(dynamic item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final itemId = item.numero.toString();
    final ref = _firestore
        .collection('coro_users')
        .doc(user.uid)
        .collection('Preferiti')
        .doc(itemId);

    final isCurrentlyFav = preferiti.contains(itemId);

    setState(() {
      if (isCurrentlyFav) {
        preferiti.remove(itemId);
      } else {
        preferiti.add(itemId);
      }
    });

    try {
      if (!isCurrentlyFav) {
        await ref.set({
          'titolo': item.titolo,
          'tipo': item is Canto ? 'Canto' : 'Canone',
          'momento': item is Canto
              ? [item.momento1, item.momento2, item.momento3]
                  .whereType<String>()
                  .join(', ')
              : 'Canone',
          'data': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.delete();
      }
    } catch (e) {
      print('Errore aggiornamento preferiti: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allItems = <dynamic>[...canti, ...canoni];

    final filteredItems = allItems.where((item) {
      final titleMatch = item.titolo.toLowerCase().contains(query.toLowerCase());

      // Canone
      if (item is! Canto) {
        return titleMatch && (momentoSelezionato == 'Tutti' || momentoSelezionato == 'Canone');
      }

      // Canto
      bool momentMatch = momentoSelezionato == 'Tutti' ||
          item.momento1 == momentoSelezionato ||
          (item.momento2 != null && item.momento2 == momentoSelezionato) ||
          (item.momento3 != null && item.momento3 == momentoSelezionato);

      return titleMatch && momentMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestisci Preferiti'),
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
                hintText: 'Cerca titolo del canto...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text('Nessun canto trovato'),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final numeroFormattato =
                          item.numero.toString().startsWith('C') ? item.numero : '#${item.numero}';
                      final isPreferito = preferiti.contains(item.numero.toString());

                      final List<String> itemMoments = [];
                      if (item is Canto) {
                        if (item.momento1.isNotEmpty) itemMoments.add(item.momento1);
                        if (item.momento2 != null && item.momento2!.isNotEmpty) itemMoments.add(item.momento2!);
                        if (item.momento3 != null && item.momento3!.isNotEmpty) itemMoments.add(item.momento3!);
                      } else {
                        itemMoments.add('Canone');
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text('$numeroFormattato - ${item.titolo}'),
                        subtitle: itemMoments.isNotEmpty ? Text(itemMoments.join(', ')) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye_outlined),
                              tooltip: 'Visualizza canto',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CantoPdfPage(
                                      pdfPath: 'assets/canti_per_app.pdf',
                                      startPage: item.inizioPagina,
                                      endPage: item.finePagina,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isPreferito ? Icons.star : Icons.star_border,
                                color: isPreferito ? Colors.amber : Colors.grey,
                              ),
                              tooltip: isPreferito
                                  ? 'Rimuovi dai preferiti'
                                  : 'Aggiungi ai preferiti',
                              onPressed: () => _togglePreferito(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
