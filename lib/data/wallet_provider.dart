import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; 
import 'package:flutter/material.dart';

class AccountModel {
  final String id;
  String title; 
  final String subtitle;
  double amount;
  double virtualTaxAmount; // 👈 NOVITÀ: Quota tasse accantonata su questo conto
  final Color color;

  AccountModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.virtualTaxAmount = 0.0, // Di default è 0
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'virtualTaxAmount': virtualTaxAmount, // 👈 Salvataggio in memoria
        'color': color.value,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        amount: (json['amount'] as num).toDouble(),
        virtualTaxAmount: (json['virtualTaxAmount'] as num?)?.toDouble() ?? 0.0, // 👈 Se vecchi dati non lo hanno, mette 0
        color: Color(json['color'] as int),
      );
}

class TransactionModel {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final String category;
  final DateTime date;
  final String? accountId; // 👈 NUOVO CAMPO

  TransactionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
    this.accountId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'isIncome': isIncome,
        'category': category,
        'date': date.toIso8601String(),
        'accountId': accountId,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'] as bool,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        accountId: json['accountId'] as String?,
      );
}

class WalletProvider extends ChangeNotifier {
  List<AccountModel> _accounts = [
    AccountModel(id: '1', title: 'Conto Principale (IBAN)', subtitle: 'Banca Fineco •• 4092', amount: 0.00, color: const Color(0xFF2DD4BF)),
    AccountModel(id: '2', title: 'Carta Spese & Svago', subtitle: 'Revolut Digital •• 1102', amount: 0.00, color: const Color(0xFFF59E0B)),
    AccountModel(id: '3', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6)),
    AccountModel(id: '4', title: 'Salvadanaio Acconto Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6)),

  ];

  List<AccountModel> get accounts => List.unmodifiable(_accounts);

// ==========================================
  // ⚙️ CONFIGURAZIONE E MATEMATICA FISCALE ATECO
  // ==========================================
  bool isPartitaIVA = true; 
  double accontiVersatiAnnoPrecedente = 100.0; // 👈 Credito tasse dell'anno scorso
  
  // Parametri Fiscali (Regime Forfettario Ateco)
  double coeffRedditivita = 0.78; // Ateco 78%
  double aliquotaImposta = 0.05;  // Imposta Sostitutiva 5%
  double aliquotaInps = 0.2607;   // INPS Gestione Separata 26.07%

  // 🎯 CALCOLO PRECISO DELL'ALIQUOTA FISCALE REALE (Totalizza 44.402%)
  double get aliquotaFiscaleReale {
    final imponibile = coeffRedditivita;                 // 0.78 su 1€
    final saldoInps = imponibile * aliquotaInps;         // ~20.335%
    final saldoImposta = imponibile * aliquotaImposta;   // ~3.900%
    final accontoInps = saldoInps * 0.80;                // ~16.268%
    final accontoImposta = saldoImposta * 1.00;          // ~3.900%
    return saldoInps + saldoImposta + accontoInps + accontoImposta;
  }

  // 🔄 Cambia profilo (P.IVA vs Dipendente) e aggiorna subito l'interfaccia
  void setPartitaIVA(bool value) {
    isPartitaIVA = value;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // ==========================================
  // 📊 MATEMATICA E STATISTICHE GLOBALI
  // ==========================================

  // 1. Saldo Reale in Banca (La somma dei conti reali)
  double get patrimonioNetto => _accounts.fold(0.0, (sum, item) => sum + item.amount);

  // 2. Fondo Tasse Lordo (Tutte le tasse generate dagli incassi)
  double get _tasseLordeAccantonate => _accounts.fold(0.0, (sum, item) => sum + item.virtualTaxAmount);

  // 3. FONDO TASSE DA VERSARE (Tiene conto dell'Acconto!)
  double get fondoTasseDaVersare {
    double fondo = _tasseLordeAccantonate - accontiVersatiAnnoPrecedente;
    return fondo > 0 ? fondo : 0.0; // Non scende mai sotto zero
  }

  // 4. NETTO SPENDIBILE 🟢 (Il vero potere d'acquisto)
  double get nettoSpendibile => patrimonioNetto - fondoTasseDaVersare;

  double _spesoBisogni = 0.00;
  double get spesoBisogni => _spesoBisogni;

  double _spesoSvago = 0.00;
  double get spesoSvago => _spesoSvago;

  double _spesoRisparmi = 0.00;
  double get spesoRisparmi => _spesoRisparmi;

  double _fatturatoTotale = 0.00;
  double get fatturatoTotale => _fatturatoTotale;

  // Stima Globale collegata alla matematica Ateco esatta!
  double get stimaTasseAccantonate => _fatturatoTotale * aliquotaFiscaleReale;
  double get nettoPiva => _fatturatoTotale - stimaTasseAccantonate;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  List<Map<String, dynamic>> _fattureDaIncassare = [];
  List<Map<String, dynamic>> get fattureDaIncassare => List.unmodifiable(_fattureDaIncassare);

  List<Map<String, dynamic>> _fattureIncassate = [];
  List<Map<String, dynamic>> get fattureIncassate => List.unmodifiable(_fattureIncassate);

  WalletProvider() {
    _caricaDatiDaLocalStorage();
  }

  // 🗑️ 1. ELIMINA UN CONTO
  void deleteAccount(String accountId) {
    // Blocco di sicurezza: deve esserci sempre almeno 1 conto attivo
    if (_accounts.length <= 1) {
      throw Exception('Impossibile eliminare: deve esserci almeno un conto attivo.');
    }
    _accounts.removeWhere((a) => a.id == accountId);
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // ✏️ 2. MODIFICA IMPORTO / SALDO DEL CONTO
  void updateAccountAmount(String accountId, double newAmount) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      _accounts[idx].amount = newAmount;
      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }
  
  // 📥 LETTURA ISTANTANEA DA LOCALSTORAGE
  void _caricaDatiDaLocalStorage() {
    try {
      final storage = html.window.localStorage;

      // 👈 Caricamento Preferenze e Parametri Fiscali (Default 'true')
      isPartitaIVA = (storage['isPartitaIVA'] ?? 'true') == 'true';
      coeffRedditivita = double.tryParse(storage['coeffRedditivita'] ?? '') ?? 0.78;
      aliquotaImposta = double.tryParse(storage['aliquotaImposta'] ?? '') ?? 0.05;
      aliquotaInps = double.tryParse(storage['aliquotaInps'] ?? '') ?? 0.2607;
      accontiVersatiAnnoPrecedente = double.tryParse(storage['accontiVersatiAnnoPrecedente'] ?? '') ?? 100.0;

      _spesoBisogni = double.tryParse(storage['spesoBisogni'] ?? '') ?? 0.0;
      _spesoSvago = double.tryParse(storage['spesoSvago'] ?? '') ?? 0.0;
      _spesoRisparmi = double.tryParse(storage['spesoRisparmi'] ?? '') ?? 0.0;
      _fatturatoTotale = double.tryParse(storage['fatturatoTotale'] ?? '') ?? 0.0;

      if (storage.containsKey('accounts')) {
        final List decoded = jsonDecode(storage['accounts']!);
        _accounts = decoded.map((a) => AccountModel.fromJson(Map<String, dynamic>.from(a))).toList();
      }

      if (storage.containsKey('transactions')) {
        final List decoded = jsonDecode(storage['transactions']!);
        _transactions = decoded.map((t) => TransactionModel.fromJson(Map<String, dynamic>.from(t))).toList();
      }

      if (storage.containsKey('fattureDaIncassare')) {
        final List decoded = jsonDecode(storage['fattureDaIncassare']!);
        _fattureDaIncassare = decoded.map((f) => Map<String, dynamic>.from(f)).toList();
      }

      if (storage.containsKey('fattureIncassate')) {
        final List decoded = jsonDecode(storage['fattureIncassate']!);
        _fattureIncassate = decoded.map((f) => Map<String, dynamic>.from(f)).toList();
      }
    } catch (e) {
      debugPrint('Errore durante la lettura da LocalStorage: $e');
    }
  }

  // 💾 SALVATAGGIO IN LOCALSTORAGE
  void _salvaDatiInLocalStorage() {
    try {
      final storage = html.window.localStorage;

      // 👈 Salva lo stato P.IVA, parametri fiscali e acconti
      storage['isPartitaIVA'] = isPartitaIVA.toString();
      storage['coeffRedditivita'] = coeffRedditivita.toString();
      storage['aliquotaImposta'] = aliquotaImposta.toString();
      storage['aliquotaInps'] = aliquotaInps.toString();
      storage['accontiVersatiAnnoPrecedente'] = accontiVersatiAnnoPrecedente.toString();

      storage['spesoBisogni'] = _spesoBisogni.toString();
      storage['spesoSvago'] = _spesoSvago.toString();
      storage['spesoRisparmi'] = _spesoRisparmi.toString();
      storage['fatturatoTotale'] = _fatturatoTotale.toString();

      storage['accounts'] = jsonEncode(_accounts.map((a) => a.toJson()).toList());
      storage['transactions'] = jsonEncode(_transactions.map((t) => t.toJson()).toList());
      storage['fattureDaIncassare'] = jsonEncode(_fattureDaIncassare);
      storage['fattureIncassate'] = jsonEncode(_fattureIncassate);
    } catch (e) {
      debugPrint('Errore durante il salvataggio in LocalStorage: $e');
    }
  }

  void addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    String? accountId,
    DateTime? date,
  }) {
    final DateTime dataUso = date ?? DateTime.now();

    // 1. Trova il conto di destinazione
    final targetAccount = _accounts.firstWhere(
      (acc) => acc.id == (accountId ?? '1'),
      orElse: () => _accounts.first,
    );

    // 2. Crea la transazione salvando l'ID del conto
    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subtitle: '${dataUso.day}/${dataUso.month} • $category',
      amount: amount,
      isIncome: isIncome,
      category: category,
      date: dataUso,
      accountId: targetAccount.id, // 👈 Collega il movimento al conto
    );

    _transactions.insert(0, newTx);

    // 3. Aggiorna i saldi e le statistiche
    if (isIncome) {
      targetAccount.amount += amount;
      
      // 🎯 CALCOLO TASSE ATECO: Applica l'aliquota reale SOLO se è un incasso P.IVA
      if (category == 'P.IVA') {
        targetAccount.virtualTaxAmount += (amount * aliquotaFiscaleReale);
      }
      
    } else {// 🚀 INCASSA FATTURA (CON GESTIONE DATA CUSTOM)
  void incassaFatturaPiva({
    String? idFattura,
    required String cliente,
    required double importoLordo,
    required double importoTasse,
    required String contoDestinazione,
    String? dataIncasso, // 👈 PARAMETRO RICEVUTO DALLA SCHERMATA
  }) {
    final targetAccount = _accounts.firstWhere(
      (acc) => acc.title.contains(contoDestinazione) || contoDestinazione.contains(acc.title),
      orElse: () => _accounts.first,
    );

    final String dataFinale = dataIncasso ?? 'Oggi';

    // Conversione della stringa data in oggetto DateTime per la transazione
    DateTime dataObj = DateTime.now();
    if (dataIncasso != null) {
      try {
        final parti = dataIncasso.split(' ');
        if (parti.length >= 3) {
          final g = int.parse(parti[0]);
          final a = int.parse(parti[2]);
          final mesi = [
            'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
            'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
          ];
          final m = mesi.indexOf(parti[1]) + 1;
          if (m > 0) dataObj = DateTime(a, m, g);
        }
      } catch (_) {}
    }

    if (idFattura != null) {
      final idx = _fattureDaIncassare.indexWhere((f) => f['id'] == idFattura);
      if (idx != -1) {
        final f = _fattureDaIncassare.removeAt(idx);
        _fattureIncassate.add({
          ...f,
          'dataIncasso': dataFinale, // 👈 SALVA LA DATA SCELTA (ES. GIUGNO)
          'importoTasse': importoTasse,
          'contoAccredito': contoDestinazione,
        });
      }
    }

    _fatturatoTotale += importoLordo;

    // Registra solo l'entrata reale: il calcolo della tassa virtuale avviene in automatico!
    addTransaction(
      title: 'Incasso: $cliente',
      amount: importoLordo,
      isIncome: true,
      category: 'P.IVA',
      accountId: targetAccount.id,
      date: dataObj,
    );

    _salvaDatiInLocalStorage();
    notifyListeners();
  }
      targetAccount.amount -= amount;
      if (category == 'Bisogni') _spesoBisogni += amount;
      if (category == 'Svago') _spesoSvago += amount;
      if (category == 'Risparmi') _spesoRisparmi += amount;
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // 🚀 REGISTRA FATTURA DA INCASSARE
  void addFatturaPiva({
    required String cliente,
    required double importo,
    String? data,
    String? numero,
  }) {
    final String numCalcolato = (numero != null && numero.trim().isNotEmpty)
        ? numero.trim()
        : '${_fattureDaIncassare.length + 1}';

    _fattureDaIncassare.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'cliente': cliente,
      'importo': importo,
      'data': data ?? DateTime.now().toString(),
      'numero': numCalcolato,
    });

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // 🚀 INCASSA FATTURA (CON GESTIONE DATA E TITOLO DETTAGLIATO)
  void incassaFatturaPiva({
    String? idFattura,
    required String cliente,
    required double importoLordo,
    required double importoTasse,
    required String contoDestinazione,
    String? dataIncasso,
  }) {
    final targetAccount = _accounts.firstWhere(
      (acc) => acc.title.contains(contoDestinazione) || contoDestinazione.contains(acc.title),
      orElse: () => _accounts.first,
    );

    final String dataFinale = dataIncasso ?? 'Oggi';

    // Conversione della stringa data in oggetto DateTime per la transazione
    DateTime dataObj = DateTime.now();
    if (dataIncasso != null) {
      try {
        final parti = dataIncasso.split(' ');
        if (parti.length >= 3) {
          final g = int.parse(parti[0]);
          final a = int.parse(parti[2]);
          final mesi = [
            'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
            'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
          ];
          final m = mesi.indexOf(parti[1]) + 1;
          if (m > 0) dataObj = DateTime(a, m, g);
        }
      } catch (_) {}
    }

    String numeroFattura = '';

    if (idFattura != null) {
      final idx = _fattureDaIncassare.indexWhere((f) => f['id'] == idFattura);
      if (idx != -1) {
        final f = _fattureDaIncassare.removeAt(idx);
        numeroFattura = f['numero']?.toString() ?? ''; // 👈 RECUPERIAMO IL NUMERO FATTURA!
        _fattureIncassate.add({
          ...f,
          'dataIncasso': dataFinale,
          'importoTasse': importoTasse,
          'contoAccredito': contoDestinazione,
        });
      }
    }

    _fatturatoTotale += importoLordo;

    // 👈 CREIAMO UN TITOLO COMPLETO CON NOME E NUMERO FATTURA
    final String titoloTransazione = numeroFattura.isNotEmpty 
        ? 'Fattura n.$numeroFattura - $cliente' 
        : 'Incasso: $cliente';

    // Registra l'entrata nel Wallet con il nuovo titolo dettagliato
    addTransaction(
      title: titoloTransazione,
      amount: importoLordo,
      isIncome: true,
      category: 'P.IVA',
      accountId: targetAccount.id,
      date: dataObj,
    );

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // 🗑️ ELIMINA FATTURA E STORNA IL FATTURATO / WALLET
  void eliminaFatturaPiva(String idFattura) {
    // 1. Controlla se la fattura era tra quelle già incassate
    final int idxIncassata = _fattureIncassate.indexWhere((f) => f['id'] == idFattura);

    if (idxIncassata != -1) {
      final fattura = _fattureIncassate.removeAt(idxIncassata);
      final double importoLordo = (fattura['importo'] as num).toDouble();
      final String cliente = fattura['cliente'] as String? ?? '';
      final String? contoAccredito = fattura['contoAccredito'] as String?;

      // Storna il fatturato totale (aggiorna la Stima Tasse)
      _fatturatoTotale = (_fatturatoTotale - importoLordo).clamp(0.0, double.infinity);

      // Storna il saldo dal conto del Wallet se presente
      if (contoAccredito != null) {
        final targetAccount = _accounts.firstWhere(
          (acc) => acc.title.contains(contoAccredito) || contoAccredito.contains(acc.title),
          orElse: () => _accounts.first,
        );
        targetAccount.amount = (targetAccount.amount - importoLordo).clamp(0.0, double.infinity);
      }

      // Rimuovi le transazioni associate dall'elenco del wallet
      _transactions.removeWhere((t) => t.title.contains(cliente));
    } else {
      // Se era ancora da incassare, la rimuove solo dalle sospese
      _fattureDaIncassare.removeWhere((f) => f['id'] == idFattura);
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // 🗑️ ELIMINA TRANSAZIONE MANUALE (Storna il saldo del conto)
  void deleteTransaction(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final tx = _transactions.removeAt(idx);

      // Trova il conto principale
      final targetAccount = _accounts.first;

      // Storna il saldo
      if (tx.isIncome) {
        targetAccount.amount -= tx.amount;
      } else {
        targetAccount.amount += tx.amount;
        if (tx.category == 'Bisogni') _spesoBisogni = (_spesoBisogni - tx.amount).clamp(0.0, double.infinity);
        if (tx.category == 'Svago') _spesoSvago = (_spesoSvago - tx.amount).clamp(0.0, double.infinity);
        if (tx.category == 'Risparmi') _spesoRisparmi = (_spesoRisparmi - tx.amount).clamp(0.0, double.infinity);
      }

      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }

  // ➕ METODO PER AGGIUNGERE UN NUOVO CONTO (CORRETTO)
  void addAccount({
    required String title,
    required String subtitle,
    required double initialAmount,
    required Color color,
  }) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    final newAccount = AccountModel(
      id: newId,
      title: title,
      subtitle: subtitle,
      amount: initialAmount,
      color: color,
    );

    // 1. Usa la lista privata _accounts (che è modificabile)
    _accounts.add(newAccount);

    // 2. Salva il nuovo conto nel LocalStorage
    _salvaDatiInLocalStorage();

    // 3. Aggiorna l'interfaccia
    notifyListeners();
  }

  // 🔄 RESET GLOBALE
  void resetTuttiIDati() {
    html.window.localStorage.clear();

    _accounts = [
      AccountModel(id: '1', title: 'Conto Principale (IBAN)', subtitle: 'Banca Fineco •• 4092', amount: 0.00, color: const Color(0xFF2DD4BF)),
      AccountModel(id: '2', title: 'Carta Spese & Svago', subtitle: 'Revolut Digital •• 1102', amount: 0.00, color: const Color(0xFFF59E0B)),
      AccountModel(id: '3', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6)),
      AccountModel(id: '4', title: 'Salvadanaio Acconto Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6)),

    ];

    isPartitaIVA = true; // 👈 Mantiene attivo il profilo P.IVA anche dopo il reset
    _spesoBisogni = 0.00;
    _spesoSvago = 0.00;
    _spesoRisparmi = 0.00;
    _fatturatoTotale = 0.00;
    _transactions.clear();
    _fattureDaIncassare.clear();
    _fattureIncassate.clear();

    notifyListeners();
  }

    // ✏️ MODIFICA NOME E SALDO CONTO
  void updateAccountDetails({
    required String accountId,
    required String newTitle,
    required double newAmount,
  }) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      _accounts[idx].title = newTitle;
      _accounts[idx].amount = newAmount;
      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }

    // 🔀 RIORDINA LA LISTA DEI CONTI
  void reorderAccounts(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1; // Aggiustamento indice richiesto da Flutter quando si sposta verso il basso
    }
    final AccountModel item = _accounts.removeAt(oldIndex);
    _accounts.insert(newIndex, item);

    _salvaDatiInLocalStorage(); // Salva il nuovo ordine nella memoria
    notifyListeners();
  }

    // ==========================================
  // 💸 PAGAMENTO F24 (Caso B & Delta)
  // ==========================================
  void pagaF24({
    required String accountId,
    required double importoF24,
    required DateTime data,
  }) {
    final targetAccount = _accounts.firstWhere((acc) => acc.id == accountId);

    // 1. Scala i soldi veri dal conto (La banca scende)
    targetAccount.amount -= importoF24;

    // 2. Registra il movimento come uscita per non far sballare lo storico
    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Pagamento F24 / Tasse',
      subtitle: 'Tasse',
      amount: importoF24,
      isIncome: false,
      category: 'Tasse', 
      date: data,
      accountId: targetAccount.id,
    );
    _transactions.insert(0, newTx);

    // 3. 🎯 GESTIONE DEL "SECCHIO TASSE" GLOBALE (Scala il debito)
    double remainingToDeduct = importoF24;

    // Prima svuota le tasse virtuali dal conto che ha pagato
    if (targetAccount.virtualTaxAmount >= remainingToDeduct) {
      targetAccount.virtualTaxAmount -= remainingToDeduct;
      remainingToDeduct = 0;
    } else {
      remainingToDeduct -= targetAccount.virtualTaxAmount;
      targetAccount.virtualTaxAmount = 0;

      // Se l'F24 era più alto, preleva la tassa virtuale dagli altri conti
      for (var acc in _accounts) {
        if (remainingToDeduct <= 0) break;
        if (acc.virtualTaxAmount >= remainingToDeduct) {
          acc.virtualTaxAmount -= remainingToDeduct;
          remainingToDeduct = 0;
        } else {
          remainingToDeduct -= acc.virtualTaxAmount;
          acc.virtualTaxAmount = 0;
        }
      }
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }


  // ==========================================
  // 🔄 GIROCONTO INTELLIGENTE (Con Gestione Cuscinetto Extra)
  // ==========================================
  void eseguiGiroconto({
    required String daAccountId,
    required String aAccountId,
    required double importo,
    required bool isAccantonamentoTasse,
  }) {
    final accDa = _accounts.firstWhere((a) => a.id == daAccountId);
    final accA = _accounts.firstWhere((a) => a.id == aAccountId);

    // Controlli di sicurezza di base
    if (importo <= 0 || accDa.amount < importo) return;

    // 1. GESTIONE DEL VINCOLO FISCALE
    if (isAccantonamentoTasse) {
      // Trasferiamo la quota tasse fino al massimo disponibile sul conto di partenza
      double tasseDaSpostare = importo;
      if (tasseDaSpostare > accDa.virtualTaxAmount) {
        tasseDaSpostare = accDa.virtualTaxAmount; // Se si sposta di più, sposta tutte le tasse disponibili
      }

      accDa.virtualTaxAmount -= tasseDaSpostare;
      accA.virtualTaxAmount += tasseDaSpostare;
      // L'eccedenza di 'importo' rimarrà sul conto di destinazione come saldo reale puro (Cuscinetto)
    }

    // 2. REGISTRAZIONE MOVIMENTO FISICO & STORICO
    addTransaction(
      title: isAccantonamentoTasse ? 'Accantonamento Tasse 🛡️' : 'Giroconto verso ${accA.title}',
      amount: importo,
      isIncome: false,
      category: 'Giroconto',
      accountId: accDa.id,
    );

    addTransaction(
      title: isAccantonamentoTasse ? 'Ricezione Riserva Tasse 🛡️' : 'Giroconto da ${accDa.title}',
      amount: importo,
      isIncome: true,
      category: 'Giroconto',
      accountId: accA.id,
    );
  }
}