import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/canti_list.dart';
import '../data/canoni_list.dart';
import 'canti_viewer.dart';

class SelezionaCantoScreen extends StatefulWidget {
  final String momentoIniziale;

  const SelezionaCantoScreen({super.key, required this.momentoIniziale});

  @override
  State<SelezionaCantoScreen> createState() => _SelezionaCantoScreenState();
}

class _SelezionaCantoScreenState extends State<SelezionaCantoScreen> {
  String query = '';
  int? selectedCantoNumero;
  late String momentoSelezionato;
  bool mostraSoloPreferiti = false;
  List<String> preferiti = [];
  bool loading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    momentoSelezionato =
        widget.momentoIniziale.isNotEmpty ? widget.momentoIniziale : 'Tutti';
    _caricaPreferiti();
  }

  Future<void> _caricaPreferiti() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('coro_users')
          .doc(user.uid)
          .collection('Preferiti')
          .get();

      setState(() {
        preferiti = snapshot.docs.map((d) => d.id).toList();
        loading = false;
      });
    } catch (e) {
      print("Errore caricamento preferiti: $e");
      setState(() => loading = false);
    }
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
      final queryLower = query.toLowerCase();
      final titleMatch = item.titolo.toLowerCase().contains(queryLower);
      final numberMatch = item.numero.toString().contains(queryLower);

      if (mostraSoloPreferiti && !preferiti.contains(item.numero.toString())) {
        return false;
      }

      if (item is! Canto) {
        return titleMatch &&
            (momentoSelezionato == 'Tutti' || momentoSelezionato == 'Canone');
      }

      final momentMatch = momentoSelezionato == 'Tutti' ||
          item.momento1 == momentoSelezionato ||
          (item.momento2 != null && item.momento2 == momentoSelezionato) ||
          (item.momento3 != null && item.momento3 == momentoSelezionato);

      return (titleMatch || numberMatch) && momentMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(mostraSoloPreferiti
            ? 'Preferiti (${momentoSelezionato})'
            : 'Canti (${momentoSelezionato})'),
        actions: [
          IconButton(
            icon: Icon(
              mostraSoloPreferiti ? Icons.star : Icons.star_border,
              color: mostraSoloPreferiti ? Colors.amber : null,
            ),
            tooltip: mostraSoloPreferiti
                ? 'Mostra tutti i canti'
                : 'Mostra solo preferiti',
            onPressed: () {
              setState(() {
                mostraSoloPreferiti = !mostraSoloPreferiti;
              });
            },
          ),
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
              decoration: const InputDecoration(
                labelText: 'Cerca per titolo o numero',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => query = val),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text('Nessun canto trovato per questo filtro'),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final numeroFormattato = item.numero.toString().startsWith('C')
                          ? item.numero
                          : '#${item.numero}';
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
                        title: Text('$numeroFormattato - ${item.titolo}'),
                        subtitle: itemMoments.isNotEmpty ? Text(itemMoments.join(', ')) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPreferito)
                              const Icon(Icons.star, color: Colors.amber),
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
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context, {
                            'numero': item.numero,
                            'titolo': item.titolo,
                          });
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
    final momenti = [
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: momenti.length,
                  itemBuilder: (context, index) {
                    final m = momenti[index];
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

