import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuggerimentiBugScreen extends StatefulWidget {
  const SuggerimentiBugScreen({super.key});

  @override
  State<SuggerimentiBugScreen> createState() => _SuggerimentiBugScreenState();
}

class _SuggerimentiBugScreenState extends State<SuggerimentiBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _testoController = TextEditingController();
  String _tipo = 'Suggerimento';
  bool _isSending = false;

  Future<void> _inviaSegnalazione() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'tipo': _tipo,
        'testo': _testoController.text.trim(),
        'data': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Segnalazione inviata con successo!')),
      );

      _formKey.currentState!.reset();
      _nomeController.clear();
      _emailController.clear();
      _testoController.clear();
      setState(() => _tipo = 'Suggerimento');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Errore durante l\'invio: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _testoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggerimenti e Bug'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hai trovato un problema o vuoi proporre un miglioramento?\nCompila il modulo qui sotto!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci il tuo nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci la tua email';
                  }
                  if (!value.contains('@')) {
                    return 'Inserisci una email valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo di segnalazione',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Suggerimento', child: Text('Suggerimento')),
                  DropdownMenuItem(value: 'Bug', child: Text('Bug')),
                  DropdownMenuItem(value: 'Commento', child: Text('Commento')),
                ],
                onChanged: (value) => setState(() => _tipo = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _testoController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Descrivi qui il tuo messaggio',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un testo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isSending ? null : _inviaSegnalazione,
                icon: _isSending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Invio...' : 'Invia'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
