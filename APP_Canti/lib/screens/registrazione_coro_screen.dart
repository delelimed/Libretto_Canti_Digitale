import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'gestione_calendario_screen.dart';

class RegistrazioneCoroScreen extends StatefulWidget {
  final User firebaseUser;

  const RegistrazioneCoroScreen({super.key, required this.firebaseUser});

  @override
  State<RegistrazioneCoroScreen> createState() => _RegistrazioneCoroScreenState();
}

class _RegistrazioneCoroScreenState extends State<RegistrazioneCoroScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _salvaProfilo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = widget.firebaseUser.uid;
      final email = widget.firebaseUser.email!;

      // Aggiorna password solo se l'utente ha effettuato login con email/password
      if (_passwordController.text.isNotEmpty &&
          widget.firebaseUser.providerData.any((p) => p.providerId == 'password')) {
        await widget.firebaseUser.updatePassword(_passwordController.text);
      }

      await _firestore.collection('coro_users').doc(uid).set({
        'nome': _nomeController.text.trim(),
        'cognome': _cognomeController.text.trim(),
        'email': email,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GestioneCalendarioScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la registrazione: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.firebaseUser.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Completa Registrazione')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Completa i tuoi dati per accedere all\'area Coro',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Inserisci il nome' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _cognomeController,
                      decoration: const InputDecoration(labelText: 'Cognome', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Inserisci il cognome' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      initialValue: email,
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password (opzionale)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _salvaProfilo,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Salva e accedi'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
