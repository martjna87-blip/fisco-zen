import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fisco_zen/data/recurrence_manager.dart';

enum AccountRole {
  principal,
  taxReserve,
  standard,
}

enum UserTier { free, pro, premium }

class AccountModel {
  final String id;
  String title;
  final String subtitle;
  double amount;
  double virtualTaxAmount;
  final Color color;
  final AccountRole role;

  AccountModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.virtualTaxAmount = 0.0,
    required this.color,
    this.role = AccountRole.standard,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'virtualTaxAmount': virtualTaxAmount,
        'color': color.value,
        'role': role.name,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String;
    final String title = (json['title'] as String? ?? '').toLowerCase();

    AccountRole roleAssegnato = AccountRole.standard;

    if (json['role'] != null) {
      roleAssegnato = AccountRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => AccountRole.standard,
      );
    }

    if (id == '1' || id == 'main_account' || title.contains('principale')) {
      roleAssegnato = AccountRole.principal;
    } else if (id == '3' ||
        id == 'tax_account' ||
        title.contains('salvadanaio tasse') ||
        title.contains('acconto tasse')) {
      roleAssegnato = AccountRole.taxReserve;
    }

    return AccountModel(
      id: id,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      virtualTaxAmount: (json['virtualTaxAmount'] as num?)?.toDouble() ?? 0.0,
      color: Color((json['color'] as num).toInt()),
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
  final DateTime? dataInizio;
  final DateTime? dataFineRicorrenza;
  final bool isArchived;

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
    this.dataInizio,
    this.dataFineRicorrenza,
    this.isArchived = false,
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
        'dataInizio': dataInizio?.toIso8601String(),
        'dataFineRicorrenza': dataFineRicorrenza?.toIso8601String(),
        'isArchived': isArchived,
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
        dataInizio: json['dataInizio'] != null ? DateTime.parse(json['dataInizio'] as String) : null,
        dataFineRicorrenza: json['dataFineRicorrenza'] != null
            ? DateTime.parse(json['dataFineRicorrenza'] as String)
            : null,
        isArchived: json['isArchived'] as bool? ?? false,
      );
}

class WalletProvider with ChangeNotifier {
  final FirebaseFirestore _firestore;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? get _userId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // 🏢 ESTRUTTURA UFFICIALE 10 MACRO-CATEGORIE PADRE (USCITE) & REGOLA BUSSOLA
  static const List<Map<String, String>> macroCategoriePadre = [
    {'padre': 'Casa & Utenze', 'bussola': 'Bisogni'},          // 50% Spese Fisse
    {'padre': 'Alimentari & Spesa', 'bussola': 'Bisogni'},     // 50% Spese Fisse
    {'padre': 'Veicoli & Trasporti', 'bussola': 'Bisogni'},    // 50% Spese Fisse
    {'padre': 'Salute & Benessere', 'bussola': 'Bisogni'},     // 50% Spese Fisse
    {'padre': 'Famiglia & Figli', 'bussola': 'Bisogni'},       // 50% Spese Fisse
    {'padre': 'Tasse & Servizi Finanziari', 'bussola': 'Bisogni'}, // 50% Spese Fisse / Neutro
    {'padre': 'Ristorazione & Svago', 'bussola': 'Svago'},     // 30% Spese Variabili
    {'padre': 'Abbigliamento & Cura', 'bussola': 'Svago'},     // 30% Spese Variabili
    {'padre': 'Servizi & Abbonamenti', 'bussola': 'Svago'},    // 30% Spese Variabili
    {'padre': 'Lavoro & P.IVA', 'bussola': 'Svago'},           // 30% Spese Variabili
  ];

  // 💰 ESTRUTTURA UFFICIALE 5 MACRO-CATEGORIE PADRE (ENTRATE)
  static const List<Map<String, String>> macroCategoriePadreEntrate = [
    {'padre': 'Fatturato P.IVA', 'bussola': 'Entrate'},
    {'padre': 'Stipendio & Pensione', 'bussola': 'Entrate'},
    {'padre': 'Rimborsi & Sussidi', 'bussola': 'Entrate'},
    {'padre': 'Investimenti & Rendite', 'bussola': 'Entrate'},
    {'padre': 'Entrate Extra & Regali', 'bussola': 'Entrate'},
  ];

  // 🧹 METODO DI NORMALIZZAZIONE TESTO (Invarianza Maiuscole/Minuscole e Simboli)
  String normalizzaTestoCategoria(String input) {
    if (input.trim().isEmpty) return 'Altro';
    String p = input.trim();
    p = p.replaceAll('&', 'e');
    p = p.replaceAll(RegExp(r'\s+'), ' ');
    
    return p.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // 🔎 TROVA O ASSEGNA LA MACRO-CATEGORIA PADRE PER QUALSIASI TAG/SOTTOCATEGORIA
  String ottieniCategoriaPadre(String sottocategoria, {bool isIncome = false}) {
    final clean = sottocategoria.toLowerCase();

    // 🟢 GESTIONE ENTRATE
    if (isIncome) {
      if (clean.contains('p.iva') || clean.contains('fattura') || clean.contains('incasso') || clean.contains('cliente')) {
        return 'Fatturato P.IVA';
      }
      if (clean.contains('stipendio') || clean.contains('pensione') || clean.contains('busta paga') || clean.contains('emolumenti')) {
        return 'Stipendio & Pensione';
      }
      if (clean.contains('rimborso') || clean.contains('bonus') || clean.contains('sussidio') || clean.contains('cashback') || clean.contains('indennita')) {
        return 'Rimborsi & Sussidi';
      }
      if (clean.contains('investim') || clean.contains('dividend') || clean.contains('cedol') || clean.contains('interess') || clean.contains('rendit')) {
        return 'Investimenti & Rendite';
      }
      return 'Entrate Extra & Regali';
    }

    // 🔴 GESTIONE USCITE
    if (clean.contains('mutuo') || clean.contains('affitto') || clean.contains('bollet') ||
        clean.contains('utenz') || clean.contains('casa') || clean.contains('condomin')) {
      return 'Casa & Utenze';
    }
    if (clean.contains('supermercat') || clean.contains('alimentar') || clean.contains('spesa') || clean.contains('panific')) {
      return 'Alimentari & Spesa';
    }
    if (clean.contains('auto') || clean.contains('carburant') || clean.contains('benzina') ||
        clean.contains('bollo') || clean.contains('trasport') || clean.contains('parchegg') || clean.contains('treno') || clean.contains('aereo')) {
      return 'Veicoli & Trasporti';
    }
    if (clean.contains('farmac') || clean.contains('salut') || clean.contains('dentist') || clean.contains('medic')) {
      return 'Salute & Benessere';
    }
    if (clean.contains('scuola') || clean.contains('infanz') || clean.contains('figli') || clean.contains('animal') || clean.contains('pet')) {
      return 'Famiglia & Figli';
    }
    if (clean.contains('tasse') || clean.contains('f24') || clean.contains('impost') || clean.contains('commission')) {
      return 'Tasse & Servizi Finanziari';
    }
    if (clean.contains('ristorant') || clean.contains('bar') || clean.contains('pizzeri') ||
        clean.contains('pub') || clean.contains('deliver') || clean.contains('cinema') || clean.contains('hobby') || clean.contains('viagg')) {
      return 'Ristorazione & Svago';
    }
    if (clean.contains('vestit') || clean.contains('abbigliament') || clean.contains('scarp') || clean.contains('parrucchier') || clean.contains('estet')) {
      return 'Abbigliamento & Cura';
    }
    if (clean.contains('netflix') || clean.contains('spotify') || clean.contains('palestra') || clean.contains('internet') || clean.contains('abbonam')) {
      return 'Servizi & Abbonamenti';
    }
    if (clean.contains('p.iva') || clean.contains('lavoro') || clean.contains('software') || clean.contains('canceller')) {
      return 'Lavoro & P.IVA';
    }

    return 'Ristorazione & Svago';
  }

  List<AccountModel> _accounts = [
    AccountModel(
      id: 'main_account',
      title: 'Conto Principale (IBAN)',
      subtitle: 'Conto Operativo',
      amount: 0.00,
      color: const Color(0xFF2DD4BF),
      role: AccountRole.principal,
    ),
    AccountModel(
      id: 'tax_account',
      title: 'Salvadanaio Tasse',
      subtitle: 'Obiettivo Riserva',
      amount: 0.00,
      color: const Color(0xFF3B82F6),
      role: AccountRole.taxReserve,
    ),
    AccountModel(
      id: 'savings_account',
      title: 'Fondo Risparmio',
      subtitle: 'Riserva Liquidità',
      amount: 0.00,
      color: const Color(0xFFF59E0B),
      role: AccountRole.standard,
    ),
  ];

  List<AccountModel> get accounts => List.unmodifiable(_accounts);

  UserTier _userTier = UserTier.free;
  UserTier get userTier => _userTier;

  bool get isFree => _userTier == UserTier.free;
  bool get isPro => _userTier == UserTier.pro;
  bool get isPremium => _userTier == UserTier.premium;

  bool get isProUser => _userTier != UserTier.free;
  bool get canUseOCR => _userTier == UserTier.pro || _userTier == UserTier.premium;
  bool get canSendSDI => _userTier == UserTier.premium;

  void setUserTier(UserTier tier) {
    _userTier = tier;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void cycleUserTier() {
    if (_userTier == UserTier.free) {
      _userTier = UserTier.pro;
    } else if (_userTier == UserTier.pro) {
      _userTier = UserTier.premium;
    } else {
      _userTier = UserTier.free;
    }
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void impostaStatoPro(bool valore) {
    _userTier = valore ? UserTier.pro : UserTier.free;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void setProUser(bool valore) => impostaStatoPro(valore);

  void attivaPro() {
    _userTier = UserTier.pro;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void disattivaPro() {
    _userTier = UserTier.free;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void toggleProUser() => cycleUserTier();

  double _textScaleFactor = 1.0;
  double get textScaleFactor => _textScaleFactor;

  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  String _codiceAteco = '74.10.21';
  String get codiceAteco => _codiceAteco;

  double _coefficienteRedditivita = 0.78;
  double coeffRedditivita = 0.78;

  double _aliquotaImposta = 0.05;
  double aliquotaImposta = 0.05;

  double _aliquotaInps = 0.2607;
  double aliquotaInps = 0.2607;

  String _tipoCassa = 'gestioneSeparata';
  bool _isStartup = true;

  String _tipoLavoroDipendente = 'nessuno';
  String? get tipoLavoroDipendente => _tipoLavoroDipendente;

  bool _scontoInps35 = false;

  double accontiVersatiAnnoPrecedente = 0.0;
  double _accontiVersati = 0.0;
  double get accontiVersati => _accontiVersati;

  double _contributiInpsPagatiAnnoCorrente = 0.0;

  double _nettoTargetMensile = 2500.0;

  double _fatturatoStimatoAnnuo = 35000.0;
  double get fatturatoStimato => _fatturatoStimatoAnnuo;

  int _mesiAttiviIncasso = 10;
  int get mesiAttivi => _mesiAttiviIncasso;
  double get nettoTargetMensile => _nettoTargetMensile;

  List<bool> _mesiAttiviState = List.generate(12, (index) => index < 10);
  List<bool> get mesiAttiviState => List.unmodifiable(_mesiAttiviState);

  double _cuscinettoAccumulato = 0.0;
  double _cuscinettoUtilizzato = 0.0;
  double get cuscinettoAccumulato => _cuscinettoAccumulato;
  double get cuscinettoUtilizzato => _cuscinettoUtilizzato;
  double get cuscinettoResiduo => (_cuscinettoAccumulato - _cuscinettoUtilizzato).clamp(0.0, double.infinity);

  int? _annoAperturaPiva = 2026;
  int? get annoAperturaPiva => _annoAperturaPiva;

  int? _meseAperturaPiva = 1;
  int? get meseAperturaPiva => _meseAperturaPiva;

  double _entrataExtraMensile = 0.0;
  double get entrataExtraMensile => _entrataExtraMensile;

  int _numeroMensilitaExtra = 13;
  int get numeroMensilitaExtra => _numeroMensilitaExtra;

  bool _hasDipendente = false;
  bool get hasDipendente => _hasDipendente;

  bool _hasPensione = false;
  bool get hasPensione => _hasPensione;

  bool get haInseritoStipendioMeseCorrente {
    final ora = DateTime.now();
    return _transactions.any((tx) {
      if (!tx.isIncome) return false;
      if (tx.date.year != ora.year || tx.date.month != ora.month) return false;

      final catLower = tx.category.toLowerCase();
      final titleLower = tx.title.toLowerCase();

      final bool isPivaOIncasso = tx.category == 'P.IVA' ||
          titleLower.startsWith('incasso') ||
          titleLower.startsWith('fattura');
      if (isPivaOIncasso || tx.category == 'Giroconto') return false;

      return catLower.contains('stipendio') ||
          catLower.contains('pensione') ||
          titleLower.contains('stipendio') ||
          titleLower.contains('pensione');
    });
  }

  bool get mostraTipAccreditoStipendio =>
      (hasDipendente || hasPensione) &&
      _entrataExtraMensile > 0 &&
      !haInseritoStipendioMeseCorrente &&
      !dismissedTipKeys.contains('tip_stipendio_${DateTime.now().year}_${DateTime.now().month}');

  void accreditaStipendioRapido() {
    if (_entrataExtraMensile <= 0) return;

    final String etichetta = _hasDipendente ? 'Stipendio Dipendente' : 'Assegno Pensione';
    final contoPrincipale = _accounts.firstWhere(
      (a) => a.role == AccountRole.principal || a.id == 'main_account' || a.id == '1',
      orElse: () => _accounts.first,
    );

    addTransaction(
      title: 'Accredito: $etichetta',
      amount: _entrataExtraMensile,
      isIncome: true,
      category: 'Stipendio',
      accountId: contoPrincipale.id,
      date: DateTime.now(),
    );
  }

  double get sogliaForfettarioReale {
    final int annoCorrente = DateTime.now().year;
    if (_annoAperturaPiva == annoCorrente && _meseAperturaPiva != null) {
      final int mesiAttivi = (12 - _meseAperturaPiva! + 1).clamp(1, 12);
      return (85000.0 / 12.0) * mesiAttivi;
    }
    return 85000.0;
  }

  bool isPartitaIVA = true;

  int _annoFiscaleCorrente = DateTime.now().year;
  int get annoFiscaleCorrente => _annoFiscaleCorrente;

  void setAnnoFiscale(int anno) {
    if (_annoFiscaleCorrente != anno) {
      _annoFiscaleCorrente = anno;
      notifyListeners();
    }
  }

  int _estraiAnnoDaData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return _annoFiscaleCorrente;
    final cleanStr = dataStr.trim().toLowerCase();
    if (cleanStr == 'oggi') return DateTime.now().year;

    try {
      if (cleanStr.contains('/')) {
        final parts = cleanStr.split('/');
        if (parts.length >= 3) {
          final aStr = parts[2].trim().split(' ').first;
          final a = int.tryParse(aStr);
          if (a != null) return a < 100 ? 2000 + a : a;
        }
      }
      if (cleanStr.contains('-')) {
        final parts = cleanStr.split('-');
        if (parts.length >= 3) {
          final a = int.tryParse(parts[0].trim());
          if (a != null) return a;
        }
      }
      final parsed = DateTime.tryParse(cleanStr);
      if (parsed != null) return parsed.year;
    } catch (_) {}

    return _annoFiscaleCorrente;
  }

  List<Map<String, dynamic>> get fattureIncassateAnnoCorrente {
    return _fattureIncassate.where((f) {
      final dataIncasso = f['dataIncasso'] as String? ?? '';
      final dataEmissione = f['data'] as String? ?? '';

      int anno = _estraiAnnoDaData(dataIncasso);
      if (!dataIncasso.contains('/20') && !dataIncasso.contains('-20') && dataEmissione.isNotEmpty) {
        anno = _estraiAnnoDaData(dataEmissione);
      }

      return anno == _annoFiscaleCorrente;
    }).toList();
  }

  List<Map<String, dynamic>> get fattureDaIncassareAnnoCorrente {
    return _fattureDaIncassare.where((f) {
      final dataStr = f['data'] as String? ?? '';
      return _estraiAnnoDaData(dataStr) == _annoFiscaleCorrente;
    }).toList();
  }

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

  void salvaContiIniziali(List<AccountModel> nuoviConti) {
    _accounts = List.from(nuoviConti);
    _transactions.removeWhere((t) => t.id.contains('_init_'));

    for (var acc in _accounts) {
      if (acc.amount > 0) {
        _transactions.insert(
          0,
          TransactionModel(
            id: '${acc.id}_init_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Saldo Iniziale: ${acc.title}',
            subtitle: 'Impostazione Onboarding',
            amount: acc.amount,
            isIncome: true,
            category: 'Risparmi',
            date: DateTime.now(),
            accountId: acc.id,
          ),
        );
      }
    }

    _aggiornaTasseVirtuali();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void salvaEntrateExtra({
    required double importoMensile,
    required bool dipendente,
    required bool pensione,
    int? numeroMensilita,
  }) {
    _entrataExtraMensile = importoMensile;
    _hasDipendente = dipendente;
    _hasPensione = pensione;
    if (numeroMensilita != null) {
      _numeroMensilitaExtra = numeroMensilita;
    }
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void _calcolaStatoCuscinetto() {
    if (!isPartitaIVA || _mesiAttiviIncasso == 12) {
      _cuscinettoAccumulato = 0.0;
      _cuscinettoUtilizzato = 0.0;
      return;
    }

    if (_mesiAttiviState.where((m) => m).length != _mesiAttiviIncasso) {
      _mesiAttiviState = List.generate(12, (index) => index < _mesiAttiviIncasso);
    }

    final int annoCorrente = DateTime.now().year;
    final int meseCorrenteIndex = DateTime.now().month - 1;

    double totaleAccumulato = 0.0;
    double totaleUtilizzato = 0.0;

    for (var tx in _transactions) {
      if (tx.isIncome && tx.date.year == annoCorrente && tx.date.month <= DateTime.now().month) {
        if (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso')) {
          final double nettoPiva = tx.amount * (1 - aliquotaFiscaleReale);
          final double percentualeAccantonamento = (12 - _mesiAttiviIncasso) / 12;
          totaleAccumulato += (nettoPiva * percentualeAccantonamento);
        }
      }
    }

    for (int i = 0; i <= meseCorrenteIndex; i++) {
      final bool isMeseLavorativo = _mesiAttiviState[i];
      if (!isMeseLavorativo) {
        final double quotaErogata = (_nettoTargetMensile - _entrataExtraMensile).clamp(0.0, double.infinity);
        totaleUtilizzato += quotaErogata;
      }
    }

    _cuscinettoAccumulato = totaleAccumulato;
    _cuscinettoUtilizzato = totaleUtilizzato;
  }

  void setMesiAttiviState(List<bool> newState) {
    _mesiAttiviState = List.from(newState);
    _mesiAttiviIncasso = newState.where((m) => m).length;
    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  bool _haRispostoRicalibrazione = false;
  bool get haRispostoRicalibrazione => _haRispostoRicalibrazione;

  void impostaRispostaRicalibrazione(bool valore) {
    _haRispostoRicalibrazione = valore;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  String get statoRitmoFatturato {
    if (!isPartitaIVA || _fatturatoStimatoAnnuo <= 0) return 'in_linea';

    final int meseCorrente = DateTime.now().month;
    final int annoReale = DateTime.now().year;

    final double fatturatoRealeAnnoCorrente = _fattureIncassate.where((f) {
      final dataIncasso = f['dataIncasso'] as String? ?? f['data'] as String? ?? '';
      return _estraiAnnoDaData(dataIncasso) == annoReale;
    }).fold(0.0, (sum, item) => sum + ((item['importo'] as num?)?.toDouble() ?? 0.0));

    int mesiLavorativiPassati = 0;
    for (int i = 0; i < meseCorrente; i++) {
      if (_mesiAttiviState.length > i && _mesiAttiviState[i]) {
        mesiLavorativiPassati++;
      }
    }

    if (mesiLavorativiPassati == 0) return 'in_linea';

    final double ritmoTeoricoMensile = _fatturatoStimatoAnnuo / _mesiAttiviIncasso;
    final double targetAdOggi = ritmoTeoricoMensile * mesiLavorativiPassati;

    if (targetAdOggi <= 0) return 'in_linea';

    final double scostamento = (fatturatoRealeAnnoCorrente - targetAdOggi) / targetAdOggi;

    if (scostamento > 0.15) return 'over';
    if (scostamento < -0.15) return 'under';
    return 'in_linea';
  }

  double getEntrataPrevistaMeseFuturo(DateTime meseFuturo) {
    double stimaEntrata = 0.0;

    if (_entrataExtraMensile > 0) {
      bool isDoppiaMensilita = false;
      if (_numeroMensilitaExtra == 13 && meseFuturo.month == 12) {
        isDoppiaMensilita = true;
      } else if (_numeroMensilitaExtra == 14 && (meseFuturo.month == 6 || meseFuturo.month == 12)) {
        isDoppiaMensilita = true;
      }
      stimaEntrata += isDoppiaMensilita ? (_entrataExtraMensile * 2) : _entrataExtraMensile;
    }

    if (isPartitaIVA) {
      final int indexMeseFuturo = meseFuturo.month - 1;
      final bool isMeseLavorativo = _mesiAttiviState.length > indexMeseFuturo
          ? _mesiAttiviState[indexMeseFuturo]
          : true;

      if (isMeseLavorativo) {
        final int meseCorrente = DateTime.now().month;
        int mesiLavorativiRimanenti = 0;

        for (int i = meseCorrente; i < 12; i++) {
          if (_mesiAttiviState.length > i && _mesiAttiviState[i]) {
            mesiLavorativiRimanenti++;
          }
        }

        final double fatturatoResiduo = (_fatturatoStimatoAnnuo - fatturatoTotale).clamp(0.0, double.infinity);

        double lordoMensileStima = mesiLavorativiRimanenti > 0
            ? (fatturatoResiduo / mesiLavorativiRimanenti)
            : (_fatturatoStimatoAnnuo / (_mesiAttiviIncasso > 0 ? _mesiAttiviIncasso : 12));

        final double nettoMensileStima = lordoMensileStima * (1 - aliquotaFiscaleReale);
        stimaEntrata += nettoMensileStima;
      }
    }

    if (stimaEntrata <= 0 && _nettoTargetMensile > 0) {
      return _nettoTargetMensile;
    }

    return stimaEntrata;
  }

  List<Map<String, dynamic>> calcolaMatriceProiezioneAnnuale({int? annoSelezionato}) {
    final int anno = annoSelezionato ?? DateTime.now().year;
    final DateTime ora = DateTime.now();
    final double aliquotaTasse = aliquotaFiscaleReale;

    final Map<int, double> pivaAnnoMap = _pilotaggioFatturatoMesi[anno] ?? {};
    final Map<int, double> stipAnnoMap = _pilotaggioStipendioMesi[anno] ?? {};

    final List<String> nomiMesi = [
      'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
      'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
    ];

    final int annoRiferimentoStorico = anno <= ora.year ? (ora.year - 1) : ora.year;
    final Map<int, double> pesiCurvaIbrida = {};
    double sommaValoriRiferimento = 0.0;
    int mesiYtdCompletati = 0;

    for (int m = 1; m <= 12; m++) {
      double valoreMesePiva = 0.0;
      final bool isMesePassatoOReale = (annoRiferimentoStorico < ora.year) ||
          (annoRiferimentoStorico == ora.year && m < ora.month);

      if (isMesePassatoOReale) {
        final lordoFatture = _fattureIncassate.where((f) {
          final dataStr = f['dataIncasso'] as String? ?? f['data'] as String? ?? '';
          return _estraiAnnoDaData(dataStr) == annoRiferimentoStorico &&
              (dataStr.contains('/$m/') || dataStr.contains('-0$m-') || dataStr.contains('-$m-'));
        }).fold(0.0, (sum, f) => sum + ((f['importo'] as num?)?.toDouble() ?? 0.0));

        final lordoTx = _transactions.where((tx) {
          return tx.isIncome &&
              tx.date.year == annoRiferimentoStorico &&
              tx.date.month == m &&
              (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso'));
        }).fold(0.0, (sum, tx) => sum + tx.amount);

        valoreMesePiva = lordoFatture > lordoTx ? lordoFatture : lordoTx;
        if (valoreMesePiva > 0) mesiYtdCompletati++;
      } else {
        valoreMesePiva = (_pilotaggioFatturatoMesi[annoRiferimentoStorico] ?? {})[m] ?? 0.0;
      }

      pesiCurvaIbrida[m] = valoreMesePiva;
      sommaValoriRiferimento += valoreMesePiva;
    }

    final double alphaDamping = (mesiYtdCompletati >= 3)
        ? 1.0
        : (mesiYtdCompletati == 2 ? 0.6 : (mesiYtdCompletati == 1 ? 0.3 : 0.0));

    int conteggioMesiOn = 0;
    for (int m = 1; m <= 12; m++) {
      final bool isMeseON = _mesiAttiviState.length >= m ? _mesiAttiviState[m - 1] : true;
      if (isMeseON) conteggioMesiOn++;
    }
    if (conteggioMesiOn == 0) conteggioMesiOn = 12;

    final double pesoNeutralePiatto = 1.0 / conteggioMesiOn;
    final Map<int, double> pesiNormalizzati = {};

    for (int m = 1; m <= 12; m++) {
      final bool isMeseON = _mesiAttiviState.length >= m ? _mesiAttiviState[m - 1] : true;
      if (isMeseON) {
        double pesoRealeYtd = (sommaValoriRiferimento > 0)
            ? (pesiCurvaIbrida[m]! / sommaValoriRiferimento)
            : pesoNeutralePiatto;

        pesiNormalizzati[m] = (alphaDamping * pesoRealeYtd) + ((1.0 - alphaDamping) * pesoNeutralePiatto);
      } else {
        pesiNormalizzati[m] = 0.0;
      }
    }

    double lordoIncassatoRealePassato = 0.0;
    for (int m = 1; m <= 12; m++) {
      final bool isPassato = (anno < ora.year) || (anno == ora.year && m < ora.month);
      if (isPassato) {
        final lordoFatture = _fattureIncassate.where((f) {
          final dataStr = f['dataIncasso'] as String? ?? f['data'] as String? ?? '';
          return _estraiAnnoDaData(dataStr) == anno &&
              (dataStr.contains('/$m/') || dataStr.contains('-0$m-') || dataStr.contains('-$m-'));
        }).fold(0.0, (sum, f) => sum + ((f['importo'] as num?)?.toDouble() ?? 0.0));

        final lordoTx = _transactions.where((tx) {
          return tx.isIncome &&
              tx.date.year == anno &&
              tx.date.month == m &&
              (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso'));
        }).fold(0.0, (sum, tx) => sum + tx.amount);

        lordoIncassatoRealePassato += (lordoFatture > lordoTx ? lordoFatture : lordoTx);
      }
    }

    final double lordoResiduoYTG = (_fatturatoStimatoAnnuo - lordoIncassatoRealePassato).clamp(0.0, double.infinity);

    double totaleDeficitMesiOffFuturi = 0.0;
    double totaleSurplusMesiOnFuturi = 0.0;

    for (int m = 1; m <= 12; m++) {
      final bool isPassato = (anno < ora.year) || (anno == ora.year && m < ora.month);
      final bool isMeseOFF = _mesiAttiviState.length >= m ? !_mesiAttiviState[m - 1] : false;
      final bool isManualPiva = pivaAnnoMap.containsKey(m) && pivaAnnoMap[m]! > 0;
      final bool isManualStipendio = stipAnnoMap.containsKey(m) && stipAnnoMap[m]! > 0;

      if (!isPassato && isPartitaIVA) {
        double stip = isManualStipendio ? stipAnnoMap[m]! : (_entrataExtraMensile > 0 ? _entrataExtraMensile : 0.0);
        if (_numeroMensilitaExtra == 13 && m == 12) stip += _entrataExtraMensile;
        if (_numeroMensilitaExtra == 14 && (m == 6 || m == 12)) stip += _entrataExtraMensile;

        if (isMeseOFF) {
          final double deficit = (_nettoTargetMensile - stip).clamp(0.0, double.infinity);
          totaleDeficitMesiOffFuturi += deficit;
        } else {
          double pivaLorda = isManualPiva ? pivaAnnoMap[m]! : (lordoResiduoYTG * pesiNormalizzati[m]!);
          double pivaNetta = pivaLorda * (1 - aliquotaTasse);
          double totaleNettoPrimaCuscinetto = pivaNetta + stip;
          double surplus = (totaleNettoPrimaCuscinetto - _nettoTargetMensile).clamp(0.0, double.infinity);
          totaleSurplusMesiOnFuturi += surplus;
        }
      }
    }

    // 💡 CALCOLO PUNTUALE DEFICIT REALE SOLO SUI MESI OFF FUTURI EFFETTIVI
    double deficitRealeOffTotale = 0.0;
    for (int mFilter = 1; mFilter <= 12; mFilter++) {
      final bool ePassato = (anno < ora.year) || (anno == ora.year && mFilter < ora.month);
      final bool eOFF = _mesiAttiviState.length >= mFilter ? !_mesiAttiviState[mFilter - 1] : false;
      if (!ePassato && eOFF) {
        final bool eStipManual = stipAnnoMap.containsKey(mFilter) && stipAnnoMap[mFilter]! > 0;
        double stip = eStipManual ? stipAnnoMap[mFilter]! : (_entrataExtraMensile > 0 ? _entrataExtraMensile : 0.0);
        if (_numeroMensilitaExtra == 13 && mFilter == 12) stip += _entrataExtraMensile;
        if (_numeroMensilitaExtra == 14 && (mFilter == 6 || mFilter == 12)) stip += _entrataExtraMensile;
        
        final double defMese = (_nettoTargetMensile - stip).clamp(0.0, double.infinity);
        deficitRealeOffTotale += defMese;
      }
    }

    final double copertaCortaRatio = 1.0;
    final List<Map<String, dynamic>> matrice = [];

    // 💡 TRACCIATORE SEQUENZIALE DINAMICO DEL DEFICIT DA COPRIRE
    double deficitAncoraDaCoprire = deficitRealeOffTotale;

    for (int m = 1; m <= 12; m++) {
      final bool isPassato = (anno < ora.year) || (anno == ora.year && m < ora.month);
      final bool isCorrente = (anno == ora.year && m == ora.month);
      final bool isMeseOFF = _mesiAttiviState.length >= m ? !_mesiAttiviState[m - 1] : false;
      final bool isManualPiva = pivaAnnoMap.containsKey(m) && pivaAnnoMap[m]! > 0;
      final bool isManualStipendio = stipAnnoMap.containsKey(m) && stipAnnoMap[m]! > 0;

      double entrataStipendio = 0.0;
      if (isPassato) {
        entrataStipendio = _transactions.where((tx) {
          return tx.isIncome &&
              tx.date.year == anno &&
              tx.date.month == m &&
              (tx.category == 'Stipendio' || tx.category == 'Pensione' || tx.title.toLowerCase().contains('stipendio'));
        }).fold(0.0, (sum, tx) => sum + tx.amount);
      } else if (isManualStipendio) {
        entrataStipendio = stipAnnoMap[m]!;
      } else if (_entrataExtraMensile > 0) {
        entrataStipendio = _entrataExtraMensile;
        if (_numeroMensilitaExtra == 13 && m == 12) entrataStipendio += _entrataExtraMensile;
        if (_numeroMensilitaExtra == 14 && (m == 6 || m == 12)) entrataStipendio += _entrataExtraMensile;
      }

      double entrataPivaLorda = 0.0;
      double entrataPivaNetta = 0.0;

      if (isPassato) {
        final lordoFatture = _fattureIncassate.where((f) {
          final dataStr = f['dataIncasso'] as String? ?? f['data'] as String? ?? '';
          return _estraiAnnoDaData(dataStr) == anno &&
              (dataStr.contains('/$m/') || dataStr.contains('-0$m-') || dataStr.contains('-$m-'));
        }).fold(0.0, (sum, f) => sum + ((f['importo'] as num?)?.toDouble() ?? 0.0));

        final lordoTx = _transactions.where((tx) {
          return tx.isIncome &&
              tx.date.year == anno &&
              tx.date.month == m &&
              (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso'));
        }).fold(0.0, (sum, tx) => sum + tx.amount);

        entrataPivaLorda = lordoFatture > lordoTx ? lordoFatture : lordoTx;
        entrataPivaNetta = entrataPivaLorda * (1 - aliquotaTasse);
      } else if (isMeseOFF) {
        entrataPivaLorda = 0.0;
        entrataPivaNetta = 0.0;
      } else if (isManualPiva) {
        entrataPivaLorda = pivaAnnoMap[m]!;
        entrataPivaNetta = entrataPivaLorda * (1 - aliquotaTasse);
      } else if (isPartitaIVA) {
        final double stimaLordaCurva = lordoResiduoYTG * pesiNormalizzati[m]!;

        if (isCorrente) {
          final double incassatoRealeCorrente = _transactions.where((tx) {
            return tx.isIncome &&
                tx.date.year == anno &&
                tx.date.month == m &&
                (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso'));
          }).fold(0.0, (sum, tx) => sum + tx.amount);

          entrataPivaLorda = incassatoRealeCorrente > stimaLordaCurva ? incassatoRealeCorrente : stimaLordaCurva;
        } else {
          entrataPivaLorda = stimaLordaCurva;
        }

        entrataPivaNetta = entrataPivaLorda * (1 - aliquotaTasse);
      }

      double speseMese = 0.0;
      if (isPassato) {
        speseMese = _transactions.where((tx) {
          return !tx.isIncome &&
              tx.date.year == anno &&
              tx.date.month == m &&
              tx.category != 'Giroconto' &&
              !tx.title.toLowerCase().contains('giroconto');
        }).fold(0.0, (sum, tx) => sum + tx.amount);
      } else {
        speseMese = vociPianificate.fold(0.0, (sum, v) {
          final double p = (v['previsto'] as num?)?.toDouble() ?? 0.0;

          if (v['dataFineRicorrenza'] != null) {
            final DateTime? dataFine = v['dataFineRicorrenza'] is DateTime
                ? v['dataFineRicorrenza'] as DateTime
                : DateTime.tryParse(v['dataFineRicorrenza'].toString());

            if (dataFine != null) {
              final DateTime inizioMeseFuturo = DateTime(anno, m, 1);
              final DateTime inizioMeseFine = DateTime(dataFine.year, dataFine.month, 1);
              if (inizioMeseFuturo.isAfter(inizioMeseFine)) {
                return sum;
              }
            }
          }

          return sum + p;
        });
      }

      double quotaCuscinetto = 0.0;
      double erogazioneCuscinetto = 0.0;

      if (!isPassato && isPartitaIVA) {
        if (isMeseOFF) {
          final double deficitNominale = (_nettoTargetMensile - entrataStipendio).clamp(0.0, double.infinity);
          erogazioneCuscinetto = deficitNominale * copertaCortaRatio;
          quotaCuscinetto = erogazioneCuscinetto;
        } else {
          final double surplusMeseNetto = (entrataPivaNetta + entrataStipendio - _nettoTargetMensile).clamp(0.0, double.infinity);
          
          // 💡 SATURAZIONE PRIORITARIA SEQUENZIALE REALE
          if (deficitAncoraDaCoprire > 0 && surplusMeseNetto > 0) {
            if (surplusMeseNetto >= deficitAncoraDaCoprire) {
              quotaCuscinetto = deficitAncoraDaCoprire;
              deficitAncoraDaCoprire = 0.0;
            } else {
              quotaCuscinetto = surplusMeseNetto;
              deficitAncoraDaCoprire = (deficitAncoraDaCoprire - surplusMeseNetto).clamp(0.0, double.infinity);
            }
          } else {
            quotaCuscinetto = 0.0;
          }
        }
      }

      final double entrataTotaleNetta = isMeseOFF
          ? (entrataStipendio + erogazioneCuscinetto)
          : (entrataPivaNetta + entrataStipendio);

      final double bilancioNetto = isMeseOFF
          ? (entrataTotaleNetta - speseMese)
          : (entrataTotaleNetta - quotaCuscinetto - speseMese);

      final bool haAnomalia = isPartitaIVA &&
          !isPassato &&
          !isMeseOFF &&
          _mesiAttiviIncasso > 0 &&
          (entrataPivaLorda < (_fatturatoStimatoAnnuo / _mesiAttiviIncasso) * 0.4);

      final double targetMensileNetto = (_fatturatoStimatoAnnuo * (1 - aliquotaTasse) / 12) + _entrataExtraMensile;

      Color coloreStato = const Color(0xFF10B981);
      if (entrataTotaleNetta < targetMensileNetto * 0.90) {
        coloreStato = const Color(0xFFEF4444);
      } else if (entrataTotaleNetta < targetMensileNetto) {
        coloreStato = const Color(0xFFFBBF24);
      }

      matrice.add({
        'meseIdx': m,
        'nomeMese': nomiMesi[m - 1],
        'isPassato': isPassato,
        'isCorrente': isCorrente,
        'isMeseOFF': isMeseOFF,
        'isMeseON': !isMeseOFF,
        'isManualOverride': isManualPiva || isManualStipendio,
        'isManualPiva': isManualPiva,
        'isManualStipendio': isManualStipendio,
        'haAnomalia': haAnomalia,
        'entrataStipendio': entrataStipendio,
        'entrataPivaLorda': entrataPivaLorda,
        'entrataPivaNetta': entrataPivaNetta,
        'erogazioneCuscinetto': erogazioneCuscinetto,
        'quotaCuscinetto': quotaCuscinetto,
        'entrataTotaleNetta': entrataTotaleNetta,
        'speseMese': speseMese,
        'bilancioNetto': bilancioNetto,
        'coloreStato': coloreStato,
        'copertaCorta': copertaCortaRatio < 1.0,
      });
    }

    return matrice;
  }

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
      final aliquotaInpsVal = (_tipoLavoroDipendente != 'nessuno') ? 0.24 : 0.2607;
      stimaInpsAnnuo = imponibileLordo * aliquotaInpsVal;
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

    final aliquotaImpostaVal = _isStartup ? 0.05 : 0.15;
    final stimaImpostaAnnuo = imponibileNettoTasse * aliquotaImpostaVal;
    final totaleTasseAnnuo = stimaInpsAnnuo + stimaImpostaAnnuo;
    final nettoRealeAnnuo = fatturato - totaleTasseAnnuo;
    final stipendioMensile12Mesi = (nettoRealeAnnuo / 12) + _entrataExtraMensile;
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

  double get patrimonioNetto => _accounts.fold(0.0, (sum, item) => sum + item.amount);
  double get _tasseLordeAccantonate => _accounts.fold(0.0, (sum, item) => sum + item.virtualTaxAmount);

  double get fondoTasseDaVersare {
    double fondo = _tasseLordeAccantonate - accontiVersatiAnnoPrecedente;
    return fondo > 0 ? fondo : 0.0;
  }

  double get nettoSpendibile => patrimonioNetto - fondoTasseDaVersare;

  String ottieniBussolaSemplificata(TransactionModel tx) {
    final testoCompleto = '${tx.category} ${tx.title} ${tx.subtitle}'.toLowerCase();

    if (tx.category == 'Imposte & F24' || testoCompleto.contains('f24') || testoCompleto.contains('imposte') || tx.category == 'Giroconto') {
      return 'Escluso';
    }

    if (testoCompleto.contains('20%') || testoCompleto.contains('risparm') || testoCompleto.contains('invest') || testoCompleto.contains('salvadanaio')) {
      return 'Risparmi';
    }

    final String padre = ottieniCategoriaPadre(tx.category, isIncome: tx.isIncome);
    final matchMacro = macroCategoriePadre.firstWhere((m) => m['padre'] == padre, orElse: () => {'bussola': 'Bisogni'});

    return matchMacro['bussola'] ?? 'Bisogni';
  }

  double getSpesoBussola(String targetBussola) {
    final ora = DateTime.now();
    return _transactions.where((tx) {
      if (tx.isIncome) return false;
      if (tx.date.year != ora.year || tx.date.month != ora.month) return false;

      return ottieniBussolaSemplificata(tx) == targetBussola;
    }).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get spesoBisogni => getSpesoBussola('Bisogni');
  double get spesoSvago => getSpesoBussola('Svago');
  double get spesoRisparmi => getSpesoBussola('Risparmi');

  double _fatturatoTotale = 0.00;

  double get fatturatoTotale {
    return fattureIncassateAnnoCorrente.fold(
      0.0,
      (sum, item) => sum + ((item['importo'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double get fatturatoTotaleAnnoCorrenteReale {
    final int annoReale = DateTime.now().year;
    return _fattureIncassate.where((f) {
      final dataIncasso = f['dataIncasso'] as String? ?? f['data'] as String? ?? '';
      return _estraiAnnoDaData(dataIncasso) == annoReale;
    }).fold(0.0, (sum, item) => sum + ((item['importo'] as num?)?.toDouble() ?? 0.0));
  }

  double get stimaTasseAccantonate => fatturatoTotale * aliquotaFiscaleReale;
  double get nettoPiva => fatturatoTotale - stimaTasseAccantonate;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  double _percentBisogni = 50.0;
  double _percentSvago = 30.0;
  double _percentRisparmio = 20.0;

  double get percentBisogni => _percentBisogni;
  double get percentSvago => _percentSvago;
  double get percentRisparmio => _percentRisparmio;

  Map<int, Map<int, double>> _pilotaggioFatturatoMesi = {};
  Map<int, Map<int, double>> _pilotaggioStipendioMesi = {};

  void resetPilotaggioAnno(int anno) {
    _pilotaggioFatturatoMesi.remove(anno);
    _pilotaggioStipendioMesi.remove(anno);
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void resetPilotaggio() {
    _pilotaggioFatturatoMesi.clear();
    _pilotaggioStipendioMesi.clear();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  Map<int, Map<int, double>> get pilotaggioFatturatoMesi => Map.unmodifiable(_pilotaggioFatturatoMesi);
  Map<int, Map<int, double>> get pilotaggioStipendioMesi => Map.unmodifiable(_pilotaggioStipendioMesi);

  Map<int, double> getPilotaggioFatturatoPerAnno(int anno) =>
      Map.unmodifiable(_pilotaggioFatturatoMesi[anno] ?? {});

  Map<int, double> getPilotaggioStipendioPerAnno(int anno) =>
      Map.unmodifiable(_pilotaggioStipendioMesi[anno] ?? {});

  void impostaStipendioMese(int mese, double importo, {int? anno}) {
    final int targetAnno = anno ?? DateTime.now().year;
    _pilotaggioStipendioMesi.putIfAbsent(targetAnno, () => {});
    if (importo <= 0) {
      _pilotaggioStipendioMesi[targetAnno]!.remove(mese);
      if (_pilotaggioStipendioMesi[targetAnno]!.isEmpty) {
        _pilotaggioStipendioMesi.remove(targetAnno);
      }
    } else {
      _pilotaggioStipendioMesi[targetAnno]![mese] = importo;
    }
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  List<Map<String, dynamic>> _vociPianificateReali = [];

  final List<Map<String, dynamic>> _vociPianificateDemo = [
    {'id': '1', 'nome': 'Affitto / Mutuo', 'categoria': 'Bisogni (50%)', 'sottocategoria': 'Casa/Affitto', 'previsto': 650.00, 'tipo': 'mensile', 'frequenzaMensile': 'tutti'},
    {'id': '2', 'nome': 'Bollette & Utenze', 'categoria': 'Bisogni (50%)', 'sottocategoria': 'Canoni/Bollette', 'previsto': 140.00, 'tipo': 'mensile', 'frequenzaMensile': 'tutti'},
    {'id': '3', 'nome': 'Spesa Alimentare', 'categoria': 'Bisogni (50%)', 'sottocategoria': 'Alimentari', 'previsto': 350.00, 'tipo': 'variabile', 'frequenzaMensile': 'tutti'},
    {'id': '4', 'nome': 'Assicurazione Auto', 'categoria': 'Bisogni (50%)', 'sottocategoria': 'Auto', 'previsto': 120.00, 'tipo': 'annuale_spalmata', 'totaleAnnuale': 1440.00, 'meseScadenza': 'SET'},
    {'id': '5', 'nome': 'Ristoranti & Uscite', 'categoria': 'Svago (30%)', 'sottocategoria': 'Divertimento', 'previsto': 200.00, 'tipo': 'variabile', 'frequenzaMensile': 'tutti'},
    {'id': '6', 'nome': 'Hobby & Palestra', 'categoria': 'Svago (30%)', 'sottocategoria': 'Divertimento', 'previsto': 80.00, 'tipo': 'mensile', 'frequenzaMensile': 'tutti'},
    {'id': '7', 'nome': 'Abbonamenti Streaming', 'categoria': 'Svago (30%)', 'sottocategoria': 'Canoni/Bollette', 'previsto': 30.00, 'tipo': 'mensile', 'frequenzaMensile': 'tutti'},
    {'id': '8', 'nome': 'Fondo Emergenze', 'categoria': 'Risparmio (20%)', 'sottocategoria': 'Altro', 'previsto': 300.00, 'tipo': 'mensile', 'frequenzaMensile': 'tutti'},
    {'id': '9', 'nome': 'Accantonamento Vacanze', 'categoria': 'Risparmio (20%)', 'sottocategoria': 'Viaggi', 'previsto': 200.00, 'tipo': 'mensile', 'frequenzaMensile': 'tutti'},
  ];

  List<Map<String, dynamic>> get vociPianificate {
    if (!isProUser) return List.unmodifiable(_vociPianificateDemo);

    final List<Map<String, dynamic>> result = [];
    final Set<String> rootIdsProcessati = {};

    for (var v in _vociPianificateReali) {
      if (v['isArchived'] == true) continue;
      final rootId = RecurrenceManager.getRootId((v['id'] ?? '').toString());

      if (rootIdsProcessati.contains(rootId)) continue;

      if (RecurrenceManager.isRicorrenzaAttiva(
          elementId: rootId,
          transactions: _transactions,
          vociReali: _vociPianificateReali,
          skippedPredictions: _skippedPredictions,
          oggi: DateTime.now())) {
        rootIdsProcessati.add(rootId);
        result.add(Map<String, dynamic>.from(v));
      }
    }

    final txsRicorrenti = _transactions.where((tx) =>
        tx.isRecurrent && !tx.isArchived && !tx.id.startsWith('rec_real_') && !tx.id.startsWith('prev_'));

    for (var tx in txsRicorrenti) {
      final rootId = RecurrenceManager.getRootId(tx.id);
      if (rootIdsProcessati.contains(rootId)) continue;

      if (RecurrenceManager.isRicorrenzaAttiva(
          elementId: rootId,
          transactions: _transactions,
          vociReali: _vociPianificateReali,
          skippedPredictions: _skippedPredictions,
          oggi: DateTime.now())) {
        rootIdsProcessati.add(rootId);
        int giornoAddebito = int.tryParse(tx.giornoRicorrenza.toString()) ?? tx.date.day;

        result.add({
          'id': tx.id,
          'nome': tx.title,
          'previsto': tx.amount,
          'tipoMovimento': tx.isIncome ? 'entrata' : 'uscita',
          'sottocategoria': tx.category,
          'categoria': tx.category,
          'frequenza': tx.frequenza ?? 'Ogni mese',
          'giornoAddebito': giornoAddebito,
          'accountId': tx.accountId,
          'dataInizio': tx.dataInizio ?? tx.date,
          'dataFineRicorrenza': tx.dataFineRicorrenza,
          'isTransaction': true,
          'isArchived': tx.isArchived,
        });
      }
    }
    return List.unmodifiable(result);
  }

  List<Map<String, dynamic>> get vociArchiviate {
    final List<Map<String, dynamic>> archiviate = [];

    for (var v in _vociPianificateReali.where((v) => v['isArchived'] == true)) {
      archiviate.add(Map<String, dynamic>.from(v));
    }

    for (var tx in _transactions.where((t) => t.isRecurrent && t.isArchived)) {
      archiviate.add({
        'id': tx.id,
        'nome': tx.title,
        'previsto': tx.amount,
        'tipoMovimento': tx.isIncome ? 'entrata' : 'uscita',
        'sottocategoria': tx.category,
        'categoria': tx.category,
        'frequenza': tx.frequenza ?? 'Ogni mese',
        'giornoAddebito': tx.giornoRicorrenza ?? tx.date.day.toString(),
        'accountId': tx.accountId,
        'dataInizio': tx.dataInizio ?? tx.date,
        'dataFineRicorrenza': tx.dataFineRicorrenza,
        'isTransaction': true,
        'isArchived': true,
      });
    }

    return List.unmodifiable(archiviate);
  }

  void aggiungiSpesaPianificata(Map<String, dynamic> voce) {
    final String rootId = (voce['id'] != null && voce['id'].toString().isNotEmpty)
        ? RecurrenceManager.getRootId(voce['id'].toString())
        : DateTime.now().millisecondsSinceEpoch.toString();

    final vocePulita = {...voce, 'id': rootId};

    final pIdx = _vociPianificateReali.indexWhere((v) =>
        RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);
    if (pIdx != -1) {
      _vociPianificateReali[pIdx] = vocePulita;
    } else {
      _vociPianificateReali.add(vocePulita);
    }

    final txIdx = _transactions.indexWhere((t) => RecurrenceManager.getRootId(t.id) == rootId);
    if (txIdx == -1) {
      final DateTime dataUso = voce['dataInizio'] != null
          ? (voce['dataInizio'] is DateTime
              ? voce['dataInizio'] as DateTime
              : DateTime.tryParse(voce['dataInizio'].toString()) ?? DateTime.now())
          : DateTime.now();

      _transactions.insert(
        0,
        TransactionModel(
          id: rootId,
          title: voce['nome'] ?? 'Spesa Pianificata',
          subtitle: '${dataUso.day}/${dataUso.month} • ${voce['categoria'] ?? 'Altro'}',
          amount: (voce['previsto'] as num?)?.toDouble() ?? 0.0,
          isIncome: voce['tipoMovimento'] == 'entrata',
          category: voce['categoria'] ?? 'Altro',
          date: dataUso,
          accountId: voce['accountId'] ?? 'main_account',
          isRecurrent: true,
          frequenza: voce['frequenza'] ?? 'Ogni mese',
          giornoRicorrenza: (voce['giornoAddebito'] ?? dataUso.day).toString(),
          dataInizio: dataUso,
          dataFineRicorrenza: voce['dataFineRicorrenza'] != null
              ? (voce['dataFineRicorrenza'] is DateTime
                  ? voce['dataFineRicorrenza'] as DateTime
                  : DateTime.tryParse(voce['dataFineRicorrenza'].toString()))
              : null,
        ),
      );
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void rimuoviSpesaPianificata(String id) => deleteTransaction(id);

  void azzeraPianificazioneSpese() {
    _vociPianificateReali.clear();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void impostaFatturatoMese(int mese, double importo, {int? anno}) {
    final int targetAnno = anno ?? DateTime.now().year;
    _pilotaggioFatturatoMesi.putIfAbsent(targetAnno, () => {});
    if (importo <= 0) {
      _pilotaggioFatturatoMesi[targetAnno]!.remove(mese);
      if (_pilotaggioFatturatoMesi[targetAnno]!.isEmpty) {
        _pilotaggioFatturatoMesi.remove(targetAnno);
      }
    } else {
      _pilotaggioFatturatoMesi[targetAnno]![mese] = importo;
    }
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void salvaRegolaBudget(double bisogni, double svago, double risparmio) {
    _percentBisogni = bisogni;
    _percentSvago = svago;
    _percentRisparmio = risparmio;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void aggiornaSpesaPianificata(String id, Map<String, dynamic> datiAggiornati) {
    final rootId = RecurrenceManager.getRootId(id);
    final idx = _vociPianificateReali.indexWhere((v) => RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);
    if (idx != -1) {
      _vociPianificateReali[idx] = {..._vociPianificateReali[idx], ...datiAggiornati};
      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fattureDaIncassare = [];
  List<Map<String, dynamic>> get fattureDaIncassare => List.unmodifiable(_fattureDaIncassare);

  List<Map<String, dynamic>> _fattureIncassate = [];
  List<Map<String, dynamic>> get fattureIncassate => List.unmodifiable(_fattureIncassate);
  List<String> _skippedPredictions = [];

  String get prossimoNumeroFattura {
    final annoCorrente = DateTime.now().year.toString();
    final tutteLeFatture = [..._fattureDaIncassare, ..._fattureIncassate];

    final fattureAnno = tutteLeFatture.where((f) {
      final dataStr = f['data'] as String? ?? '';
      return dataStr.contains(annoCorrente);
    }).toList();

    if (fattureAnno.isEmpty) return '1';

    final ultimaFattura = fattureAnno.last;
    final ultimoNumeroStr = (ultimaFattura['numero'] as String? ?? '').trim();

    if (ultimoNumeroStr.isEmpty) return '1';

    final regExp = RegExp(r'^(.*?)(\d+)(.*)$');
    final match = regExp.firstMatch(ultimoNumeroStr);

    if (match != null) {
      final prefisso = match.group(1) ?? '';
      final cifreStr = match.group(2) ?? '';
      final soffisso = match.group(3) ?? '';

      final numero = int.tryParse(cifreStr) ?? 0;
      final prossimoNumero = numero + 1;

      final cifreFormattate = prossimoNumero.toString().padLeft(cifreStr.length, '0');

      return '$prefisso$cifreFormattate$soffisso';
    }

    return '1';
  }

  WalletProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _caricaDatiDaLocalStorage();
  }

  bool _superaDataFine(DateTime dataVirtuale, DateTime? dataFine) {
    if (dataFine == null) return false;
    final dVirtuale = DateTime(dataVirtuale.year, dataVirtuale.month, dataVirtuale.day);
    final dFine = DateTime(dataFine.year, dataFine.month, dataFine.day);
    return dVirtuale.isAfter(dFine);
  }

  List<TransactionModel> getMovimentiPrevisti(DateTime meseRiferimento) {
    final previsti = <TransactionModel>[];

    final Map<String, TransactionModel> masterMap = {};
    for (var tx in _transactions.where((t) => t.isRecurrent && !t.isArchived)) {
      if (tx.id.startsWith('rec_real_') || tx.id.startsWith('prev_')) continue;

      final cleanId = RecurrenceManager.getRootId(tx.id);
      if (!masterMap.containsKey(cleanId)) {
        masterMap[cleanId] = tx;
      }
    }

    for (var tx in masterMap.values) {
      final String cleanParentId = RecurrenceManager.getRootId(tx.id);

      if (tx.frequenza != 'Ogni settimana') {
        int stepMesi = 1;
        if (tx.frequenza == 'Ogni 2 mesi') stepMesi = 2;
        else if (tx.frequenza == 'Ogni 3 mesi (Trimestrale)') stepMesi = 3;
        else if (tx.frequenza == 'Ogni 6 mesi (Semestrale)') stepMesi = 6;
        else if (tx.frequenza == 'Ogni anno (Annuale)') stepMesi = 12;

        int mesiDiff = (meseRiferimento.year - tx.date.year) * 12 + (meseRiferimento.month - tx.date.month);

        if (mesiDiff >= 0 && mesiDiff % stepMesi == 0) {
          final String keySkip = '${cleanParentId}_${meseRiferimento.year}_${meseRiferimento.month}';

          if (_skippedPredictions.contains(keySkip)) continue;

          int giornoPrevisto = int.tryParse(tx.giornoRicorrenza ?? '1') ?? tx.date.day;
          int maxGiorniMese = DateTime(meseRiferimento.year, meseRiferimento.month + 1, 0).day;
          int giornoEffettivo = giornoPrevisto > maxGiorniMese ? maxGiorniMese : giornoPrevisto;

          DateTime dataVirtuale = DateTime(meseRiferimento.year, meseRiferimento.month, giornoEffettivo);

          if (tx.dataFineRicorrenza != null) {
            final DateTime inizioMeseRiferimento = DateTime(meseRiferimento.year, meseRiferimento.month, 1);
            final DateTime inizioMeseFine = DateTime(tx.dataFineRicorrenza!.year, tx.dataFineRicorrenza!.month, 1);
            if (inizioMeseRiferimento.isAfter(inizioMeseFine)) {
              continue;
            }
          }

          if (_superaDataFine(dataVirtuale, tx.dataFineRicorrenza)) continue;

          bool isStessoMeseCreazione = dataVirtuale.year == tx.date.year && dataVirtuale.month == tx.date.month;

          final giaContabilizzato = _transactions.any((t) =>
              t.id == 'rec_real_${cleanParentId}_${dataVirtuale.year}_${dataVirtuale.month}' ||
              (!t.id.startsWith('rule_') &&
               !t.id.startsWith('prev_') &&
               t.title == tx.title &&
               t.date.year == dataVirtuale.year &&
               t.date.month == dataVirtuale.month));

          if (!isStessoMeseCreazione && !giaContabilizzato) {
            previsti.add(TransactionModel(
              id: 'prev_${cleanParentId}_${dataVirtuale.year}_${dataVirtuale.month}',
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
      }
    }

    previsti.sort((a, b) => a.date.compareTo(b.date));
    return previsti;
  }

  void sincronizzaRicorrenzeScadute() {
    final ora = DateTime.now();
    final oggi = DateTime(ora.year, ora.month, ora.day);

    final masterRicorrenti = _transactions
        .where((t) => t.isRecurrent && !t.isArchived && !t.id.startsWith('rec_real_') && !t.id.startsWith('prev_'))
        .toList();

    bool modificaEffettuata = false;

    for (var master in masterRicorrenti) {
      DateTime dataInizio = master.dataInizio ?? master.date;
      DateTime dataCorrente = DateTime(dataInizio.year, dataInizio.month, dataInizio.day);

      int stepMesi = 1;
      if (master.frequenza == 'Ogni 2 mesi') stepMesi = 2;
      else if (master.frequenza == 'Ogni 3 mesi (Trimestrale)') stepMesi = 3;
      else if (master.frequenza == 'Ogni 6 mesi (Semestrale)') stepMesi = 6;
      else if (master.frequenza == 'Ogni anno (Annuale)') stepMesi = 12;

      while (!dataCorrente.isAfter(oggi)) {
        if (_superaDataFine(dataCorrente, master.dataFineRicorrenza)) break;

        final cleanId = RecurrenceManager.getRootId(master.id);
        final keySkip = '${cleanId}_${dataCorrente.year}_${dataCorrente.month}';

        if (!_skippedPredictions.contains(keySkip)) {
          final giaRegistrato = _transactions.any((t) =>
              t.id == 'rec_real_${cleanId}_${dataCorrente.year}_${dataCorrente.month}' ||
              (t.title == master.title &&
                  t.date.year == dataCorrente.year &&
                  t.date.month == dataCorrente.month &&
                  !t.id.startsWith('rule_')));

          if (!giaRegistrato) {
            final targetAccount = _accounts.firstWhere(
              (a) => a.id == (master.accountId ?? 'main_account'),
              orElse: () => _accounts.first,
            );

            if (master.isIncome) {
              targetAccount.amount += master.amount;
            } else {
              targetAccount.amount -= master.amount;
            }

            _transactions.insert(
              0,
              TransactionModel(
                id: 'rec_real_${cleanId}_${dataCorrente.year}_${dataCorrente.month}',
                title: master.title,
                subtitle: '${dataCorrente.day}/${dataCorrente.month} • ${master.category}',
                amount: master.amount,
                isIncome: master.isIncome,
                category: master.category,
                date: dataCorrente,
                accountId: targetAccount.id,
                isRecurrent: true,
                frequenza: master.frequenza,
                giornoRicorrenza: master.giornoRicorrenza,
                dataInizio: master.dataInizio,
                dataFineRicorrenza: master.dataFineRicorrenza,
              ),
            );

            modificaEffettuata = true;
          }
        }

        dataCorrente = DateTime(dataCorrente.year, dataCorrente.month + stepMesi, dataCorrente.day);
      }
    }

    if (modificaEffettuata) {
      _aggiornaTasseVirtuali();
      _calcolaStatoCuscinetto();
      _salvaDatiInLocalStorage();
    }
  }

  void deleteAccount(String accountId) {
    final target = _accounts.firstWhere((a) => a.id == accountId, orElse: () => _accounts.first);

    final bool isProtetto = target.role == AccountRole.principal ||
        target.role == AccountRole.taxReserve ||
        target.id == 'main_account' ||
        target.id == 'tax_account' ||
        target.id == '1' ||
        target.id == '3';

    if (isProtetto) {
      throw Exception('"${target.title}" è un conto di sistema protetto e non può essere eliminato.');
    }

    if (_accounts.length <= 1) {
      throw Exception('Impossibile eliminare: deve esserci almeno un conto attivo.');
    }
    _accounts.removeWhere((a) => a.id == accountId);
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void chiudiContoGuidato({
    required String targetAccountId,
    required String? saldoDestinazioneAccountId,
    required Map<String, String> mappaNuoviContiRicorrenze,
  }) {
    final targetIndex = _accounts.indexWhere((a) => a.id == targetAccountId);
    if (targetIndex == -1) return;

    final target = _accounts[targetIndex];

    if (target.role == AccountRole.principal ||
        target.role == AccountRole.taxReserve ||
        target.id == 'main_account' ||
        target.id == 'tax_account' ||
        target.id == '1' ||
        target.id == '3') {
      throw Exception('"${target.title}" è un conto di sistema protetto e non può essere eliminato.');
    }

    if (target.amount != 0.0) {
      final double residuo = target.amount;

      if (saldoDestinazioneAccountId != null && saldoDestinazioneAccountId != 'AZZERA') {
        final contoDestinazione = _accounts.firstWhere(
          (a) => a.id == saldoDestinazioneAccountId,
          orElse: () => _accounts.first,
        );
        contoDestinazione.amount += residuo;

        _transactions.insert(
          0,
          TransactionModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Chiusura: ${target.title}',
            subtitle: 'Giroconto residuo a ${contoDestinazione.title}',
            amount: residuo.abs(),
            isIncome: residuo > 0,
            category: 'Giroconto',
            date: DateTime.now(),
            accountId: contoDestinazione.id,
          ),
        );
      } else {
        _transactions.insert(
          0,
          TransactionModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Azzeramento: ${target.title}',
            subtitle: 'Rettifica saldo pre-chiusura',
            amount: residuo.abs(),
            isIncome: false,
            category: 'Risparmi',
            date: DateTime.now(),
            accountId: target.id,
          ),
        );
      }
    }

    for (int i = 0; i < _transactions.length; i++) {
      final tx = _transactions[i];

      if (tx.accountId == targetAccountId && tx.isRecurrent) {
        final nuovaScelta = mappaNuoviContiRicorrenze[tx.id];

        if (nuovaScelta == 'ANNULLA' || nuovaScelta == null) {
          _transactions[i] = TransactionModel(
            id: tx.id,
            title: '${tx.title} [Ex ${target.title}]',
            subtitle: tx.subtitle,
            amount: tx.amount,
            isIncome: tx.isIncome,
            category: tx.category,
            date: tx.date,
            accountId: tx.accountId,
            isRecurrent: false,
          );
        } else {
          _transactions[i] = TransactionModel(
            id: tx.id,
            title: tx.title,
            subtitle: tx.subtitle,
            amount: tx.amount,
            isIncome: tx.isIncome,
            category: tx.category,
            date: tx.date,
            accountId: nuovaScelta,
            isRecurrent: true,
            frequenza: tx.frequenza,
            giornoRicorrenza: tx.giornoRicorrenza,
          );
        }
      } else if (tx.accountId == targetAccountId) {
        _transactions[i] = TransactionModel(
          id: tx.id,
          title: '${tx.title} [Ex ${target.title}]',
          subtitle: tx.subtitle,
          amount: tx.amount,
          isIncome: tx.isIncome,
          category: tx.category,
          date: tx.date,
          accountId: tx.accountId,
          isRecurrent: false,
        );
      }
    }

    _accounts.removeAt(targetIndex);

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
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

  Future<void> _caricaDatiDaLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final tierStr = prefs.getString('userTier') ?? 'free';
      _userTier = UserTier.values.firstWhere(
        (t) => t.name == tierStr,
        orElse: () => UserTier.free,
      );

      isPartitaIVA = prefs.getBool('isPartitaIVA') ?? true;
      coeffRedditivita = prefs.getDouble('coeffRedditivita') ?? 0.78;
      _coefficienteRedditivita = coeffRedditivita;

      aliquotaImposta = prefs.getDouble('aliquotaImposta') ?? 0.05;
      _aliquotaImposta = aliquotaImposta;

      aliquotaInps = prefs.getDouble('aliquotaInps') ?? 0.2607;
      _aliquotaInps = aliquotaInps;

      _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
      _haRispostoRicalibrazione = prefs.getBool('haRispostoRicalibrazione') ?? false;

      accontiVersatiAnnoPrecedente = prefs.getDouble('accontiVersatiAnnoPrecedente') ?? 0.0;
      _accontiVersati = accontiVersatiAnnoPrecedente;

      _codiceAteco = prefs.getString('codiceAteco') ?? '74.10.21';
      _nettoTargetMensile = prefs.getDouble('nettoTargetMensile') ?? 2500.0;
      _fatturatoStimatoAnnuo = prefs.getDouble('fatturatoStimatoAnnuo') ?? 35000.0;
      _mesiAttiviIncasso = prefs.getInt('mesiAttiviIncasso') ?? 10;
      final mesiStateStr = prefs.getString('mesiAttiviState');
      if (mesiStateStr != null) {
        final List decoded = jsonDecode(mesiStateStr);
        _mesiAttiviState = decoded.map((e) => e as bool).toList();
      } else {
        _mesiAttiviState = List.generate(12, (index) => index < _mesiAttiviIncasso);
      }
      _annoAperturaPiva = prefs.getInt('annoAperturaPiva') ?? 2026;
      _meseAperturaPiva = prefs.getInt('meseAperturaPiva') ?? 1;

      _entrataExtraMensile = prefs.getDouble('entrataExtraMensile') ?? 0.0;
      _numeroMensilitaExtra = prefs.getInt('numeroMensilitaExtra') ?? 13;
      _hasDipendente = prefs.getBool('hasDipendente') ?? false;
      _hasPensione = prefs.getBool('hasPensione') ?? false;

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

      final vociPianificateStr = prefs.getString('vociPianificateReali');
      if (vociPianificateStr != null) {
        final List decoded = jsonDecode(vociPianificateStr);
        _vociPianificateReali = decoded.map((v) => Map<String, dynamic>.from(v)).toList();
      }

      _percentBisogni = prefs.getDouble('percentBisogni') ?? 50.0;
      _percentSvago = prefs.getDouble('percentSvago') ?? 30.0;
      _percentRisparmio = prefs.getDouble('percentRisparmio') ?? 20.0;

      final pilotaggioStr = prefs.getString('pilotaggioFatturatoMesi');
      if (pilotaggioStr != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(pilotaggioStr);
          _pilotaggioFatturatoMesi = decoded.map((annoKey, mesiValue) {
            if (mesiValue is Map) {
              final Map<int, double> mesiDecoded = {};
              mesiValue.forEach((mKey, val) {
                mesiDecoded[int.parse(mKey.toString())] = (val as num).toDouble();
              });
              return MapEntry(int.parse(annoKey), mesiDecoded);
            }
            return MapEntry(DateTime.now().year, <int, double>{});
          });
        } catch (_) {}
      }

      final pilotaggioStipendioStr = prefs.getString('pilotaggioStipendioMesi');
      if (pilotaggioStipendioStr != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(pilotaggioStipendioStr);
          _pilotaggioStipendioMesi = decoded.map((annoKey, mesiValue) {
            if (mesiValue is Map) {
              final Map<int, double> mesiDecoded = {};
              mesiValue.forEach((mKey, val) {
                mesiDecoded[int.parse(mKey.toString())] = (val as num).toDouble();
              });
              return MapEntry(int.parse(annoKey), mesiDecoded);
            }
            return MapEntry(DateTime.now().year, <int, double>{});
          });
        } catch (_) {}
      }

      _aggiornaTasseVirtuali();
      _calcolaStatoCuscinetto();
      sincronizzaRicorrenzeScadute();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante la lettura: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _salvaDatiInLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userTier', _userTier.name);
      await prefs.setBool('isPartitaIVA', isPartitaIVA);
      await prefs.setDouble('coeffRedditivita', coeffRedditivita);
      await prefs.setDouble('aliquotaImposta', aliquotaImposta);
      await prefs.setDouble('aliquotaInps', aliquotaInps);
      await prefs.setDouble('accontiVersatiAnnoPrecedente', accontiVersatiAnnoPrecedente);

      await prefs.setDouble('textScaleFactor', _textScaleFactor);
      await prefs.setBool('haRispostoRicalibrazione', _haRispostoRicalibrazione);

      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('codiceAteco', _codiceAteco);
      await prefs.setDouble('nettoTargetMensile', _nettoTargetMensile);
      await prefs.setDouble('fatturatoStimatoAnnuo', _fatturatoStimatoAnnuo);
      await prefs.setInt('mesiAttiviIncasso', _mesiAttiviIncasso);
      await prefs.setString('mesiAttiviState', jsonEncode(_mesiAttiviState));
      if (_annoAperturaPiva != null) {
        await prefs.setInt('annoAperturaPiva', _annoAperturaPiva!);
      }
      if (_meseAperturaPiva != null) {
        await prefs.setInt('meseAperturaPiva', _meseAperturaPiva!);
      }

      await prefs.setDouble('entrataExtraMensile', _entrataExtraMensile);
      await prefs.setInt('numeroMensilitaExtra', _numeroMensilitaExtra);
      await prefs.setBool('hasDipendente', _hasDipendente);
      await prefs.setBool('hasPensione', _hasPensione);

      await prefs.setDouble('fatturatoTotale', _fatturatoTotale);

      await prefs.setString('accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
      await prefs.setString('transactions', jsonEncode(_transactions.map((t) => t.toJson()).toList()));
      await prefs.setString('fattureDaIncassare', jsonEncode(_fattureDaIncassare));
      await prefs.setString('fattureIncassate', jsonEncode(_fattureIncassate));
      await prefs.setString('skippedPredictions', jsonEncode(_skippedPredictions));
      await prefs.setString('vociPianificateReali', jsonEncode(_vociPianificateReali));

      await prefs.setDouble('percentBisogni', _percentBisogni);
      await prefs.setDouble('percentSvago', _percentSvago);
      await prefs.setDouble('percentRisparmio', _percentRisparmio);
      await prefs.setString(
        'pilotaggioFatturatoMesi',
        jsonEncode(
          _pilotaggioFatturatoMesi.map((annoKey, mesiMap) => MapEntry(
                annoKey.toString(),
                mesiMap.map((mKey, val) => MapEntry(mKey.toString(), val)),
              )),
        ),
      );
      await prefs.setString(
        'pilotaggioStipendioMesi',
        jsonEncode(
          _pilotaggioStipendioMesi.map((annoKey, mesiMap) => MapEntry(
                annoKey.toString(),
                mesiMap.map((mKey, val) => MapEntry(mKey.toString(), val)),
              )),
        ),
      );

      await _salvaDatiSuCloud();
    } catch (e) {
      debugPrint('Errore durante il salvataggio: $e');
    }
  }

  Future<void> _salvaDatiSuCloud() async {
    if (_userId == null) return;
    try {
      await _firestore.collection('utenti').doc(_userId).set({
        'userTier': _userTier.name,
        'isPartitaIVA': isPartitaIVA,
        'coeffRedditivita': coeffRedditivita,
        'aliquotaImposta': aliquotaImposta,
        'aliquotaInps': aliquotaInps,
        'accontiVersatiAnnoPrecedente': accontiVersatiAnnoPrecedente,
        'codiceAteco': _codiceAteco,
        'nettoTargetMensile': _nettoTargetMensile,
        'fatturatoStimatoAnnuo': _fatturatoStimatoAnnuo,
        'mesiAttiviIncasso': _mesiAttiviIncasso,
        'annoAperturaPiva': _annoAperturaPiva,
        'meseAperturaPiva': _meseAperturaPiva,
        'entrataExtraMensile': _entrataExtraMensile,
        'numeroMensilitaExtra': _numeroMensilitaExtra,
        'hasDipendente': _hasDipendente,
        'hasPensione': _hasPensione,
        'fatturatoTotale': _fatturatoTotale,
        'accounts': _accounts.map((a) => a.toJson()).toList(),
        'transactions': _transactions.map((t) => t.toJson()).toList(),
        'fattureDaIncassare': _fattureDaIncassare,
        'fattureIncassate': _fattureIncassate,
        'vociPianificate': _vociPianificateReali,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Errore salvataggio Cloud: $e');
    }
  }

  double get totaleTasseDovute {
    return fattureIncassateAnnoCorrente.fold(
      0.0,
      (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double get totaleTasseDovuteAnnoCorrenteReale {
    final int annoReale = DateTime.now().year;
    return _fattureIncassate.where((f) {
      final dataIncasso = f['dataIncasso'] as String? ?? f['data'] as String? ?? '';
      return _estraiAnnoDaData(dataIncasso) == annoReale;
    }).fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
  }

  double get saldoSalvadanaioTasse {
    final salvadanaio = _accounts.firstWhere(
      (a) => a.role == AccountRole.taxReserve || a.id == 'tax_account' || a.id == '3',
      orElse: () => _accounts.last,
    );
    return salvadanaio.amount;
  }

  double get tasseScoperteContoPrincipale {
    final scoperte = totaleTasseDovuteAnnoCorrenteReale - saldoSalvadanaioTasse;
    return scoperte > 0 ? scoperte : 0.0;
  }

  void _aggiornaTasseVirtuali() {
    for (var account in _accounts) {
      account.virtualTaxAmount = 0.0;
    }

    final contoPrincipale = _accounts.firstWhere(
      (a) => a.role == AccountRole.principal || a.id == 'main_account' || a.id == '1',
      orElse: () => _accounts.first,
    );

    contoPrincipale.virtualTaxAmount = tasseScoperteContoPrincipale;
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
    DateTime? dataInizio,
    DateTime? dataFineRicorrenza,
    String? customId,
  }) {
    final DateTime dataUso = date ?? DateTime.now();

    final targetAccount = _accounts.firstWhere(
      (acc) => acc.id == (accountId ?? 'main_account'),
      orElse: () => _accounts.first,
    );

    final newTx = TransactionModel(
      id: customId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
      dataInizio: dataInizio ?? (isRecurrent ? dataUso : null),
      dataFineRicorrenza: dataFineRicorrenza,
    );

    _transactions.insert(0, newTx);

    if (isIncome) {
      targetAccount.amount += amount;
    } else {
      targetAccount.amount -= amount;
    }

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    sincronizzaRicorrenzeScadute();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void addFatturaPiva({
    required String cliente,
    required double importo,
    String? data,
    String? numero,
    double? coefAteco,
    double? importoTasseStimate,
    bool inviaSdi = false,
    String? pivaCliente,
    String? codiceSdiPec,
    String? descrizione,
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
      'coefAteco': coefAteco ?? coeffRedditivita,
      'importoTasseStimate': importoTasseStimate ?? (importo * aliquotaFiscaleReale),
      'inviaSdi': inviaSdi,
      'pivaCliente': pivaCliente ?? '',
      'codiceSdiPec': codiceSdiPec ?? '',
      'descrizione': descrizione ?? '',
      'statoSdi': inviaSdi ? 'in_coda' : 'bozza_interna',
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

    final DateTime ora = DateTime.now();
    final String dataOggiFormattata = '${ora.day.toString().padLeft(2, '0')}/${ora.month.toString().padLeft(2, '0')}/${ora.year}';
    final String dataFinale = (dataIncasso == null || dataIncasso.toLowerCase() == 'oggi' || dataIncasso.isEmpty)
        ? dataOggiFormattata
        : dataIncasso;

    DateTime dataObj = DateTime.now();
    try {
      final strPulita = dataFinale.trim().split(' ').first;
      if (strPulita.contains('/')) {
        final parts = strPulita.split('/');
        if (parts.length == 3) {
          dataObj = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (strPulita.contains('-')) {
        final parts = strPulita.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            dataObj = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else {
            dataObj = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      }
    } catch (_) {}

    if (idFattura != null) {
      final idx = _fattureDaIncassare.indexWhere((f) => f['id'] == idFattura);
      if (idx != -1) {
        final f = _fattureDaIncassare.removeAt(idx);
        _fattureIncassate.add({
          ...f,
          'dataIncasso': dataFinale,
          'importoTasse': importoTasse > 0 ? importoTasse : (importoLordo * aliquotaFiscaleReale),
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
      date: dataObj,
    );

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
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

      final contoPrincipale = _accounts.firstWhere(
        (a) => a.role == AccountRole.principal || a.id == 'main_account' || a.id == '1',
        orElse: () => _accounts.first,
      );

      final targetAccount = (contoAccredito != null)
          ? _accounts.firstWhere(
              (acc) => acc.title.contains(contoAccredito) || contoAccredito.contains(acc.title),
              orElse: () => contoPrincipale,
            )
          : contoPrincipale;

      targetAccount.amount -= importoLordo;

      _transactions.removeWhere((t) => t.title.contains(cliente));

      _aggiornaTasseVirtuali();
      _calcolaStatoCuscinetto();
    } else {
      _fattureDaIncassare.removeWhere((f) => f['id'] == idFattura);
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void archiviaRicorrenza(String id) {
    final rootId = RecurrenceManager.getRootId(id);

    final idx = _transactions.indexWhere((t) => RecurrenceManager.getRootId(t.id) == rootId);
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
        isRecurrent: true,
        frequenza: tx.frequenza,
        giornoRicorrenza: tx.giornoRicorrenza,
        dataInizio: tx.dataInizio,
        dataFineRicorrenza: tx.dataFineRicorrenza,
        isArchived: true,
      );
    }

    final pIdx = _vociPianificateReali.indexWhere((v) => RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);
    if (pIdx != -1) {
      _vociPianificateReali[pIdx]['isArchived'] = true;
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void ripristinaRicorrenzaArchiviata(String id, {double? nuovoImporto, DateTime? nuovaDataInizio, DateTime? nuovaDataFine}) {
    final rootId = RecurrenceManager.getRootId(id);

    final idx = _transactions.indexWhere((t) => RecurrenceManager.getRootId(t.id) == rootId);
    if (idx != -1) {
      final tx = _transactions[idx];
      _transactions[idx] = TransactionModel(
        id: tx.id,
        title: tx.title,
        subtitle: tx.subtitle,
        amount: nuovoImporto ?? tx.amount,
        isIncome: tx.isIncome,
        category: tx.category,
        date: nuovaDataInizio ?? tx.date,
        accountId: tx.accountId,
        isRecurrent: true,
        frequenza: tx.frequenza,
        giornoRicorrenza: tx.giornoRicorrenza,
        dataInizio: nuovaDataInizio ?? tx.dataInizio,
        dataFineRicorrenza: nuovaDataFine,
        isArchived: false,
      );
    }

    final pIdx = _vociPianificateReali.indexWhere((v) => RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);
    if (pIdx != -1) {
      _vociPianificateReali[pIdx]['isArchived'] = false;
      if (nuovoImporto != null) _vociPianificateReali[pIdx]['previsto'] = nuovoImporto;
      if (nuovaDataInizio != null) _vociPianificateReali[pIdx]['dataInizio'] = nuovaDataInizio.toIso8601String();
      if (nuovaDataFine != null) _vociPianificateReali[pIdx]['dataFineRicorrenza'] = nuovaDataFine.toIso8601String();
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void eliminaRegolaRicorrenteDefinitivamente(String id) {
    final String rootId = RecurrenceManager.getRootId(id);

    _vociPianificateReali.removeWhere((v) =>
        RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);

    for (int i = 0; i < _transactions.length; i++) {
      if (RecurrenceManager.getRootId(_transactions[i].id) == rootId) {
        final tx = _transactions[i];

        if (tx.id.startsWith('rule_')) {
          _transactions.removeAt(i);
          i--;
          continue;
        }

        _transactions[i] = TransactionModel(
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
          dataInizio: null,
          dataFineRicorrenza: null,
          isArchived: false,
        );
      }
    }

    _skippedPredictions.removeWhere((k) => k.startsWith(rootId));

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    final String rootId = RecurrenceManager.getRootId(id);

    if (id.startsWith('rec_real_') || id.startsWith('prev_')) {
      final parts = id.split('_');
      if (parts.length >= 4) {
        final month = parts.last;
        final year = parts[parts.length - 2];

        final keySkip = '${rootId}_${year}_${month}';
        if (!_skippedPredictions.contains(keySkip)) {
          _skippedPredictions.add(keySkip);
        }
      }

      final idx = _transactions.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _stornaSaldoConto(_transactions[idx]);
        _transactions.removeAt(idx);
      }
    } else {
      final txSingolaIdx = _transactions.indexWhere((t) => t.id == id && !t.isRecurrent);

      if (txSingolaIdx != -1) {
        _stornaSaldoConto(_transactions[txSingolaIdx]);
        _transactions.removeAt(txSingolaIdx);
      } else {
        _vociPianificateReali.removeWhere((v) =>
            RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);

        for (int i = _transactions.length - 1; i >= 0; i--) {
          final tx = _transactions[i];
          if (tx.id == id || tx.id == rootId || tx.id == 'rule_$rootId' || RecurrenceManager.getRootId(tx.id) == rootId) {
            _stornaSaldoConto(tx);
            _transactions.removeAt(i);
          }
        }

        _skippedPredictions.removeWhere((k) => k.startsWith(rootId));
      }
    }

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void eliminaSoloQuestoMese(String id, DateTime dataRata) {
    final String rootId = RecurrenceManager.getRootId(id);
    final String keySkip = '${rootId}_${dataRata.year}_${dataRata.month}';

    if (!_skippedPredictions.contains(keySkip)) {
      _skippedPredictions.add(keySkip);
    }

    if (id.startsWith('rec_real_')) {
      final idx = _transactions.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _stornaSaldoConto(_transactions[idx]);
        _transactions.removeAt(idx);
      }
    } else if (id == rootId) {
      final idx = _transactions.indexWhere((t) => t.id == rootId);
      if (idx != -1) {
        final tx = _transactions[idx];
        _stornaSaldoConto(tx);
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
          dataInizio: tx.dataInizio,
          dataFineRicorrenza: tx.dataFineRicorrenza,
        );
      }
    }

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void eliminaQuestoEFuturi(String id, DateTime dataRata) {
    final String rootId = RecurrenceManager.getRootId(id);

    stopRecurrenceFromDate(rootId, dataRata);

    if (id.startsWith('rec_real_')) {
      final idx = _transactions.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _stornaSaldoConto(_transactions[idx]);
        _transactions.removeAt(idx);
      }
    } else if (id == rootId) {
      final idx = _transactions.indexWhere((t) => t.id == rootId);
      if (idx != -1) {
        final tx = _transactions[idx];
        _stornaSaldoConto(tx);
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
          dataInizio: tx.dataInizio,
          dataFineRicorrenza: tx.dataFineRicorrenza,
        );
      }
    }

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void eliminaInteraSerie(String id) {
    deleteTransaction(RecurrenceManager.getRootId(id));
  }

  void _stornaSaldoConto(TransactionModel tx) {
    if (tx.id.startsWith('rule_') || tx.id.startsWith('prev_')) return;
    if (tx.accountId == null || tx.accountId!.isEmpty) return;

    final accIdx = _accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIdx != -1) {
      if (tx.isIncome) {
        _accounts[accIdx].amount -= tx.amount;
      } else {
        _accounts[accIdx].amount += tx.amount;
      }
    }
  }

  void stopRecurrence(String id) {
    final rootId = RecurrenceManager.getRootId(id);
    final idx = _transactions.indexWhere((t) => RecurrenceManager.getRootId(t.id) == rootId && !t.id.startsWith('rec_real_'));

    if (idx != -1) {
      final tx = _transactions[idx];
      final dataFine = DateTime.now().subtract(const Duration(days: 1));

      _transactions[idx] = TransactionModel(
        id: tx.id,
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
        dataInizio: tx.dataInizio,
        dataFineRicorrenza: dataFine,
        isArchived: tx.isArchived,
      );

      final pIdx = _vociPianificateReali.indexWhere((v) => RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);
      if (pIdx != -1) {
        _vociPianificateReali[pIdx]['dataFineRicorrenza'] = dataFine.toIso8601String();
      }

      _salvaDatiInLocalStorage();
      notifyListeners();
    }
  }

  void stopRecurrenceFromDate(String id, DateTime limiteData) {
    final rootId = RecurrenceManager.getRootId(id);

    final DateTime dataFine = limiteData.day > 1
        ? limiteData
        : DateTime(limiteData.year, limiteData.month + 1, 0, 23, 59, 59);

    final idx = _transactions.indexWhere((t) => RecurrenceManager.getRootId(t.id) == rootId && !t.id.startsWith('rec_real_'));
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
        isRecurrent: true,
        frequenza: tx.frequenza,
        giornoRicorrenza: tx.giornoRicorrenza,
        dataInizio: tx.dataInizio,
        dataFineRicorrenza: dataFine,
        isArchived: tx.isArchived,
      );
    }

    final pIdx = _vociPianificateReali.indexWhere((v) => RecurrenceManager.getRootId((v['id'] ?? '').toString()) == rootId);
    if (pIdx != -1) {
      _vociPianificateReali[pIdx]['dataFineRicorrenza'] = dataFine.toIso8601String();
    }

    final movimentiDaStornare = _transactions.where((t) {
      final bool eDellaSerie = RecurrenceManager.getRootId(t.id) == rootId;
      final bool eSuccessivo = t.date.isAfter(dataFine);
      return eDellaSerie && eSuccessivo;
    }).toList();

    for (var tx in movimentiDaStornare) {
      _stornaSaldoConto(tx);
      _transactions.removeWhere((t) => t.id == tx.id);
    }

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
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

      _stornaSaldoConto(tx);

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
        dataFineRicorrenza: tx.dataFineRicorrenza,
      );

      _aggiornaTasseVirtuali();
      _calcolaStatoCuscinetto();
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

    if (initialAmount > 0) {
      _transactions.insert(
        0,
        TransactionModel(
          id: '${newId}_init',
          title: 'Saldo Iniziale: $title',
          subtitle: 'Apertura conto',
          amount: initialAmount,
          isIncome: true,
          category: 'Risparmi',
          date: DateTime.now(),
          accountId: newId,
        ),
      );
    }

    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  Future<void> resetTuttiIDati() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _accounts = [
      AccountModel(
        id: 'main_account',
        title: 'Conto Principale (IBAN)',
        subtitle: 'Conto Operativo',
        amount: 0.00,
        color: const Color(0xFF2DD4BF),
        role: AccountRole.principal,
      ),
      AccountModel(
        id: 'tax_account',
        title: 'Salvadanaio Tasse',
        subtitle: 'Obiettivo Riserva',
        amount: 0.00,
        color: const Color(0xFF3B82F6),
        role: AccountRole.taxReserve,
      ),
      AccountModel(
        id: 'savings_account',
        title: 'Fondo Risparmio',
        subtitle: 'Riserva Liquidità',
        amount: 0.00,
        color: const Color(0xFFF59E0B),
        role: AccountRole.standard,
      ),
    ];

    isPartitaIVA = true;
    _fatturatoTotale = 0.00;
    _transactions.clear();
    _fattureDaIncassare.clear();
    _fattureIncassate.clear();
    _vociPianificateReali.clear();

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    notifyListeners();
  }

  void updateAccountDetails({
    required String accountId,
    required String newTitle,
    required double newAmount,
  }) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      final oldTitle = _accounts[idx].title;
      _accounts[idx].title = newTitle;
      _accounts[idx].amount = newAmount;

      for (int i = 0; i < _transactions.length; i++) {
        final tx = _transactions[i];
        if (tx.title.contains(oldTitle) && tx.category == 'Giroconto') {
          _transactions[i] = TransactionModel(
            id: tx.id,
            title: tx.title.replaceAll(oldTitle, newTitle),
            subtitle: tx.subtitle,
            amount: tx.amount,
            isIncome: tx.isIncome,
            category: tx.category,
            date: tx.date,
            accountId: tx.accountId,
            isRecurrent: tx.isRecurrent,
            frequenza: tx.frequenza,
            giornoRicorrenza: tx.giornoRicorrenza,
          );
        }
      }

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
    required int annoRiferimentoTasse,
  }) {
    final targetAccount = _accounts.firstWhere((acc) => acc.id == accountId, orElse: () => _accounts.first);

    targetAccount.amount -= importoF24;

    if (annoRiferimentoTasse == _annoFiscaleCorrente - 1) {
      accontiVersatiAnnoPrecedente += importoF24;
      _accontiVersati += importoF24;
    }

    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Pagamento F24 (Anno $annoRiferimentoTasse)',
      subtitle: 'Liquidazione / Acconti Tasse',
      amount: importoF24,
      isIncome: false,
      category: 'Imposte & F24',
      date: data,
      accountId: targetAccount.id,
    );

    _transactions.insert(0, newTx);

    _aggiornaTasseVirtuali();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void eseguiGiroconto({
    required String daAccountId,
    required String aAccountId,
    required double importo,
    required bool isAccantonamentoTasse,
    DateTime? date,
  }) {
    final accDa = _accounts.firstWhere((a) => a.id == daAccountId);
    final accA = _accounts.firstWhere((a) => a.id == aAccountId);

    if (importo <= 0 || accDa.amount < importo) return;

    final bool eVersamentoTasse = accA.role == AccountRole.taxReserve || isAccantonamentoTasse;
    final bool ePrelievoTasse = accDa.role == AccountRole.taxReserve;

    String titoloDa = 'Giroconto verso ${accA.title}';
    String titoloA = 'Giroconto da ${accDa.title}';

    if (eVersamentoTasse) {
      titoloDa = 'Accantonamento Tasse 🛡️';
      titoloA = 'Ricezione Riserva Tasse 🛡️';
    } else if (ePrelievoTasse) {
      titoloDa = 'Prelievo da Riserva Tasse ⚠️';
      titoloA = 'Rientro Liquidità da Tasse ⚠️';
    }

    final String baseId = DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime dataFinale = date ?? DateTime.now();

    addTransaction(
      customId: '${baseId}_da',
      title: titoloDa,
      amount: importo,
      isIncome: false,
      category: 'Giroconto',
      accountId: accDa.id,
      date: dataFinale,
    );

    addTransaction(
      customId: '${baseId}_verso',
      title: titoloA,
      amount: importo,
      isIncome: true,
      category: 'Giroconto',
      accountId: accA.id,
      date: dataFinale,
    );

    _aggiornaTasseVirtuali();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void salvaProfiloFiscale({
    required String codiceAteco,
    required double coeffRedditivitaVal,
    required double aliquotaImpostaVal,
    double accontiVersati = 0.0,
    double nettoTarget = 2000.0,
    double fatturatoStimato = 35000.0,
    int mesiAttivi = 12,
    List<bool>? mesiAttiviStateCustom,
    int? annoAperturaPiva,
    int? meseAperturaPiva,
  }) {
    _codiceAteco = codiceAteco;
    _coefficienteRedditivita = coeffRedditivitaVal;
    coeffRedditivita = coeffRedditivitaVal;

    _aliquotaImposta = aliquotaImpostaVal;
    aliquotaImposta = aliquotaImpostaVal;
    _isStartup = (aliquotaImpostaVal == 0.05);

    accontiVersatiAnnoPrecedente = accontiVersati;
    _accontiVersati = accontiVersati;

    _nettoTargetMensile = nettoTarget;
    _fatturatoStimatoAnnuo = fatturatoStimato;
    _mesiAttiviIncasso = mesiAttivi;

    if (mesiAttiviStateCustom != null && mesiAttiviStateCustom.length == 12) {
      _mesiAttiviState = List.from(mesiAttiviStateCustom);
    } else if (_mesiAttiviState.where((m) => m).length != mesiAttivi) {
      _mesiAttiviState = List.generate(12, (index) => index < mesiAttivi);
    }

    if (annoAperturaPiva != null) _annoAperturaPiva = annoAperturaPiva;
    if (meseAperturaPiva != null) _meseAperturaPiva = meseAperturaPiva;

    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void aggiornaProfiloFiscale({
    required String nuovoAteco,
    required double nuovoCoeff,
    required double nuovaImposta,
    bool ricalcolaFattureAnnoCorrente = false,
  }) {
    salvaProfiloFiscale(
      codiceAteco: nuovoAteco,
      coeffRedditivitaVal: nuovoCoeff,
      aliquotaImpostaVal: nuovaImposta,
      accontiVersati: _accontiVersati,
      nettoTarget: _nettoTargetMensile,
      fatturatoStimato: _fatturatoStimatoAnnuo,
      mesiAttivi: _mesiAttiviIncasso,
      annoAperturaPiva: _annoAperturaPiva,
      meseAperturaPiva: _meseAperturaPiva,
    );
  }

  Future<void> resetSoloMovimentieFatture() async {
    _accounts = [
      AccountModel(
        id: 'main_account',
        title: 'Conto Principale (IBAN)',
        subtitle: 'Conto Operativo',
        amount: 0.00,
        color: const Color(0xFF2DD4BF),
        role: AccountRole.principal,
      ),
      AccountModel(
        id: 'tax_account',
        title: 'Salvadanaio Tasse',
        subtitle: 'Obiettivo Riserva',
        amount: 0.00,
        color: const Color(0xFF3B82F6),
        role: AccountRole.taxReserve,
      ),
      AccountModel(
        id: 'savings_account',
        title: 'Fondo Risparmio',
        subtitle: 'Riserva Liquidità',
        amount: 0.00,
        color: const Color(0xFFF59E0B),
        role: AccountRole.standard,
      ),
    ];

    _fatturatoTotale = 0.00;
    _haRispostoRicalibrazione = false;

    _mesiAttiviState = [true, true, true, true, true, true, true, false, true, true, false, false];
    _mesiAttiviIncasso = 9;

    _transactions.clear();
    _fattureDaIncassare.clear();
    _fattureIncassate.clear();

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    await _salvaDatiInLocalStorage();
    notifyListeners();
  }

  final Set<String> _dismissedTipKeys = {};
  Set<String> get dismissedTipKeys => _dismissedTipKeys;

  void dismissAdvisorTip(String key) {
    _dismissedTipKeys.add(key);
    notifyListeners();
  }
}