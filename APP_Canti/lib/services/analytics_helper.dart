import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsHelper {
  static FirebaseAnalytics? _analytics;
  static bool analyticsEnabled = false;

  /// Inizializza Firebase Analytics e legge il consenso da SharedPreferences
  static Future<void> init() async {
    _analytics = FirebaseAnalytics.instance;

    final prefs = await SharedPreferences.getInstance();
    analyticsEnabled = prefs.getBool('analyticsEnabled') ?? false;

    if (analyticsEnabled) {
      print('📊 Analytics abilitato');
    } else {
      print('📊 Analytics disabilitato');
    }
  }

  /// Aggiorna il consenso e salva in SharedPreferences
  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analyticsEnabled', value);
    analyticsEnabled = value;

    print('📊 Analytics ${value ? "attivato" : "disattivato"}');
  }

  /// Logga un evento (parametri facoltativi)
  static Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (!analyticsEnabled || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(), // 🔹 cast necessario
      );
    } catch (e) {
      print('⚠️ Errore log evento Analytics: $e');
    }
  }

  /// Logga la visualizzazione di una schermata
  static Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (!analyticsEnabled || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': screenName,
          if (screenClass != null) 'screen_class': screenClass,
        },
      );
    } catch (e) {
      print('⚠️ Errore log screen Analytics: $e');
    }
  }

  /// Ritorna se l'analytics è abilitato
  static bool get isEnabled => analyticsEnabled;
}
