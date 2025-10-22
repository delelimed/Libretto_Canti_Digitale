import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'home_screen.dart';
import 'registrazione_coro_screen.dart';

class AccessoCoroScreen extends StatefulWidget {
  const AccessoCoroScreen({super.key});

  @override
  State<AccessoCoroScreen> createState() => _AccessoCoroScreenState();
}

class _AccessoCoroScreenState extends State<AccessoCoroScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = true;
  String? _debugMessage;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  /// 🔹 Controlla se c'è un utente già salvato in locale
  Future<void> _checkUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      print('🔹 Controllo utente salvato: $uid');

      if (uid != null && mounted) {
        Future.microtask(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Errore nel checkUser: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 Login con email e password
  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci email e password')),
      );
      return;
    }

    setState(() => _debugMessage = null);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _onLoginSuccess(credential.user);
    } on FirebaseAuthException catch (e) {
      String message = 'Errore di accesso';
      switch (e.code) {
        case 'user-not-found':
          message = 'Utente non trovato. Controlla l’email.';
          break;
        case 'wrong-password':
          message = 'Password errata. Riprova.';
          break;
        case 'invalid-email':
          message = 'Formato email non valido.';
          break;
        case 'user-disabled':
          message = 'Questo account è stato disabilitato.';
          break;
        case 'too-many-requests':
          message = 'Troppi tentativi di accesso. Riprova più tardi.';
          break;
        case 'network-request-failed':
          message = 'Errore di connessione. Controlla la rete.';
          break;
        default:
          message = 'Errore sconosciuto (${e.code})';
      }

      setState(() => _debugMessage = e.message ?? e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() => _debugMessage = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore generico: $e')));
    }
  }

  /// 🔹 Login con Google (supporta sia Web che Mobile)
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _debugMessage = null);

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final credential = await _auth.signInWithPopup(googleProvider);
        await _onLoginSuccess(credential.user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Sign-In non disponibile su questa build. Usa email/password.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final message = 'Errore di accesso con Google (${e.code})';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _debugMessage = e.message ?? e.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore generico: $e')));
      setState(() => _debugMessage = e.toString());
    }
  }

  /// 🔹 Gestisce il salvataggio e la navigazione
  Future<void> _onLoginSuccess(User? user) async {
    if (user == null) return;

    final docRef = _firestore.collection('coro_users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // 🔹 Utente già registrato: salva in locale e vai alla Home
      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('uid', user.uid);
      await prefs.setString('nome', (data['nome'] ?? user.displayName ?? '').toString());
      await prefs.setString('cognome', (data['cognome'] ?? '').toString());
      await prefs.setString('email', (data['email'] ?? user.email ?? '').toString());
      await prefs.setBool('isAdmin', data['isAdmin'] == true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      // 🔹 Utente autenticato ma non presente in Firestore → vai alla registrazione
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa la registrazione per accedere.')),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrazioneCoroScreen(firebaseUser: user),
          ),
        );
      }
    }
  }

  /// 🔹 Reset password via email
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci la tua email per reimpostare la password')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email di reset inviata a $email')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Errore durante l’invio dell’email di reset';
      if (e.code == 'user-not-found') {
        message = 'Nessun account trovato con questa email.';
      } else if (e.code == 'invalid-email') {
        message = 'Formato email non valido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Accesso Coro')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Accedi con il tuo account del coro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Accedi'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _signInWithEmail,
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Accedi con Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: _signInWithGoogle,
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: _resetPassword,
                child: const Text(
                  'Password dimenticata?',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 20),
              if (_debugMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Debug info:\n$_debugMessage",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
