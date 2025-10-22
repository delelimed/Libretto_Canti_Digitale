import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';

import 'suggerimenti_bug_screen.dart';
import 'informazioni_screen.dart';
import 'home_screen.dart';
import 'statistiche_screen.dart';
import 'utenti_screen.dart';
import 'gestione_calendario_screen.dart';

class ImpostazioniScreen extends StatefulWidget {
  const ImpostazioniScreen({super.key});

  @override
  State<ImpostazioniScreen> createState() => _ImpostazioniScreenState();
}

class _ImpostazioniScreenState extends State<ImpostazioniScreen> {
  bool isLoggedIn = false;
  bool isAdmin = false;
  String? nome;
  String? email;
  bool loading = true;

  // 🔹 Toggle per Google Analytics
  bool analyticsEnabled = false;
  FirebaseAnalytics? analytics;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAnalyticsPreference();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedEmail = prefs.getString('email');
      final savedNome = prefs.getString('nome');
      final savedIsAdmin = prefs.getBool('isAdmin') ?? false;

      setState(() {
        isLoggedIn = savedEmail != null;
        isAdmin = savedIsAdmin;
        nome = savedNome;
        email = savedEmail;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _loadAnalyticsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('analyticsEnabled') ?? false;
    setState(() {
      analyticsEnabled = enabled;
      if (analyticsEnabled) analytics = FirebaseAnalytics.instance;
    });
  }

  Future<void> _setAnalyticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analyticsEnabled', enabled);
    setState(() {
      analyticsEnabled = enabled;
      if (enabled) {
        analytics = FirebaseAnalytics.instance;
      } else {
        analytics = null;
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire il link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Map<String, dynamic>> settingsButtons = [
      {
        'label': 'Mostra Guida',
        'icon': Icons.help_outline,
        'visible': true,
        'onTap': () {
          Navigator.popUntil(context, (route) => route.isFirst);
          Future.delayed(const Duration(milliseconds: 300), () {
            globalShowTutorial?.call();
          });
        },
      },
      {
        'label': 'Statistiche',
        'icon': Icons.bar_chart,
        'visible': isLoggedIn && isAdmin,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticheScreen()),
          );
        },
      },
      {
        'label': 'Utenti',
        'icon': Icons.people,
        'visible': isLoggedIn && isAdmin,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UtentiScreen()),
          );
        },
      },
      {
        'label': 'Gestione Celebrazioni',
        'icon': Icons.event_note,
        'visible': isLoggedIn,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const GestioneCalendarioScreen()),
          );
        },
      },
      {
        'label': 'Informazioni',
        'icon': Icons.info_outline,
        'visible': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InformazioniScreen()),
          );
        },
      },
      {
        'label': 'Suggerimenti e Bug',
        'icon': Icons.bug_report,
        'visible': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SuggerimentiBugScreen()),
          );
        },
      },
      {
        'label':
            'Condividi statistiche anonime di utilizzo per migliorare l\'app',
        'icon': Icons.analytics,
        'visible': true,
        'onTap': null,
        'widget': Switch(
          value: analyticsEnabled,
          onChanged: (v) async {
            await _setAnalyticsEnabled(v);
          },
        ),
      },
    ];

    final visibleButtons =
        settingsButtons.where((b) => b['visible'] as bool).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: visibleButtons.length + 1, // +1 per la tile versione
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          if (index < visibleButtons.length) {
            final btn = visibleButtons[index];
            if (btn.containsKey('widget')) {
              return ListTile(
                leading: Icon(btn['icon'] as IconData, color: Colors.indigo),
                title: Text(btn['label'] as String),
                trailing: btn['widget'] as Widget,
              );
            }
            return ListTile(
              leading: Icon(btn['icon'] as IconData, color: Colors.indigo),
              title: Text(btn['label'] as String),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: btn['onTap'] as VoidCallback?,
            );
          } else {
            // Tile Versioni con dialog
            return ListTile(
              leading: const Icon(Icons.info, color: Colors.indigo),
              title: const Text('Versioni'),
              subtitle: const Text(
                'Versione applicazione: 20251019\n'
                'Versione libro dei canti: 20251019',
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Informazioni'),
                    content: const Text('Sviluppato da DELELIMED'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _openUrl('https://libretto-canti-digitale.readthedocs.io/it/latest/');
                        },
                        child: const Text('Apri manuale utente'),
                      ),
                      TextButton(
                        onPressed: () {
                          _openUrl('https://github.com/DELELIMED');
                        },
                        child: const Text('Apri GitHub'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Chiudi'),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

