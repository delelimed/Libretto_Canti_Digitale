import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seleziona_canto_screen.dart';

class AggiungiCelebrazioneScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? celebrazioneData;

  const AggiungiCelebrazioneScreen({super.key, this.docId, this.celebrazioneData});

  @override
  State<AggiungiCelebrazioneScreen> createState() =>
      _AggiungiCelebrazioneScreenState();
}

class _AggiungiCelebrazioneScreenState extends State<AggiungiCelebrazioneScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _tipoCelebrazione = 'Tempo Ordinario';
  final TextEditingController _titoloController = TextEditingController();

  final Map<String, Map<String, dynamic>> _canti = {
    'Ingresso': {'numero': null, 'titolo': null},
    'Gloria': {'numero': null, 'titolo': null},
    'Alleluia': {'numero': null, 'titolo': null},
    'Offertorio': {'numero': null, 'titolo': null},
    'Santo': {'numero': null, 'titolo': null},
    'Comunione': {'numero': null, 'titolo': null},
    'Congedo': {'numero': null, 'titolo': null},
  };

  List<Map<String, dynamic>> _cantiPenitenziali = [];

  @override
  void initState() {
    super.initState();
    if (widget.celebrazioneData != null) {
      final data = widget.celebrazioneData!;
      _titoloController.text = data['titolo'] ?? '';
      _tipoCelebrazione = data['tipo'] ?? 'Tempo Ordinario';

      if (data['data'] is Timestamp) {
        final dateTime = (data['data'] as Timestamp).toDate();
        _selectedDate = dateTime;
        _selectedTime = TimeOfDay.fromDateTime(dateTime);
      }

      if (_tipoCelebrazione != 'Penitenziale') {
        if (data['canti'] != null) {
          _canti.forEach((key, value) {
            if (data['canti'][key] != null) {
              _canti[key]!['numero'] = data['canti'][key]['numero'];
              _canti[key]!['titolo'] = data['canti'][key]['titolo'];
            }
          });
        }
      } else {
        if (data['canti'] != null && data['canti']['penitenziale'] != null) {
          _cantiPenitenziali =
              List<Map<String, dynamic>>.from(data['canti']['penitenziale']);
        }
      }
    }
  }

  Future<void> _selezionaData() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selezionaOra() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _selezionaCanto(String momento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelezionaCantoScreen(momentoIniziale: momento),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _canti[momento]!['numero'] = result['numero'];
        _canti[momento]!['titolo'] = result['titolo'];
      });
    }
  }

  Future<void> _selezionaCantoPenitenziale(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelezionaCantoScreen(momentoIniziale: 'Canto ${index + 1}'),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (_cantiPenitenziali.length <= index) {
          _cantiPenitenziali.add({'numero': result['numero'], 'titolo': result['titolo']});
        } else {
          _cantiPenitenziali[index] = {'numero': result['numero'], 'titolo': result['titolo']};
        }
      });
    }
  }

  Future<void> _salvaCelebrazione() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una data')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un orario')),
      );
      return;
    }

    final dateTimeCompleto = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    Map<String, dynamic> dataDaSalvare = {
      'uid': user.uid,
      'data': Timestamp.fromDate(dateTimeCompleto),
      'tipo': _tipoCelebrazione,
      'titolo': _titoloController.text,
      'canti': {},
    };

    if (_tipoCelebrazione != 'Penitenziale') {
      dataDaSalvare['canti'] = _canti.map((key, value) => MapEntry(key, {
            'numero': value['numero'],
            'titolo': value['titolo'],
          }));
    } else {
      dataDaSalvare['canti'] = {
        'penitenziale': _cantiPenitenziali.map((canto) => {
              'numero': canto['numero'],
              'titolo': canto['titolo'],
            }).toList()
      };
    }

    if (widget.docId != null) {
      await _firestore.collection('coro_celebrazioni').doc(widget.docId).update(dataDaSalvare);
    } else {
      await _firestore.collection('coro_celebrazioni').add(dataDaSalvare);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId != null ? 'Modifica Celebrazione' : 'Aggiungi Celebrazione'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titoloController,
              decoration: InputDecoration(
                labelText: 'Titolo (opzionale)',
                prefixIcon: const Icon(Icons.title, color: Colors.indigo),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.church, color: Colors.indigo),
                  const SizedBox(width: 12),
                  const Text(
                    'Tipo:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tipoCelebrazione,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: 'Tempo Ordinario', child: Text('Tempo Ordinario')),
                          DropdownMenuItem(value: 'Tempo di Avvento', child: Text('Tempo di Avvento')),
                          DropdownMenuItem(value: 'Tempo di Natale', child: Text('Tempo di Natale')),
                          DropdownMenuItem(value: 'Tempo di Quaresima', child: Text('Tempo di Quaresima')),
                          DropdownMenuItem(value: 'Tempo di Pasqua', child: Text('Tempo di Pasqua')),
                          DropdownMenuItem(value: 'Settimana Santa', child: Text('Settimana Santa')),
                          DropdownMenuItem(value: 'Penitenziale', child: Text('Penitenziale')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _tipoCelebrazione = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                    title: Text(
                      _selectedDate != null
                          ? 'Data: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Seleziona Data',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: _selezionaData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.indigo),
                    title: Text(
                      _selectedTime != null
                          ? 'Ora: ${_selectedTime!.format(context)}'
                          : 'Seleziona Ora',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: _selezionaOra,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Canti della celebrazione',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: (_tipoCelebrazione != 'Penitenziale')
                  ? ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _canti.keys.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final momento = _canti.keys.elementAt(index);
                        final numero = _canti[momento]!['numero'];
                        final titolo = _canti[momento]!['titolo'];
                        final hasCanto = numero != null && titolo != null;

                        return ListTile(
                          leading: Icon(
                            Icons.music_note,
                            color: hasCanto ? Colors.indigo : Colors.grey,
                          ),
                          title: Text(
                            hasCanto
                                ? '$momento: #$numero - $titolo'
                                : 'Seleziona $momento',
                            style: TextStyle(
                              color: hasCanto ? Colors.black : Colors.black87,
                              fontWeight: hasCanto ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () => _selezionaCanto(momento),
                        );
                      },
                    )
                  : Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cantiPenitenziali.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final numero = _cantiPenitenziali[index]['numero'];
                            final titolo = _cantiPenitenziali[index]['titolo'];
                            return ListTile(
                              leading: Icon(Icons.music_note, color: Colors.indigo),
                              title: Text(numero != null && titolo != null
                                  ? 'Canto ${index + 1}: #$numero - $titolo'
                                  : 'Seleziona Canto ${index + 1}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color.fromARGB(255, 0, 0, 0)),
                              onTap: () => _selezionaCantoPenitenziale(index),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Aggiungi Canto', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() {
                                _cantiPenitenziali.add({'numero': null, 'titolo': null});
                              });
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Salva Celebrazione', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _salvaCelebrazione,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
