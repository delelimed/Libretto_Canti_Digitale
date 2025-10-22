import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';
import 'services/analytics_helper.dart';
import 'services/analytics_observer.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inizializzazione di Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Inizializzazione AnalyticsHelper
  await AnalyticsHelper.init();

  runApp(const CantiApp());
}

class CantiApp extends StatelessWidget {
  const CantiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canti Liturgici',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      navigatorObservers: [
        AnalyticsRouteObserver(),
      ], // <-- qui registri l'observer
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
