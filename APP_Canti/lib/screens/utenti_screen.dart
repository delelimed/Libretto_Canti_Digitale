import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UtentiScreen extends StatefulWidget {
  const UtentiScreen({super.key});

  @override
  State<UtentiScreen> createState() => _UtentiScreenState();
}

class _UtentiScreenState extends State<UtentiScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _utenti = [];
  String? _currentUid; // UID utente loggato

  @override
  void initState() {
    super.initState();
    _currentUid = _auth.currentUser?.uid;
    _loadUtenti();
  }

  Future<void> _loadUtenti() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('coro_users').get();
      _utenti = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'nome': data['nome'] ?? '',
          'cognome': data['cognome'] ?? '',
          'email': data['email'] ?? '',
          'isAdmin': data['isAdmin'] ?? false,
        };
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore caricamento utenti: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _aggiungiUtente() async {
    final nomeController = TextEditingController();
    final cognomeController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAdmin = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aggiungi nuovo utente'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: cognomeController,
                decoration: const InputDecoration(labelText: 'Cognome'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Amministratore'),
                  Switch(
                    value: isAdmin,
                    onChanged: (v) => isAdmin = v,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              final cognome = cognomeController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text.trim();

              if (nome.isEmpty || cognome.isEmpty || email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compila tutti i campi')),
                );
                return;
              }

              try {
                // Crea utente in Firebase Authentication
                final cred = await _auth.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                final uid = cred.user!.uid;

                // Salva dati in Firestore
                await _firestore.collection('coro_users').doc(uid).set({
                  'nome': nome,
                  'cognome': cognome,
                  'email': email,
                  'isAdmin': isAdmin,
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utente aggiunto con successo')),
                  );
                  _loadUtenti();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore creazione utente: $e')),
                  );
                }
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _modificaUtente(Map<String, dynamic> utente) async {
    final nomeController = TextEditingController(text: utente['nome']);
    final cognomeController = TextEditingController(text: utente['cognome']);
    bool isAdmin = utente['isAdmin'];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifica utente'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                enabled: false, // Non modificabile
              ),
              TextField(
                controller: cognomeController,
                decoration: const InputDecoration(labelText: 'Cognome'),
                enabled: false, // Non modificabile
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Amministratore'),
                  Switch(
                    value: isAdmin,
                    onChanged: (v) => isAdmin = v,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('coro_users').doc(utente['uid']).update({
                  'isAdmin': isAdmin,
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utente aggiornato con successo')),
                  );
                  _loadUtenti();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore aggiornamento utente: $e')),
                  );
                }
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminaUtente(Map<String, dynamic> utente) async {
    if (utente['uid'] == _currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non puoi eliminare te stesso')),
      );
      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare ${utente['nome']} ${utente['cognome']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma == true) {
      try {
        await _firestore.collection('coro_users').doc(utente['uid']).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utente eliminato con successo')),
        );
        _loadUtenti();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore eliminazione utente: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utenti'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _aggiungiUtente,
            tooltip: 'Aggiungi utente',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _utenti.isEmpty
              ? const Center(child: Text('Nessun utente registrato'))
              : ListView.separated(
                  itemCount: _utenti.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final utente = _utenti[index];
                    return ListTile(
                      leading: const Icon(Icons.account_circle, color: Colors.indigo),
                      title: Text('${utente['nome']} ${utente['cognome']}'),
                      subtitle: Text(utente['email']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (utente['isAdmin'])
                            const Icon(Icons.admin_panel_settings, color: Colors.red),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _modificaUtente(utente),
                          ),
                          if (utente['uid'] != currentUid)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _eliminaUtente(utente),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
