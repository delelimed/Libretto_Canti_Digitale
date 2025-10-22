# Aggiornamento dell’Applicazione

Nel tempo verranno rilasciate **nuove versioni** dell’applicazione, contenenti:
- Miglioramenti di sicurezza e stabilità;
- Nuove funzionalità;
- Aggiornamenti manutentivi e ottimizzazioni.

> **Nota:** Prima di procedere, assicurarsi di avere familiarità con le procedure di installazione e gestione del progetto.

---

## 1. Esecuzione del Backup

Prima di ogni aggiornamento, **è fortemente raccomandato eseguire un backup completo** del progetto corrente, in modo da poter ripristinare rapidamente una versione stabile in caso di problemi.

**Procedura:**

1. Aprire il progetto nel proprio editor di codice (ad es. *Visual Studio Code*);
2. Nella struttura delle cartelle del progetto, creare una nuova directory denominata: `Back-UP/`
3. Tagliare tutti i file e le cartelle presenti nella directory `APP_Canti` ed incollarli nella directory appena creata


---

## 2. Download della Nuova Versione

Clonare la versione più recente del repository ufficiale:

```bash
git clone https://github.com/delelimed/APP_CantiPSNDB.git
cd APP_Canti
```

---

## 3. Ripristino dei Dati e Risorse Personalizzate

Per mantenere i dati e gli asset personalizzati della precedente installazione, copiare le risorse generate durante l'installazione nella nuova versione:
    - `Back-UP/assets` in `APP_Canti/assets/`;
    - `Back-UP/lib/data` in `APP_Canti/lib/data`.


## 4. Aggiornamento delle Dipendenze

Aggiornare le dipendenze Flutter per allinearsi alla nuova versione:
```bash
flutter pub get
```
Questo comando scaricherà e configurerà automaticamente tutte le librerie necessarie in base al file `pubspec.yaml`.

## 5. Deploy della Nuova Versione su Web

Per distribuire la nuova build sul web (Firebase Hosting):
```bash
flutter build web --release
firebase deploy --only hosting
```

## (Consigliato) 6. Verifica Post-Deploy

Dopo il completamento del deploy:

1. Aprire la webapp mediante il link precedente (meglio se da PC);
2. Forzare il ricaricamento della pagina 2 - 3 volte
3. Verificare il corretto funzionamento.