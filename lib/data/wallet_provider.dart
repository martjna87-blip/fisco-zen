import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 LA NUOVA CASSAFORTE UNIVERSALE

// 🛡️ 1. ENUM PER I RUOLI DI SISTEMA INDELEBILI
enum AccountRole {
  principal,  // Conto Operativo Principale
  taxReserve, // Salvadanaio Riserva Tasse
  standard,   // Conto o Carta Libera (creabile/eliminabile dall'utente)
}

class AccountModel {
  final String id;
  String title; 
  final String subtitle;
  double amount;
  double virtualTaxAmount;
  final Color color;
  final AccountRole role; // 👈 RUOLO DI SISTEMA INDELEBILE

  AccountModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.virtualTaxAmount = 0.0,
    required this.color,
    this.role = AccountRole.standard, // 👈 Di default ogni conto è Standard
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'virtualTaxAmount': virtualTaxAmount,
        'color': color.value,
        'role': role.name, // 👈 Salvataggio ruolo in memoria
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    AccountRole roleAssegnato = AccountRole.standard;

    if (json['role'] != null) {
      roleAssegnato = AccountRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => AccountRole.standard,
      );
    } else {
      // 🛡️ AUTO-MIGRAZIONE: Se il dato salvato è vecchio, riconosce il ruolo dall'ID o dal Titolo
      final String id = json['id'] as String;
      final String title = (json['title'] as String).toLowerCase();

      if (id == '1' || title.contains('principale')) {
        roleAssegnato = AccountRole.principal;
      } else if (id == '3' || title.contains('salvadanaio') || title.contains('acconto')) {
        roleAssegnato = AccountRole.taxReserve;
      }
    }

    return AccountModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      virtualTaxAmount: (json['virtualTaxAmount'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int),
      role: roleAssegnato,
    );
  }
}

class TransactionModel {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final String category;
  final DateTime date;
  final String? accountId; 
  
  final bool isRecurrent; 
  final String? frequenza; 
  final String? giornoRicorrenza; 

  TransactionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
    this.accountId,
    this.isRecurrent = false,
    this.frequenza,
    this.giornoRicorrenza,
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
        'isRecurrent': isRecurrent,
        'frequenza': frequenza,
        'giornoRicorrenza': giornoRicorrenza,
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
        isRecurrent: json['isRecurrent'] as bool? ?? false,
        frequenza: json['frequenza'] as String?,
        giornoRicorrenza: json['giornoRicorrenza'] as String?,
      );
}

class WalletProvider extends ChangeNotifier {
  List<AccountModel> _accounts = [
    AccountModel(id: '1', title: 'Conto Principale (IBAN)', subtitle: 'Banca Fineco •• 4092', amount: 0.00, color: const Color(0xFF2DD4BF), role: AccountRole.principal),
    AccountModel(id: '2', title: 'Carta Spese & Svago', subtitle: 'Revolut Digital •• 1102', amount: 0.00, color: const Color(0xFFF59E0B), role: AccountRole.standard),
    AccountModel(id: '3', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6), role: AccountRole.taxReserve),
  ];

  List<AccountModel> get accounts => List.unmodifiable(_accounts);

  bool _isProUser = false;
  bool get isProUser => _isProUser;

// ===========================================================================
  // 🪪 PROFILO ONBOARDING & MOTORE FISCALE
  // ===========================================================================
  String _codiceAteco = '62.02.00';
  double _coefficienteRedditivita = 0.78;
  String _tipoCassa = 'gestioneSeparata';
  bool _isStartup = true;
  
  String _tipoLavoroDipendente = 'nessuno';
  bool _ralSupera30k = false;
  bool _scontoInps35 = false;

  bool _isPrimoAnnoAssoluto = false;
  double _accontoImpostaVersato = 0.0;
  double _accontoInpsVersato = 0.0;
  double _contributiInpsPagatiAnnoCorrente = 0.0;

  double _nettoTargetMensile = 2000.0;
  double _speseFisseMensili = 800.0;
  double _fatturatoStimatoAnnuo = 35000.0;
  int _mesiAttiviIncasso = 10;

// ===========================================================================
  // 🎯 MOTORE DI CALCOLO: VERDETTO FISCALE & STRATEGICO
  // ===========================================================================
  Map<String, dynamic> calcolaVerdettoFiscale({
    double? fatturatoCustom,
    double? nettoTargetCustom,
    int? mesiAttiviCustom,
  }) {
    final fatturato = fatturatoCustom ?? _fatturatoStimatoAnnuo;
    final nettoTargetMese = nettoTargetCustom ?? _nettoTargetMensile;
    final mesiAttivi = mesiAttiviCustom ?? _mesiAttiviIncasso;

    final imponibileLordo = fatturato * _coefficienteRedditivita;
    final imponibileNettoTasse = (imponibileLordo - _contributiInpsPagatiAnnoCorrente).clamp(0.0, double.infinity);

    double stimaInpsAnnuo = 0.0;
    
    if (_tipoCassa == 'gestioneSeparata') {
      final aliquotaInps = (_tipoLavoroDipendente != 'nessuno') ? 0.24 : 0.2607;
      stimaInpsAnnuo = imponibileLordo * aliquotaInps;
    } else if (_tipoCassa == 'commercianti' || _tipoCassa == 'artigiani') {
      final isEsenzioneFissi = (_tipoLavoroDipendente == 'fullTime' || _tipoLavoroDipendente == 'partTimeSuperiore50');
      
      if (isEsenzioneFissi) {
        stimaInpsAnnuo = 0.0; 
      } else {
        double fissoBase = 4200.0;
        if (_scontoInps35) fissoBase *= 0.65;
        stimaInpsAnnuo = fissoBase;
      }
    } else {
      stimaInpsAnnuo = imponibileLordo * 0.15;
    }

    final aliquotaImposta = _isStartup ? 0.05 : 0.15;
    final stimaImpostaAnnuo = imponibileNettoTasse * aliquotaImposta;
    final totaleTasseAnnuo = stimaInpsAnnuo + stimaImpostaAnnuo;
    final nettoRealeAnnuo = fatturato - totaleTasseAnnuo;
    final stipendioMensile12Mesi = nettoRealeAnnuo / 12;
    final mesiPausa = 12 - mesiAttivi;
    final quotaMesiZeroMensile = (mesiPausa > 0) 
        ? (stipendioMensile12Mesi * mesiPausa) / mesiAttivi 
        : 0.0;

    final percentualeTrattenutaTasseFattura = fatturato > 0 
        ? (totaleTasseAnnuo / fatturato) * 100 
        : 0.0;
    
    final percentualeTrattenutaMesiZeroFattura = (fatturato > 0 && mesiPausa > 0)
        ? ((stipendioMensile12Mesi * mesiPausa) / fatturato) * 100
        : 0.0;

    String semaforo = 'VERDE'; 
    String motivazione = '';

    if (stipendioMensile12Mesi >= nettoTargetMese) {
      semaforo = 'VERDE';
      motivazione = 'Il tuo fatturato stimato copre il tuo obiettivo di netto e ti permette un margine extra!';
    } else if (stipendioMensile12Mesi >= (nettoTargetMese * 0.85)) {
      semaforo = 'GIALLO';
      motivazione = 'Sei vicino al tuo obiettivo, ma il margine per imprevisti è ridotto.';
    } else {
      semaforo = 'ROSSO';
      motivazione = 'Il fatturato stimato non è sufficiente per garantire il tuo netto desiderato.';
    }

    final pressioneFiscalePercentuale = fatturato > 0 ? (totaleTasseAnnuo / fatturato) : 0.25;
    final fatturatoLordoNecessarioForTarget = (nettoTargetMese * 12) / (1 - pressioneFiscalePercentuale);

    return {
      'fatturatoLordo': fatturato,
      'imponibileLordo': imponibileLordo,
      'stimaInpsAnnuo': stimaInpsAnnuo,
      'stimaImpostaAnnuo': stimaImpostaAnnuo,
      'totaleTasseAnnuo': totaleTasseAnnuo,
      'pressioneFiscaleReale': pressioneFiscalePercentuale * 100,
      'nettoRealeAnnuo': nettoRealeAnnuo,
      'stipendioMensile12Mesi': stipendioMensile12Mesi,
      'quotaMesiZeroMensile': quotaMesiZeroMensile,
      'percentualeTrattenutaTasseFattura': percentualeTrattenutaTasseFattura,
      'percentualeTrattenutaMesiZeroFattura': percentualeTrattenutaMesiZeroFattura,
      'percentualeNettoDisponibile': 100 - percentualeTrattenutaTasseFattura - percentualeTrattenutaMesiZeroFattura,
      'semaforo': semaforo,
      'motivazione': motivazione,
      'fatturatoLordoNecessarioForTarget': fatturatoLordoNecessarioForTarget,
    };
  }
  
// ==========================================
  // ⚙️ CONFIGURAZIONE E MATEMATICA FISCALE ATECO
  // ==========================================
  bool isPartitaIVA = true; 
  double accontiVersatiAnnoPrecedente = 100.0; 
  
  double coeffRedditivita = 0.78; 
  double aliquotaImposta = 0.05;  
  double aliquotaInps = 0.2607;   

  double get aliquotaFiscaleReale {
    final imponibile = coeffRedditivita;                 
    final saldoInps = imponibile * aliquotaInps;         
    final saldoImposta = imponibile * aliquotaImposta;   
    final accontoInps = saldoInps * 0.80;                
    final accontoImposta = saldoImposta * 1.00;          
    return saldoInps + saldoImposta + accontoInps + accontoImposta;
  }

  void setPartitaIVA(bool value) {
    isPartitaIVA = value;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // ==========================================
  // 📊 MATEMATICA E STATISTICHE GLOBALI
  // ==========================================

  double get patrimonioNetto => _accounts.fold(0.0, (sum, item) => sum + item.amount);
  double get _tasseLordeAccantonate => _accounts.fold(0.0, (sum, item) => sum + item.virtualTaxAmount);

  double get fondoTasseDaVersare {
    double fondo = _tasseLordeAccantonate - accontiVersatiAnnoPrecedente;
    return fondo > 0 ? fondo : 0.0; 
  }

  double get nettoSpendibile => patrimonioNetto - fondoTasseDaVersare;

  double _spesoBisogni = 0.00;
  double get spesoBisogni => _spesoBisogni;

  double _spesoSvago = 0.00;
  double get spesoSvago => _spesoSvago;

  double _spesoRisparmi = 0.00;
  double get spesoRisparmi => _spesoRisparmi;

  double _fatturatoTotale = 0.00;
  double get fatturatoTotale => _fatturatoTotale;

  double get stimaTasseAccantonate => _fatturatoTotale * aliquotaFiscaleReale;
  double get nettoPiva => _fatturatoTotale - stimaTasseAccantonate;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  int _stringToWeekday(String day) {
    switch (day) {
      case 'Lunedì': return 1;
      case 'Martedì': return 2;
      case 'Mercoledì': return 3;
      case 'Giovedì': return 4;
      case 'Venerdì': return 5;
      case 'Sabato': return 6;
      case 'Domenica': return 7;
      default: return 1;
    }
  }

  List<TransactionModel> getMovimentiPrevisti(DateTime meseRiferimento) {
    final previsti = <TransactionModel>[];
    final oggi = DateTime.now();
    final ricorrenti = _transactions.where((t) => t.isRecurrent).toList();

    for (var tx in ricorrenti) {
      if (tx.frequenza == 'Ogni mese' && tx.giornoRicorrenza != null) {
        int giornoPrevisto = int.tryParse(tx.giornoRicorrenza!) ?? 1;
        DateTime dataVirtuale;
        try {
          dataVirtuale = DateTime(meseRiferimento.year, meseRiferimento.month, giornoPrevisto);
        } catch (e) {
          dataVirtuale = DateTime(meseRiferimento.year, meseRiferimento.month + 1, 0); 
        }

        bool isStessoMeseCreazione = dataVirtuale.year == tx.date.year && dataVirtuale.month == tx.date.month;

        if (dataVirtuale.isAfter(oggi) && !isStessoMeseCreazione) {
          previsti.add(TransactionModel(
            id: 'prev_${tx.id}_${dataVirtuale.month}', 
            title: tx.title,
            subtitle: 'In arrivo il ${dataVirtuale.day}/${dataVirtuale.month}', 
            amount: tx.amount,
            isIncome: tx.isIncome,
            category: tx.category,
            date: dataVirtuale,
            accountId: tx.accountId,
            isRecurrent: true, 
          ));
        }
      }
      else if (tx.frequenza == 'Ogni settimana' && tx.giornoRicorrenza != null) {
        final keySettimanale = '${tx.id}_${meseRiferimento.year}_${meseRiferimento.month}';
        if (_skippedPredictions.contains(keySettimanale)) continue;

        int targetWeekday = _stringToWeekday(tx.giornoRicorrenza!);
        int numOccorrenze = 0;
        DateTime? primaDataValida;
        
        int daysInMonth = DateTime(meseRiferimento.year, meseRiferimento.month + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          DateTime checkDate = DateTime(meseRiferimento.year, meseRiferimento.month, i);
          if (checkDate.weekday == targetWeekday) {
            if (checkDate.isAfter(oggi) && checkDate.isAfter(tx.date)) {
              numOccorrenze++;
              primaDataValida ??= checkDate; 
            }
          }
        }
        
        if (numOccorrenze > 0) {
          final String etichettaOccorrenze = tx.isIncome ? 'entrate' : 'uscite';
          previsti.add(TransactionModel(
            id: 'prev_${tx.id}_${meseRiferimento.month}', 
            title: '${tx.title} ($numOccorrenze $etichettaOccorrenze)', 
            subtitle: 'Previsto', 
            amount: tx.amount * numOccorrenze, 
            isIncome: tx.isIncome,
            category: tx.category,
            date: primaDataValida ?? meseRiferimento, 
            accountId: tx.accountId,
            isRecurrent: true, 
          ));
        }
      }
    }
    
    previsti.sort((a, b) => a.date.compareTo(b.date));
    return previsti;
  }

  List<Map<String, dynamic>> _fattureDaIncassare = [];
  List<Map<String, dynamic>> get fattureDaIncassare => List.unmodifiable(_fattureDaIncassare);

  List<Map<String, dynamic>> _fattureIncassate = [];
  List<Map<String, dynamic>> get fattureIncassate => List.unmodifiable(_fattureIncassate);
  List<String> _skippedPredictions = [];

  WalletProvider() {
    _caricaDatiDaLocalStorage();
  }

  void deleteAccount(String accountId) {
    final target = _accounts.firstWhere((a) => a.id == accountId, orElse: () => _accounts.first);

    // 🛡️ SCUDO DI SISTEMA: Impedisce l'eliminazione dei conti chiave
    if (target.role == AccountRole.principal || target.role == AccountRole.taxReserve) {
      throw Exception('I conti di sistema (Principale e Salvadanaio Tasse) non possono essere eliminati.');
    }

    if (_accounts.length <= 1) {
      throw Exception('Impossibile eliminare: deve esserci almeno un conto attivo.');
    }
    _accounts.removeWhere((a) => a.id == accountId);
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void updateAccountAmount(String accountId, double newAmount) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      _accounts[idx].amount = newAmount;
      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }
  
  // 📥 LETTURA ISTANTANEA DA SHAREDPREFERENCES (NUOVO METODO)
  Future<void> _caricaDatiDaLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      isPartitaIVA = prefs.getBool('isPartitaIVA') ?? true;
      coeffRedditivita = prefs.getDouble('coeffRedditivita') ?? 0.78;
      aliquotaImposta = prefs.getDouble('aliquotaImposta') ?? 0.05;
      aliquotaInps = prefs.getDouble('aliquotaInps') ?? 0.2607;
      accontiVersatiAnnoPrecedente = prefs.getDouble('accontiVersatiAnnoPrecedente') ?? 100.0;

      // 📥 Caricamento variabili fiscali dal Questionario
      _codiceAteco = prefs.getString('codiceAteco') ?? '62.02.00';
      _nettoTargetMensile = prefs.getDouble('nettoTargetMensile') ?? 2000.0;
      _fatturatoStimatoAnnuo = prefs.getDouble('fatturatoStimatoAnnuo') ?? 35000.0;
      _mesiAttiviIncasso = prefs.getInt('mesiAttiviIncasso') ?? 10;

      _spesoBisogni = prefs.getDouble('spesoBisogni') ?? 0.0;
      _spesoSvago = prefs.getDouble('spesoSvago') ?? 0.0;
      _spesoRisparmi = prefs.getDouble('spesoRisparmi') ?? 0.0;
      _fatturatoTotale = prefs.getDouble('fatturatoTotale') ?? 0.0;

      final accountsStr = prefs.getString('accounts');
      if (accountsStr != null) {
        final List decoded = jsonDecode(accountsStr);
        _accounts = decoded.map((a) => AccountModel.fromJson(Map<String, dynamic>.from(a))).toList();
      }

      final transactionsStr = prefs.getString('transactions');
      if (transactionsStr != null) {
        final List decoded = jsonDecode(transactionsStr);
        _transactions = decoded.map((t) => TransactionModel.fromJson(Map<String, dynamic>.from(t))).toList();
      }

      final fattureDaIncassareStr = prefs.getString('fattureDaIncassare');
      if (fattureDaIncassareStr != null) {
        final List decoded = jsonDecode(fattureDaIncassareStr);
        _fattureDaIncassare = decoded.map((f) => Map<String, dynamic>.from(f)).toList();
      }

      final fattureIncassateStr = prefs.getString('fattureIncassate');
      if (fattureIncassateStr != null) {
        final List decoded = jsonDecode(fattureIncassateStr);
        _fattureIncassate = decoded.map((f) => Map<String, dynamic>.from(f)).toList();
      }

      final skippedPredictionsStr = prefs.getString('skippedPredictions');
      if (skippedPredictionsStr != null) {
        final List decoded = jsonDecode(skippedPredictionsStr);
        _skippedPredictions = decoded.map((s) => s.toString()).toList();
      }

      notifyListeners(); // 👈 Aggiorna l'UI appena i dati sono caricati
    } catch (e) {
      debugPrint('Errore durante la lettura: $e');
    }
  }

  // 💾 SALVATAGGIO IN SHAREDPREFERENCES (NUOVO METODO)
  Future<void> _salvaDatiInLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('isPartitaIVA', isPartitaIVA);
      await prefs.setDouble('coeffRedditivita', coeffRedditivita);
      await prefs.setDouble('aliquotaImposta', aliquotaImposta);
      await prefs.setDouble('aliquotaInps', aliquotaInps);
      await prefs.setDouble('accontiVersatiAnnoPrecedente', accontiVersatiAnnoPrecedente);

      // 💾 Salvataggio variabili fiscali dal Questionario
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('codiceAteco', _codiceAteco);
      await prefs.setDouble('nettoTargetMensile', _nettoTargetMensile);
      await prefs.setDouble('fatturatoStimatoAnnuo', _fatturatoStimatoAnnuo);
      await prefs.setInt('mesiAttiviIncasso', _mesiAttiviIncasso);

      await prefs.setDouble('spesoBisogni', _spesoBisogni);
      await prefs.setDouble('spesoSvago', _spesoSvago);
      await prefs.setDouble('spesoRisparmi', _spesoRisparmi);
      await prefs.setDouble('fatturatoTotale', _fatturatoTotale);

      await prefs.setString('accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
      await prefs.setString('transactions', jsonEncode(_transactions.map((t) => t.toJson()).toList()));
      await prefs.setString('fattureDaIncassare', jsonEncode(_fattureDaIncassare));
      await prefs.setString('fattureIncassate', jsonEncode(_fattureIncassate));
      await prefs.setString('skippedPredictions', jsonEncode(_skippedPredictions));
    } catch (e) {
      debugPrint('Errore durante il salvataggio: $e');
    }
  }

  void addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    String? accountId,
    DateTime? date,
    bool isRecurrent = false, 
    String? frequenza,        
    String? giornoRicorrenza, 
  }) {
    final DateTime dataUso = date ?? DateTime.now();

    final targetAccount = _accounts.firstWhere(
      (acc) => acc.id == (accountId ?? '1'),
      orElse: () => _accounts.first,
    );

    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subtitle: '${dataUso.day}/${dataUso.month} • $category',
      amount: amount,
      isIncome: isIncome,
      category: category,
      date: dataUso,
      accountId: targetAccount.id,
      isRecurrent: isRecurrent,
      frequenza: frequenza,
      giornoRicorrenza: giornoRicorrenza,
    );

    _transactions.insert(0, newTx);

    if (isIncome) {
      targetAccount.amount += amount;
      
      if (category == 'P.IVA') {
        targetAccount.virtualTaxAmount += (amount * aliquotaFiscaleReale);
      }
      
    } else {
      targetAccount.amount -= amount;
      if (category == 'Bisogni') _spesoBisogni += amount;
      if (category == 'Svago') _spesoSvago += amount;
      if (category == 'Risparmi') _spesoRisparmi += amount;
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

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
    String dataEmissioneFormattata = '';

    if (idFattura != null) {
      final idx = _fattureDaIncassare.indexWhere((f) => f['id'] == idFattura);
      if (idx != -1) {
        final f = _fattureDaIncassare.removeAt(idx);
        numeroFattura = f['numero']?.toString() ?? ''; 
        
        if (f['data'] != null) {
          String rawData = f['data'].toString();
          bool parsed = false;

          final mesi = ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];
          for (int i = 0; i < mesi.length; i++) {
            if (rawData.contains(mesi[i])) {
              final parts = rawData.split(' ');
              if (parts.isNotEmpty) {
                dataEmissioneFormattata = '${parts[0].padLeft(2, '0')}/${(i + 1).toString().padLeft(2, '0')}';
                parsed = true;
                break;
              }
            }
          }

          if (!parsed && rawData.contains('/')) {
            final parts = rawData.split('/');
            if (parts.length >= 2) {
              dataEmissioneFormattata = '${parts[0].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}';
              parsed = true;
            }
          }

          if (!parsed) {
            try {
              final dt = DateTime.parse(rawData);
              dataEmissioneFormattata = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
              parsed = true;
            } catch (_) {}
          }

          if (!parsed) {
            dataEmissioneFormattata = rawData.length > 5 ? rawData.substring(0, 5) : rawData;
          }
        }

        _fattureIncassate.add({
          ...f,
          'dataIncasso': dataFinale,
          'importoTasse': importoTasse,
          'contoAccredito': contoDestinazione,
        });
      }
    }

    _fatturatoTotale += importoLordo;

    final String suffissoData = dataEmissioneFormattata.isNotEmpty ? ' (del $dataEmissioneFormattata)' : '';
    final String titoloTransazione = numeroFattura.isNotEmpty 
        ? 'Fattura n.$numeroFattura$suffissoData - $cliente' 
        : 'Incasso: $cliente';

    addTransaction(
      title: titoloTransazione,
      amount: importoLordo,
      isIncome: true,
      category: 'P.IVA',
      accountId: targetAccount.id,
      date: dataObj,
    );

    // 🎯 1. Rimuove la stima generica aggiunta in automatico da addTransaction
    targetAccount.virtualTaxAmount = (targetAccount.virtualTaxAmount - (importoLordo * aliquotaFiscaleReale)).clamp(0.0, double.infinity);

    // 🎯 2. Calcola le tasse reali della fattura
    final double tasseFattura = importoTasse > 0 ? importoTasse : (importoLordo * aliquotaFiscaleReale);

    // 🛡️ 3. Calcola il "cuscinetto libero" già presente nel Salvadanaio prima di questa fattura
    final double riservaSalvadanaio = _accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double totaleTasseFatturePrecedenti = _fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0)) - tasseFattura;

    final double cuscinettoLibero = (riservaSalvadanaio - totaleTasseFatturePrecedenti).clamp(0.0, double.infinity);

    // 🟢 4. Assegna al Conto Principale solo la quota tasse NON ancora coperta dal Salvadanaio
    final double tasseDaAssegnare = (tasseFattura - cuscinettoLibero).clamp(0.0, double.infinity);
    targetAccount.virtualTaxAmount += tasseDaAssegnare;

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void eliminaFatturaPiva(String idFattura) {
    final int idxIncassata = _fattureIncassate.indexWhere((f) => f['id'] == idFattura);

    if (idxIncassata != -1) {
      final fattura = _fattureIncassate.removeAt(idxIncassata);
      final double importoLordo = (fattura['importo'] as num).toDouble();
      final String cliente = fattura['cliente'] as String? ?? '';
      final String? contoAccredito = fattura['contoAccredito'] as String?;

      _fatturatoTotale = (_fatturatoTotale - importoLordo).clamp(0.0, double.infinity);

      if (contoAccredito != null) {
        final targetAccount = _accounts.firstWhere(
          (acc) => acc.title.contains(contoAccredito) || contoAccredito.contains(acc.title),
          orElse: () => _accounts.first,
        );
        targetAccount.amount = (targetAccount.amount - importoLordo).clamp(0.0, double.infinity);
      }

      _transactions.removeWhere((t) => t.title.contains(cliente));
    } else {
      _fattureDaIncassare.removeWhere((f) => f['id'] == idFattura);
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final tx = _transactions.removeAt(idx);
      final targetAccount = _accounts.firstWhere((a) => a.id == (tx.accountId ?? '1'), orElse: () => _accounts.first);

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

  void stopRecurrence(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final tx = _transactions[idx];
      _transactions[idx] = TransactionModel(
        id: tx.id,
        title: tx.title,
        subtitle: tx.subtitle,
        amount: tx.amount,
        isIncome: tx.isIncome,
        category: tx.category,
        date: tx.date,
        accountId: tx.accountId,
        isRecurrent: false, 
        frequenza: null,
        giornoRicorrenza: null,
      );
      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }

  void skipPrediction(String parentId, DateTime meseRiferimento) {
    final key = '${parentId}_${meseRiferimento.year}_${meseRiferimento.month}';
    if (!_skippedPredictions.contains(key)) {
      _skippedPredictions.add(key);
      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }

  void deleteButKeepRecurrence(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final tx = _transactions[idx];
      final targetAccount = _accounts.firstWhere((a) => a.id == (tx.accountId ?? '1'), orElse: () => _accounts.first);

      if (tx.isIncome) {
        targetAccount.amount -= tx.amount;
      } else {
        targetAccount.amount += tx.amount;
        if (tx.category == 'Bisogni') _spesoBisogni = (_spesoBisogni - tx.amount).clamp(0.0, double.infinity);
        if (tx.category == 'Svago') _spesoSvago = (_spesoSvago - tx.amount).clamp(0.0, double.infinity);
        if (tx.category == 'Risparmi') _spesoRisparmi = (_spesoRisparmi - tx.amount).clamp(0.0, double.infinity);
      }

      _transactions[idx] = TransactionModel(
        id: 'rule_${tx.id}',
        title: tx.title,
        subtitle: tx.subtitle,
        amount: tx.amount,
        isIncome: tx.isIncome,
        category: tx.category,
        date: tx.date,
        accountId: tx.accountId,
        isRecurrent: true,
        frequenza: tx.frequenza,
        giornoRicorrenza: tx.giornoRicorrenza,
      );

      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }

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

    _accounts.add(newAccount);
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  Future<void> resetTuttiIDati() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 👈 Cancella la memoria

    _accounts = [
      AccountModel(id: '1', title: 'Conto Principale (IBAN)', subtitle: 'Banca Fineco •• 4092', amount: 0.00, color: const Color(0xFF2DD4BF), role: AccountRole.principal),
      AccountModel(id: '2', title: 'Carta Spese & Svago', subtitle: 'Revolut Digital •• 1102', amount: 0.00, color: const Color(0xFFF59E0B), role: AccountRole.standard),
      AccountModel(id: '3', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6), role: AccountRole.taxReserve),
    ];

    isPartitaIVA = true; 
    _spesoBisogni = 0.00;
    _spesoSvago = 0.00;
    _spesoRisparmi = 0.00;
    _fatturatoTotale = 0.00;
    _transactions.clear();
    _fattureDaIncassare.clear();
    _fattureIncassate.clear();

    notifyListeners();
  }

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

  void reorderAccounts(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1; 
    }
    final AccountModel item = _accounts.removeAt(oldIndex);
    _accounts.insert(newIndex, item);

    _salvaDatiInLocalStorage(); 
    notifyListeners();
  }

  void pagaF24({
    required String accountId,
    required double importoF24,
    required DateTime data,
  }) {
    final targetAccount = _accounts.firstWhere((acc) => acc.id == accountId);

    targetAccount.amount -= importoF24;

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

    double remainingToDeduct = importoF24;

    if (targetAccount.virtualTaxAmount >= remainingToDeduct) {
      targetAccount.virtualTaxAmount -= remainingToDeduct;
      remainingToDeduct = 0;
    } else {
      remainingToDeduct -= targetAccount.virtualTaxAmount;
      targetAccount.virtualTaxAmount = 0;

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

  void eseguiGiroconto({
    required String daAccountId,
    required String aAccountId,
    required double importo,
    required bool isAccantonamentoTasse,
  }) {
    final accDa = _accounts.firstWhere((a) => a.id == daAccountId);
    final accA = _accounts.firstWhere((a) => a.id == aAccountId);

    if (importo <= 0 || accDa.amount < importo) return;

    if (isAccantonamentoTasse) {
      accDa.virtualTaxAmount = (accDa.virtualTaxAmount - importo).clamp(0.0, double.infinity);
    }

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

  void toggleProUser() {
    _isProUser = !_isProUser;
    notifyListeners();
  }

  // ===========================================================================
  // 💾 SALVATAGGIO PROFILO FISCALE DAL WIZARD
  // ===========================================================================
  void salvaProfiloFiscale({
    required String codiceAteco,
    required double coeffRedditivitaVal,
    required double aliquotaImpostaVal,
    required double accontiVersati,
    required double nettoTarget,
    required double fatturatoStimato,
    required int mesiAttivi,
  }) {
    _codiceAteco = codiceAteco;
    _coefficienteRedditivita = coeffRedditivitaVal;
    coeffRedditivita = coeffRedditivitaVal;
    aliquotaImposta = aliquotaImpostaVal;
    accontiVersatiAnnoPrecedente = accontiVersati;
    _nettoTargetMensile = nettoTarget;
    _fatturatoStimatoAnnuo = fatturatoStimato;
    _mesiAttiviIncasso = mesiAttivi;

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  // ===========================================================================
  // 🔄 RESET MORBIDO: AZZERA FATTURE E MOVIMENTI MA MANTIENE IL QUESTIONARIO
  // ===========================================================================
  Future<void> resetSoloMovimentieFatture() async {
    final prefs = await SharedPreferences.getInstance();

    _accounts = [
      AccountModel(id: '1', title: 'Conto Principale (IBAN)', subtitle: 'Banca Fineco •• 4092', amount: 0.00, color: const Color(0xFF2DD4BF)),
      AccountModel(id: '2', title: 'Carta Spese & Svago', subtitle: 'Revolut Digital •• 1102', amount: 0.00, color: const Color(0xFFF59E0B)),
      AccountModel(id: '3', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6)),
    ];

    _spesoBisogni = 0.00;
    _spesoSvago = 0.00;
    _spesoRisparmi = 0.00;
    _fatturatoTotale = 0.00;
    _transactions.clear();
    _fattureDaIncassare.clear();
    _fattureIncassate.clear();

    await _salvaDatiInLocalStorage();
    notifyListeners();
  }
}