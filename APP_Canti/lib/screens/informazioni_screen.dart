import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InformazioniScreen extends StatelessWidget {
  const InformazioniScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Mostra un messaggio in caso di errore
      throw 'Impossibile aprire il link: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informazioni e Privacy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SezioneTitolo('Scopo dell\'app'),
            const Text(
              'Questa applicazione ha lo scopo di facilitare la partecipazione '
              'alle celebrazioni liturgiche, mostrando i canti utilizzati durante le messe '
              'e fornendo supporto al coro parrocchiale ed a tutti i fedeli partecipanti.',
            ),
            const SizedBox(height: 24),

            const _SezioneTitolo('Diritti dei canti e contenuti'),
            const Text(
              'Tutti i testi e i diritti dei canti presenti nell\'app appartengono '
              'ai rispettivi autori e/o editori musicali. L\'app non detiene alcun diritto '
              'sui contenuti musicali ma si limita a raccogliere e mostrare testi già pubblici '
              'ai fini pastorali e non commerciali.',
            ),
            const SizedBox(height: 24),

            const _SezioneTitolo('Trattamento dei dati personali'),
            const Text(
              'L\'app utilizza i servizi di Firebase (forniti da Google LLC) per garantire '
              'il corretto funzionamento tecnico, la sicurezza e l\'autenticazione degli utenti '
              'appartenenti al coro parrocchiale. I dati raccolti sono limitati al minimo necessario '
              'per permettere il funzionamento dell\'app e non vengono ceduti a terzi né utilizzati '
              'per fini commerciali.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Gli utenti non registrati possono utilizzare l\'app liberamente senza fornire '
              'alcun dato personale. Gli utenti del coro che effettuano il login hanno i propri '
              'dati (nome, cognome, email e ruolo) salvati in modo sicuro su Firebase Authentication '
              'e Firestore, accessibili solo agli amministratori autorizzati.',
            ),
            const SizedBox(height: 24),

            const _SezioneTitolo('Firebase e Google Analytics'),
            const Text(
              'Al primo avvio dell\'app viene richiesto all\'utente se desidera contribuire '
              'in modo anonimo al miglioramento dell\'app attraverso Google Analytics for Firebase. '
              'Questa scelta è completamente facoltativa e può essere modificata in qualsiasi momento '
              'dalle impostazioni dell\'app.',
            ),
            const SizedBox(height: 8),
            const Text(
              'I dati eventualmente raccolti sono trattati in forma aggregata e anonima, '
              'esclusivamente a fini statistici e per comprendere meglio come gli utenti '
              'utilizzano l\'app, così da migliorarne le funzionalità e l\'esperienza d\'uso. '
              'Nessuna informazione personale identificabile viene raccolta o associata all\'utente.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Gli utenti possono disattivare in qualsiasi momento la raccolta anonima dei dati '
              'di utilizzo tramite le impostazioni della app. ',
            ),
            const SizedBox(height: 24),

            const _SezioneTitolo('Conservazione dei dati'),
            const Text(
              'I dati relativi agli utenti del coro vengono conservati finché l\'account rimane attivo '
              'o fino alla richiesta di cancellazione. In qualsiasi momento è possibile richiedere '
              'la modifica o l\'eliminazione dei propri dati personali.',
            ),
            const SizedBox(height: 24),

            const _SezioneTitolo('Diritti dell\'utente (GDPR)'),
            const Text(
              'In conformità al Regolamento UE 2016/679 (GDPR), ogni utente ha diritto a:'
              '\n• accedere ai propri dati personali;'
              '\n• richiederne la rettifica o cancellazione;'
              '\n• limitare o opporsi al trattamento;'
              '\n• revocare il consenso in qualsiasi momento;'
              '\n• proporre reclamo al Garante per la protezione dei dati personali.',
            ),
            const SizedBox(height: 24),

            const _SezioneTitolo('Note finali'),
            const Text(
              'Questa app è un progetto senza fini di lucro, realizzato per uso pastorale interno. '
              'L\'utilizzo dell\'app implica l\'accettazione della presente informativa sulla privacy.',
            ),
            const SizedBox(height: 40),

            // 🔹 Pulsante "Apri manuale utente"
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _openUrl('https://libretto-canti-digitale.readthedocs.io/it/latest/');
                },
                child: const Text('Apri manuale utente'),
              ),
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Ultimo aggiornamento: ottobre 2025',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Widget per titolo sezione
class _SezioneTitolo extends StatelessWidget {
  final String titolo;
  const _SezioneTitolo(this.titolo);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titolo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }
}

/// 🔹 Widget per contatto email cliccabile
class _ContattoEmail extends StatelessWidget {
  final String email;
  const _ContattoEmail({required this.email});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri(
          scheme: 'mailto',
          path: email,
          query: Uri.encodeFull('subject=Richiesta informazioni app'),
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Text(
        email,
        style: const TextStyle(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
          fontSize: 16,
        ),
      ),
    );
  }
}
