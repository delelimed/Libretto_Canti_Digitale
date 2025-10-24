# Installazione

Questa guida ti aiuta a installare e configurare l'applicazione, personalizzandola in base alle tue esigenze. 

N.B.: per tutti i link riportati, si consiglia di selezionarli con il tasto destro del mouse e di aprirli in una nuova scheda, per non perdere di vista il seguente manuale.

## Requisiti

Assicurati di avere installato:

- [Flutter](https://flutter.dev/docs/get-started/install) (versione stabile consigliata)
- [Dart](https://dart.dev/get-dart) (di solito incluso con Flutter)
- [Node.js](https://nodejs.org/en/download) e Chocolatey
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [Git](https://git-scm.com/)
- Un editor di codice come [VS Code](https://code.visualstudio.com/) o [Android Studio](https://developer.android.com/studio) (necessario per generare l'app Android)

## Clonare il repository
Come prima cosa, apri VS Code.
Apri il terminale e digita:

```bash
git clone https://github.com/delelimed/Libretto-Canti-Digitale.git
cd Libretto_Canti_Digitale
cd APP_Canti
```

Successivamente, installa le dipendenze:

```bash
flutter pub get
```

Questo comando scaricherà tutti i plugin e le librerie necessarie.

Infine, cancella la cartella `docs`, in quanto non necessaria

---

## Preparazione dei Files

Le operazioni indicate di seguito consentiranno di importare nell'applicazione i files necessari al corretto funzionamento dell'applicazione e per una personalizzazione dell'esperienza utente. Siccome è necessario dover mettere materialmente mano al codice, si invita a seguire queste operazioni in modo scrupoloso.

### Importazione delle immagini 

Come prima cosa, recarsi nella posizione `assets/images` ed importare i seguenti files:

- **logo.png**, contenente il logo della parrocchia, se posseduto;
- **sfondo.jpg**, contenente l'immagine che verrà raffigurata all'avvio dell'app e come sfondo nella home.

Se si vuole modificare anche l'icona rispetto alla predefinita, recarsi in `assets/icon` e modificare il file **icon.png**.

### Importazione dei canti

E' necessario importare, sottoforma di unico file pdf, il libretto digitale dei canti.
E' possibile visualizzare il template word da noi realizzato nella cartella "templates" del repository su github, per poterlo eventualmente adattare. A prescindere dallo stile e dal software utilizzato, si consiglia di esportare il PDF in modalità "Pubblicazione Online" / "Minimum Size". Il file cos' generato deve necessariamente essere nominato `canti_per_app.pdf`, da posizionare nella cartella `assets`.

Dalla stessa cartella, copiare i files `canoni_list_template.dart` e `canti_list_template.dart` nella cartella `lib/data`, rinominandoli in `canoni_list.dart` e `canti_list.dart`. Essi contengono la lista dei canti e dei canoni che verranno successivamente mostrati in applicazione. Si procede con un esempio di `canti_list.dart`:

```dart
class Canto {
  final int numero;
  final String titolo;
  final String momento1;
  final String? momento2;
  final String? momento3;
  final int inizioPagina;
  final int finePagina;

  const Canto({
    required this.numero,
    required this.titolo,
    required this.momento1,
    this.momento2,
    this.momento3,
    required this.inizioPagina,
    required this.finePagina,
  });
}

  final List<Canto> canti = [
  Canto(numero: 1, titolo: "titolo", momento1: "Momento", inizioPagina: 1, finePagina: 1),
  Canto(numero: 2, titolo: "titolo", momento1: "UNKNOWN1", momento2: "UNKNOWN2", momento3: "UNKNOWN3", inizioPagina: 2, finePagina: 2), 
  ]
  
```
Del primo blocco (`class Canto` e `const Canto`) non è necessario preoccuparsi. La lista successiva (`final List<Canto> canti ...`) contiene la dichiarazione di tutti i canti inseriti a libretto. In particolare:

- `numero`: contiene il numero progressivo del canto. Campo obbligatorio;
- `titolo`: contiene il titolo del canto. Campo obbligatorio;
- `momentox`: 1<=x<=3. Il `momento1` è obbligatorio, `momento2` e `momento3` sono facoltativi (e possono essere aggiunti o rimossi dal codice). Vedi il capitolo "Gestione Canti" per informazioni su come gestire i momenti;
- `inizioPagina`: il numero di pagina del PDF in cui inizia il canto. Può coincidere con `finePagina`;
- `finePagina`: numero di pagina del PDF in cui il canto finisce. Può coincidere con `inizioPagina`.

---

#### Gestione Canti

La presente webapp supporta solamente i seguenti momenti liturgici, impostabili ai canti (in numero massimo di 3 per canto), per facilitare la ricerca degli stessi:
  - Ingresso;
  - Gloria;
  - Alleluia;
  - Offertorio;
  - Comunione;
  - Congedo;
  - Momenti di Preghiera;
  - Natale;
  - Pasqua;
  - Canone (in file apposito `canoni_list.dart`).

---

### Impostazioni sito web
E' possibile impostare il download del PDF del libro dei canti dal proprio sito web parrocchiale. 
Aprire il file `lib/screens/home_screen.dart` e recarsi alla riga 254, dove è possibile inserire il link al file PDF sul proprio sito web (o da uno spazio google drive). Se non si utilizza questa funzione, è possibile eliminare il pulsante cancellando le righe 252 - 254.

---

### Schema Finale dei files

Di seguito si illustra l'organizzazione dei files modificati che dovrai avere prima di passare alla fase successiva. Le cartelle (`assets/`) sono indicate postponendo lo slash. Non si mostrano i files non oggetto di modifica:

```text
APP_Canti/
|
└─ assets/
      |
      └─ icon/
          |
          └─ icon.png
      |
      └─ images/
          |
          └─ logo.png
          └─ sfondo.png
      |
      └─ canti_per_app.pdf
|
└─ lib/
    |
    └─ data/
        |
        └─ canoni_list.dart
        └─ canti_list.dart
```

---

## Configura Firebase
Firebase è una piattaforma di sviluppo di applicazioni mobili e web fornita da Google. Offre una vasta gamma di servizi backend come un database in tempo reale (Firestore), autenticazione utente, hosting statico, cloud functions, analisi, e altro ancora, permettendo agli sviluppatori di concentrarsi sulla creazione delle esperienze utente senza dover gestire l'infrastruttura del server. È particolarmente popolare nello sviluppo Flutter grazie alla sua facile integrazione.

### Creazione di un nuovo progetto
Per integrare i servizi backend nell'applicazione, è necessario creare un nuovo progetto nella console di Firebase:

1. **Accedi alla Consolle**: Vai alla [Console di Firebase](https://console.firebase.google.com/) ed effettua l'accesso con il tuo account Google (importante: siccome l'accesso alla console consente la visualizzazione e gestione di informazioni "sensibili" per l'applicazione, è conveniente che colui il quale configura firebase sia il responsabile designato alla gestione del coro, o eventualmente delle infrastrutture informatiche della parrocchia).
2. **Crea un Progetto**:
    - Fai clic su "**Aggiungi Progetto**";
    - **Inserisci un nome** al progetto (ex: app-canti). Questo nome è visibile solo a te;
    - **Google Analytics**: Scegli se abilitare o meno Google Analytics per il tuo progetto. Nella versione originale, esso è abilitato;
    - **Configura Analytics**: Se hai abilitato Analytics, seleziona o crea un account Google Analytics e la regione del database (consiglio: TORINO);
    - Fai clic su "**Crea Progetto**".

### Configura Firebase per la tua app

  - Installa **Firebase CLI**
  ```bash 
  npm install -g firebase-tools
  ```
  - Accedi al tuo account firebase:
  ```bash
  firebase login
  ```
  Segui ora la procedura indicata nel browser web. Al termine del processo, dovresti notare una scritta nel terminale che avvisa dell'avvenuto login.
  - Inizializza il progetto Firebase:
  assicurati di trovarti con il terminale nella cartella principale del progetto (la riconosci dalla presenza del file "pubspec.yaml"):
  ```bash
  firebase init
  ```
  Ti chiede conferma, inserisci `Y` e premi invio.
  Durante questa procedura, seleiona muovendoti con le frecce e selezionando con la barra spaziatrice i seguenti servizi da abilitare: 
      - Firestore
      - Remote Config
      - Hosting
    Al termine, premi ENTER
  - Seleziona il progetto creato precedentemente;
  - Alla richiesta `What file should be used for Firestore Rules?` premere semplicemente `ENTER`;
  - Alla richiesta `What file should be used for Firestore indexes?` premere semplicemente `ENTER`;
  - Alla richiesta `What do you want to use as your public directory?` inserire `build/web` e premere `ENTER`;
  - Alla richiesta `Configure as a single-page app (rewrite all urls to /index.html)?` inserire `Y` e premere `ENTER`;
  - Alla richiesta `Set up automatic builds and deploys with GitHub?` inserire `n` e premere `ENTER`;
  - Alla richiesta `What file should be used for your Remote Config template?` premere `ENTER`.

L'inizializzazione di Firebase è ora completata.

## Deploy su WEB

Dopo aver configurato correttamente l'applicazione, è arrivato il momento di caricarla sul web per renderla accessibile pubblicamente. Come prima cosa, abilita la piattaforma web da terminale:

```bash
flutter config --enable-web
flutter devices
```

Dovresti ora vedere un dispositivo come questi:

```bash
Chrome (web) • chrome • web-javascript
```

Compila l'app per il web e caricali su firebase:

```bash
flutter build web --release
firebase deploy --only hosting
```

Al termine, comparirà un avviso come il seguente, con il link per raggiungere la webapp:

```bash
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/<tuo-progetto>
Hosting URL: https://<tuo-progetto>.web.app
```

## Registra il primo utente (ADMIN)
La seguente procedura è necessaria alla creazione di un account di amministratore, che avrà pieni privilegi sull'app. 

> N.B. Esistono due tipi di utente in questa app. La prima è Admin, e consente di inserire tutti gli utenti dell'app. La seconda è "Utente Normale", idealmente riservata ai responsabili dei cori, e consente di inserire tutte le celebrazioni liturgiche. Di seguito è mostrata la procedura per inserire gli amministratori. NON è prevista la registrazione per i fedeli.

  - Recati nella [Console di Firebase](https://console.firebase.google.com/) e seleziona il progetto dell'app.
  - Sulla sinistra, dal menù `BUILD`, seleziona `Authentication`;
  - Seleziona `Email/Password` e `Google` (se non le trovi, vai su `Sign-in Method`);
  - Seleziona `Add user` ed inserisci una coppia di username e password per l'amministratore;
  - Accedi all'App tramite il link generato nella parte precedente;
  - Inserisci Nome, Cognome e Password (opzionale, modifica quella di default inserita);
  - Appare la schermata di gestione celebrazioni. Si consiglia di tornare indietro e fare nuovamente login per abilitare tutte le funzioni dedicate al coro;
  - Recarsi su `BUILD` - `Firestore Database` - `coro_users`. Compaiono tutti gli utenti registrati. Trovare l'utente da rendere admin, selezionare `Add field` - inserire `isAdmin` - Type `boolean` - `true`. Salvare.

## Registra gli utenti successivi (Responsabili Cori)

  - Recati nella [Console di Firebase](https://console.firebase.google.com/) e seleziona il progetto dell'app.
  - Sulla sinistra, dal menù `BUILD`, seleziona `Authentication`;
  - Recati su `Settings` - `User action`;
  - Abilita la voce `Enable create (sign-up)` e seleziona `Save`.
  - Mediante un utente amministratore, entrare in app mediante il link generato sopra, selezionare `IMPOSTAZIONI` - `Utenti` - selezionare il tasto `+` in alto a destra;
  - Compilare con tutte le voci necessarie;
  - Premere `Aggiungi`.

  Questa procedura è ripetibile per tutti gli utenti da associare.
  Dopo aver inserito tutti gli utenti:

  - Recati nella [Console di Firebase](https://console.firebase.google.com/) e seleziona il progetto dell'app.
  - Sulla sinistra, dal menù `BUILD`, seleziona `Authentication`;
  - Recati su `Settings` - `User action`;
  - Disabilita la voce `Enable create (sign-up)` e seleziona `Save`.

