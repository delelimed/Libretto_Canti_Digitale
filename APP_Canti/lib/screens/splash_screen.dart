import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'home_screen.dart';
import 'maintenance_screen.dart';

import 'package:flutter/foundation.dart';
import '../services/pwa_update_service.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  FirebaseAnalytics? analytics;

  @override
  void initState() {
    super.initState();

    // 🔹 Animazione splash
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 🔹 Controllo consent + Remote Config
    Future.delayed(Duration.zero, _initSplashFlow);
  }

  Future<void> _initSplashFlow() async {
    await _checkAnalyticsConsent();
    await _checkMaintenanceMode();

    if (kIsWeb && mounted) {
        PwaUpdateService(context).checkForUpdate();
      }
  }

  Future<void> _checkAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getBool('analyticsConsent');

    if (consent == null) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Condivisione dati anonimi (facoltativa)'),
          content: const Text(
            'L\'app può raccogliere dati anonimi e aggregati sull\'uso dell\'app '
            'per capire come gli utenti utilizzano l\'app e migliorare l\'esperienza. '
            'La partecipazione è facoltativa e puoi cambiare idea in qualsiasi momento nelle impostazioni.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, grazie'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sì, acconsento'),
            ),
          ],
        ),
      );
      await prefs.setBool('analyticsConsent', result ?? false);
      if (result == true) analytics = FirebaseAnalytics.instance;
    } else {
      if (consent) analytics = FirebaseAnalytics.instance;
    }
  }

  Future<void> _checkMaintenanceMode() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );

      await remoteConfig.setDefaults(const {'is_maintenance_mode': false});
      await remoteConfig.fetchAndActivate();

      bool isMaintenance = remoteConfig.getBool('is_maintenance_mode') ?? false;

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      if (isMaintenance) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('⚠️ Errore Remote Config: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        // 🔹 Sfondo
        Image.asset(
          'assets/images/sfondo.jpg',
          fit: BoxFit.cover,
          //alignment: Alignment.topCenter,
        ),

        // 🔹 Sovrapposizione scura per leggibilità
        Container(
          color: Colors.black.withOpacity(0.3),
        ),

        // 🔹 Contenuto verticale
        Column(
          children: [
            const Spacer(flex: 3), // spinge il testo verso il centro

            // Testo animato
            FadeTransition(
              opacity: _animation,
              child: const Text(
                "CANTI LITURGICI",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black54,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 4), // spinge il logo verso il basso

            // 🔹 Logo parrocchiale
            Padding(
              padding: const EdgeInsets.only(bottom: 40), // distanza dal fondo
              child: Image.asset(
                'assets/images/logo.png',
                height: 80, // puoi regolare
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
