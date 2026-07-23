import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; 
import 'package:flutter/material.dart';

class AccountModel {
  final String id;
  final String title;
  final String subtitle;
  double amount;
  final Color color;

  AccountModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'color': color.value,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        amount: (json['amount'] as num).toDouble(),
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

  TransactionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'isIncome': isIncome,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'] as bool,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class WalletProvider extends ChangeNotifier {
  List<AccountModel> _accounts = [
    AccountModel(id: '1', title: 'Conto Principale (IBAN)', subtitle: 'Banca Fineco •• 4092', amount: 0.00, color: const Color(0xFF2DD4BF)),
    AccountModel(id: '2', title: 'Carta Spese & Svago', subtitle: 'Revolut Digital •• 1102', amount: 0.00, color: const Color(0xFFF59E0B)),
    AccountModel(id: '3', title: 'Salvadanaio Emergenze / Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6)),
  ];

  List<AccountModel> get accounts => List.unmodifiable(_accounts);
  double get patrimonioNetto => _accounts.fold(0.0, (sum, acc) => sum + acc.amount);

  double _spesoBisogni = 0.00;
  double get spesoBisogni => _spesoBisogni;

  double _spesoSvago = 0.00;
  double get spesoSvago => _spesoSvago;

  double _spesoRisparmi = 0.00;
  double get spesoRisparmi => _spesoRisparmi;

  double _fatturatoTotale = 0.00;
  double get fatturatoTotale => _fatturatoTotale;

  final double _coefficienteRedditivita = 0.78;
  double get stimaTasseAccantonate => (_fatturatoTotale * _coefficienteRedditivita) * 0.35;
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
    DateTime? date, // 👈 AGGIUNTA PARAMETRO DATA
  }) {
    final DateTime dataUso = date ?? DateTime.now();
    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subtitle: '${dataUso.day}/${dataUso.month} • $category',
      amount: amount,
      isIncome: isIncome,
      category: category,
      date: dataUso, // 👈 USA LA DATA PASSATA
    );

    _transactions.insert(0, newTx);

    final targetAccount = _accounts.firstWhere(
      (acc) => acc.id == (accountId ?? '1'),
      orElse: () => _accounts.first,
    );

    if (isIncome) {
      targetAccount.amount += amount;
    } else {
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

  // 🚀 INCASSA FATTURA (CON GESTIONE DATA CUSTOM)
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

    addTransaction(
      title: 'Incasso: $cliente',
      amount: importoLordo,
      isIncome: true,
      category: 'P.IVA',
      accountId: targetAccount.id,
      date: dataObj, // 👈 ASSEGNA LA DATA CORRETTA ALLA TRANSAZIONE
    );

    if (importoTasse > 0) {
      addTransaction(
        title: 'Accantonamento Tasse ($cliente)',
        amount: importoTasse,
        isIncome: false,
        category: 'Risparmi',
        accountId: targetAccount.id,
        date: dataObj, // 👈 ASSEGNA LA DATA CORRETTA ALLA TRANSAZIONE
      );
    }

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
      AccountModel(id: '3', title: 'Salvadanaio Emergenze / Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6)),
    ];

    _spesoBisogni = 0.00;
    _spesoSvago = 0.00;
    _spesoRisparmi = 0.00;
    _fatturatoTotale = 0.00;
    _transactions.clear();
    _fattureDaIncassare.clear();
    _fattureIncassate.clear();

    notifyListeners();
  }
}