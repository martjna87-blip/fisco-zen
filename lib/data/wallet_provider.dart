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
  }) {
    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subtitle: 'Oggi • $category',
      amount: amount,
      isIncome: isIncome,
      category: category,
      date: DateTime.now(),
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

  // 🚀 INCASSA FATTURA
  void incassaFatturaPiva({
    String? idFattura,
    required String cliente,
    required double importoLordo,
    required double importoTasse,
    required String contoDestinazione,
  }) {
    final targetAccount = _accounts.firstWhere(
      (acc) => acc.title.contains(contoDestinazione) || contoDestinazione.contains(acc.title),
      orElse: () => _accounts.first,
    );

    if (idFattura != null) {
      final idx = _fattureDaIncassare.indexWhere((f) => f['id'] == idFattura);
      if (idx != -1) {
        final f = _fattureDaIncassare.removeAt(idx);
        _fattureIncassate.add({
          ...f,
          'dataIncasso': 'Oggi',
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
    );

    if (importoTasse > 0) {
      addTransaction(
        title: 'Accantonamento Tasse ($cliente)',
        amount: importoTasse,
        isIncome: false,
        category: 'Risparmi',
        accountId: targetAccount.id,
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