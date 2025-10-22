import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../widgets/home_button.dart';
import 'search_canti_screen.dart';
import 'accesso_coro_screen.dart';
import 'account_utente_screen.dart';
import 'celebrazioni_giornaliere_screen.dart';
import 'impostazioni_screen.dart';

// 🔹 callback globale per far partire la guida da altre schermate
Function()? globalShowTutorial;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  bool isLoading = true;

  // Chiavi per i target del tutorial
  final keyButtonCelebrazioni = GlobalKey();
  final keyButtonCanti = GlobalKey();
  final keyButtonDownload = GlobalKey();
  final keyButtonImpostazioni = GlobalKey();
  final keyButtonAccount = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');
    final cognome = prefs.getString('cognome');

    if (nome != null && cognome != null) {
      setState(() => userName = '$nome $cognome');
    }

    setState(() => isLoading = false);

    // Imposta la callback globale per richiamare la guida da fuori
    globalShowTutorial = _showTutorial;

    // Dopo il caricamento, chiediamo se mostrare la guida
    Future.delayed(const Duration(milliseconds: 500), _askToShowTutorial);
  }

  Future<void> _askToShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seenTutorial = prefs.getBool('seenTutorial') ?? false;

    if (!seenTutorial && mounted) {
      final show = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Vuoi vedere la guida?"),
          content: const Text(
              "Ti mostreremo una breve introduzione alle funzioni principali dell'app."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No, grazie"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sì, mostra la guida"),
            ),
          ],
        ),
      );

      if (show == true) {
        await prefs.setBool('seenTutorial', true);
        _showTutorial();
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      if (kIsWeb) {
        await launchUrl(uri, webOnlyWindowName: '_blank');
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // 🔹 TUTORIAL
  void _showTutorial() {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "celebrazioni",
        keyTarget: keyButtonCelebrazioni,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "Celebrazioni del giorno\n\nVisualizza i canti delle celebrazioni odierne.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "canti",
        keyTarget: keyButtonCanti,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "Cerca Canti\n\nTrova canti per titolo o momento liturgico.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "download",
        keyTarget: keyButtonDownload,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Scarica il Libretto\n\nOttieni il libretto completo dei canti dal sito parrocchiale.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "impostazioni",
        keyTarget: keyButtonImpostazioni,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Impostazioni\n\nPersonalizza l'app secondo le tue preferenze.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        ],
      ),
      TargetFocus(
        identify: "account",
        keyTarget: keyButtonAccount,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              "Accesso Coro\n\nAccesso riservato ai responsabili del coro per impostare i canti delle celebrazioni.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        ],
      ),
    ];

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black87,
      textSkip: "SALTA",
      paddingFocus: 10,
      opacityShadow: 0.8,
    );

    tutorial.show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      {'label': 'CELEBRAZIONI DEL GIORNO', 'icon': Icons.event, 'key': keyButtonCelebrazioni},
      {'label': 'CERCA CANTI', 'icon': Icons.search, 'key': keyButtonCanti},
      {'label': 'SCARICA LIBRETTO', 'icon': Icons.download, 'key': keyButtonDownload},
      {'label': 'IMPOSTAZIONI', 'icon': Icons.settings, 'key': keyButtonImpostazioni},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canti Liturgici'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/images/sfondo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: buttons.map((b) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: HomeButton(
                                key: b['key'] as GlobalKey,
                                label: b['label'] as String,
                                icon: b['icon'] as IconData,
                                onPressed: () async {
                                  switch (b['label']) {
                                    case 'CELEBRAZIONI DEL GIORNO':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CelebrazioniGiornaliereScreen(),
                                        ),
                                      );
                                      break;
                                    case 'CERCA CANTI':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const SearchCantiScreen(),
                                        ),
                                      );
                                      break;
                                    case 'SCARICA LIBRETTO':
                                      const url =
                                          'https://snicoladabarimentana.it/download/libretto-dei-canti/';
                                      await _openUrl(url);
                                      break;
                                    case 'IMPOSTAZIONI':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ImpostazioniScreen(),
                                        ),
                                      );
                                      break;
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(color: Colors.grey, thickness: 1),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _openUrl('https://delelimed.github.io/'),
                        child: const Text(
                          'Developed by DELELIMED',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      HomeButton(
                        key: keyButtonAccount,
                        label: userName ?? 'ACCESSO CORO',
                        icon: userName != null ? Icons.person : Icons.lock_open,
                        onPressed: () {
                          if (userName != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountUtenteScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccessoCoroScreen(),
                              ),
                            ).then((_) => _loadUser());
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
