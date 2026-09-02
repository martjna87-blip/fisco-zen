import 'package:fisco_zen/data/wallet_provider.dart';

class RecurrenceManager {
  
  // ---------------------------------------------------------------------------
  // 1. ESTRATTORE DI RADICI (Trova l'ID Padre)
  // ---------------------------------------------------------------------------
  // Qualsiasi ID gli passiamo (es: rec_real_123_2026_9, prev_123_2026_10, rule_123)
  // lui "sbuccia" la stringa e ci restituisce sempre e solo la radice (123).
  static String getRootId(String id) {
    String clean = id.replaceFirst('rule_', '');
    
    if (clean.startsWith('rec_real_')) {
      final parts = clean.split('_');
      if (parts.length >= 5) return parts.sublist(2, parts.length - 2).join('_');
    }
    
    if (clean.startsWith('prev_')) {
      final parts = clean.split('_');
      if (parts.length >= 4) return parts.sublist(1, parts.length - 2).join('_');
    }
    
    final parts = clean.split('_');
    if (parts.length >= 3 && int.tryParse(parts.last) != null && int.tryParse(parts[parts.length - 2]) != null) {
      return parts.sublist(0, parts.length - 2).join('_');
    }
    
    return clean;
  }

  // ---------------------------------------------------------------------------
  // 2. CONTROLLORE DI VITA DELLA RICORRENZA (Vero/Falso)
  // ---------------------------------------------------------------------------
  // Analizza le liste e risponde alla domanda: "Questa ricorrenza ha ancora
  // almeno un mese futuro da pagare, o è stata completamente cancellata/terminata?"
  static bool isRicorrenzaAttiva({
    required String elementId, // L'ID da controllare
    required List<TransactionModel> transactions, // Lista del Wallet
    required List<Map<String, dynamic>> vociReali, // Lista di 2.4
    required List<String> skippedPredictions, // Lista delle eccezioni (skip)
    required DateTime oggi, // La data di oggi
  }) {
    final rootId = getRootId(elementId);
    final meseCorrente = DateTime(oggi.year, oggi.month, 1);

    DateTime? dataFine;

    // A) Cerca la regola madre nel Wallet (transactions)
    final idx = transactions.indexWhere((t) => 
        t.id == rootId || t.id == 'rule_$rootId' || getRootId(t.id) == rootId);

    if (idx != -1) {
      final tx = transactions[idx];
      // Se è archiviata o non più ricorrente, è morta.
      if (!tx.isRecurrent || tx.isArchived) return false; 
      dataFine = tx.dataFineRicorrenza;
    } 
    // B) Se non è nel Wallet, la cerca in 2.4 (vociReali)
    else {
      final pIdx = vociReali.indexWhere((v) => getRootId((v['id'] ?? '').toString()) == rootId);
      if (pIdx != -1) {
        final v = vociReali[pIdx];
        if (v['isArchived'] == true) return false; // Se è archiviata, è morta.
        
        if (v['dataFineRicorrenza'] != null) {
          dataFine = v['dataFineRicorrenza'] is DateTime 
              ? v['dataFineRicorrenza'] as DateTime 
              : DateTime.tryParse(v['dataFineRicorrenza'].toString());
        }
      } else {
        // Non esiste in nessuna delle due liste, è morta.
        return false; 
      }
    }

    // C) Se ha una data di fine ed è già passata, è morta.
    if (dataFine != null && dataFine.isBefore(oggi)) return false;

    // D) LA PROVA DEL NOVECENTO: Scorriamo i mesi futuri.
    // Se non ha data di fine, ipotizziamo un controllo fino a 2 anni nel futuro.
    DateTime limiteControllo = dataFine ?? DateTime(oggi.year + 2, 12, 31);
    DateTime dataCheck = meseCorrente;

    while (!dataCheck.isAfter(limiteControllo)) {
      final key1 = '${rootId}_${dataCheck.year}_${dataCheck.month}';
      final key2 = 'rule_${rootId}_${dataCheck.year}_${dataCheck.month}';
      final key3 = 'rec_real_${rootId}_${dataCheck.year}_${dataCheck.month}';
      final key4 = 'prev_${rootId}_${dataCheck.year}_${dataCheck.month}';

      // Se questo specifico mese NON si trova tra le eccezioni cancellate...
      if (!skippedPredictions.contains(key1) &&
          !skippedPredictions.contains(key2) &&
          !skippedPredictions.contains(key3) &&
          !skippedPredictions.contains(key4)) {
        
        // ...allora BINGO! Abbiamo trovato un mese futuro ancora valido.
        // La regola è viva e vegeta.
        return true; 
      }
      
      // Passa al mese successivo
      dataCheck = DateTime(dataCheck.year, dataCheck.month + 1, 1);
    }

    // Se il ciclo finisce e non ha trovato nemmeno un mese futuro valido 
    // (perché sono tutti tra gli "skipped"), la regola è morta.
    return false; 
  }
}