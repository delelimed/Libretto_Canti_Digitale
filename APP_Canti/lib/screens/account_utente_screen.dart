import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'gestione_calendario_screen.dart';
import 'gestisci_preferiti_screen.dart';

class AccountUtenteScreen extends StatefulWidget {
  const AccountUtenteScreen({super.key});

  @override
  State<AccountUtenteScreen> createState() => _AccountUtenteScreenState();
}

class _AccountUtenteScreenState extends State<AccountUtenteScreen> {
  String nome = '';
  String cognome = '';
  String email = '';
  bool loading = true;

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        nome = prefs.getString('nome') ?? '';
        cognome = prefs.getString('cognome') ?? '';
        email = prefs.getString('email') ?? _auth.currentUser?.email ?? '';
        loading = false;
      });
    } catch (e) {
      print('Errore caricamento dati utente: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _cambiaPassword() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final vecchiaPasswordController = TextEditingController();
    final nuovaPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambia password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: vecchiaPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password attuale',
                  hintText: 'Inserisci la password attuale',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nuovaPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nuova password',
                  hintText: 'Inserisci la nuova password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPassword = vecchiaPasswordController.text.trim();
                final newPassword = nuovaPasswordController.text.trim();

                if (oldPassword.isEmpty || newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compila entrambi i campi')),
                  );
                  return;
                }

                try {
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: oldPassword,
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPassword);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password aggiornata con successo'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('uid');
      await prefs.remove('nome');
      await prefs.remove('cognome');
      await prefs.remove('email');
      await prefs.remove('isAdmin');

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout effettuato')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il logout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Utente'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.indigo),
            const SizedBox(height: 16),
            _infoTile('Nome', nome),
            _infoTile('Cognome', cognome),
            _infoTile('Email', email),
            const SizedBox(height: 24),

            // 🔹 Banner informativo
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La funzione "Gestisci Templates" sarà disponibile nelle prossime settimane.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Gestisci Templates (disattivato)
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.article_outlined),
              label: const Text('Gestisci Templates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Gestisci Celebrazioni
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestioneCalendarioScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Gestisci Celebrazioni'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Gestisci Preferiti
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GestionePreferitiScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.favorite_border),
              label: const Text('Gestisci Preferiti'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Cambia password
            ElevatedButton.icon(
              onPressed: _cambiaPassword,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Cambia password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Logout
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      leading: const Icon(Icons.info_outline, color: Colors.indigo),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value.isNotEmpty ? value : 'Non disponibile'),
    );
  }
}
