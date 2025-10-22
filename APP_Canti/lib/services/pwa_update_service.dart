import 'dart:html' as html;
import 'package:flutter/material.dart';

class PwaUpdateService {
  final BuildContext context;

  PwaUpdateService(this.context);

  void checkForUpdate() {
    html.window.navigator.serviceWorker?.getRegistrations().then((regs) {
      for (final reg in regs) {
        reg.update().then((_) {
          reg.onUpdateFound.listen((_) {
            final newWorker = reg.installing;
            if (newWorker != null) {
              newWorker.onStateChange.listen((_) {
                if (newWorker.state == 'installed') {
                  // Mostra SnackBar per aggiornamento
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Nuova versione disponibile!'),
                      action: SnackBarAction(
                        label: 'Ricarica',
                        onPressed: () {
                          html.window.location.reload();
                        },
                      ),
                    ),
                  );
                }
              });
            }
          });
        });
      }
    });
  }
}
