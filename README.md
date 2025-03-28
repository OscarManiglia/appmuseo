# Museo7

Un'applicazione mobile per la gestione e l'acquisto di biglietti per musei.

## Funzionalità Principali

### Autenticazione
- **Registrazione**: Gli utenti possono creare un nuovo account fornendo i propri dati personali.
- **Login**: Gli utenti registrati possono accedere all'applicazione utilizzando le proprie credenziali.
- **Logout**: Gli utenti possono disconnettersi dall'applicazione.

### Esplorazione Musei
- **Lista Musei**: Visualizzazione di tutti i musei disponibili con informazioni di base.
- **Dettagli Museo**: Visualizzazione delle informazioni dettagliate di un museo specifico, inclusi orari, prezzi e descrizione.
- **Ricerca**: Possibilità di cercare musei per nome o categoria.

### Acquisto Biglietti
1. **Selezione Museo**: L'utente seleziona il museo che desidera visitare.
2. **Selezione Biglietti**: L'utente sceglie il tipo e la quantità di biglietti (bambini, giovani, adulti, senior).
3. **Selezione Data e Ora**: L'utente seleziona la data e l'ora della visita.
4. **Checkout**: Riepilogo dell'ordine con il totale da pagare.
5. **Pagamento**: Processo di pagamento (simulato nell'applicazione).
6. **Conferma**: Dopo il pagamento, viene generato un biglietto con QR code.

### Gestione Biglietti
- **Visualizzazione Biglietti**: Gli utenti possono visualizzare i biglietti acquistati.
- **Dettagli Biglietto**: Visualizzazione delle informazioni dettagliate di un biglietto, incluso il QR code.
- **QR Code**: Ogni biglietto include un QR code che contiene tutte le informazioni necessarie per la validazione.

## Flusso Utente

1. **Registrazione/Login**:
   - L'utente si registra o accede all'applicazione.

2. **Esplorazione**:
   - L'utente naviga tra i musei disponibili.
   - L'utente può visualizzare i dettagli di ciascun museo.

3. **Acquisto**:
   - L'utente seleziona un museo.
   - L'utente sceglie i biglietti desiderati (tipo e quantità).
   - L'utente seleziona data e ora della visita.
   - L'utente procede al checkout.
   - L'utente completa il pagamento.

4. **Post-Acquisto**:
   - L'utente riceve la conferma dell'acquisto.
   - L'utente può visualizzare il biglietto con QR code.
   - Il biglietto viene salvato nell'account dell'utente per future consultazioni.

## Architettura Tecnica

L'applicazione è sviluppata utilizzando:
- **Frontend**: Flutter per un'interfaccia utente cross-platform.
- **Backend**: PHP per la gestione delle API e l'interazione con il database.
- **Database**: MySQL per l'archiviazione dei dati.
- **Generazione QR Code**: Utilizzo della libreria qr_flutter per generare i QR code dei biglietti.

## Requisiti di Sistema

- Flutter SDK
- PHP 7.4 o superiore
- MySQL 5.7 o superiore
- Xampp o ambiente di sviluppo web simile
