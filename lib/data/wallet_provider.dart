import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    } else if (id == '3' || id == 'tax_account' || title.contains('salvadanaio tasse') || title.contains('acconto tasse')) {
      roleAssegnato = AccountRole.taxReserve;
    }

    return AccountModel(
      id: id,
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
  final DateTime? dataFineRicorrenza;

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
    this.dataFineRicorrenza,
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
        'dataFineRicorrenza': dataFineRicorrenza?.toIso8601String(),
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
        dataFineRicorrenza: json['dataFineRicorrenza'] != null 
            ? DateTime.parse(json['dataFineRicorrenza'] as String) 
            : null,
      );
}

class WalletProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  final Map<String, String> _mappaSottocategoriaABussola = {
    'Casa/Affitto': 'Bisogni',
    'Mutuo': 'Bisogni',
    'Canoni/Bollette': 'Bisogni',
    'Supermercato': 'Bisogni',
    'Auto': 'Bisogni',
    'Salute & Benessere': 'Bisogni',
    'Alimentari': 'Bisogni',
    'Ristoranti & Bar': 'Svago',
    'Divertimento': 'Svago',
    'Acquisti': 'Svago',
    'Viaggi': 'Svago',
    'Altro': 'Svago',
  };

  List<AccountModel> _accounts = [
    AccountModel(id: 'main_account', title: 'Conto Principale (IBAN)', subtitle: 'Conto Operativo', amount: 0.00, color: const Color(0xFF2DD4BF), role: AccountRole.principal),
    AccountModel(id: 'tax_account', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6), role: AccountRole.taxReserve),
    AccountModel(id: 'savings_account', title: 'Fondo Risparmio', subtitle: 'Riserva Liquidità', amount: 0.00, color: const Color(0xFFF59E0B), role: AccountRole.standard),
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

  void toggleProUser() {
    cycleUserTier(); 
  }

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

  bool _ralSupera30k = false;
  bool _scontoInps35 = false;
  bool _isPrimoAnnoAssoluto = false;

  double accontiVersatiAnnoPrecedente = 0.0;
  double _accontiVersati = 0.0;
  double get accontiVersati => _accontiVersati;

  double _contributiInpsPagatiAnnoCorrente = 0.0;

  double _nettoTargetMensile = 2500.0;
  double _speseFisseMensili = 800.0;

  double _fatturatoStimatoAnnuo = 35000.0;
  double get fatturatoStimato => _fatturatoStimatoAnnuo;

  int _mesiAttiviIncasso = 10;
  int get mesiAttivi => _mesiAttiviIncasso;
  double get nettoTargetMensile => _nettoTargetMensile;

  // 🏖️ STATO MESI ATTIVI (12 MESI: true = Lavoro, false = Pausa)
  List<bool> _mesiAttiviState = List.generate(12, (index) => index < 10);
  List<bool> get mesiAttiviState => List.unmodifiable(_mesiAttiviState);

  // 🛡️ STATO CUSCINETTO MESI OFF
  double _cuscinettoAccumulato = 0.0;
  double _cuscinettoUtilizzato = 0.0;
  double get cuscinettoAccumulato => _cuscinettoAccumulato;
  double get cuscinettoUtilizzato => _cuscinettoUtilizzato;
  double get cuscinettoResiduo => (_cuscinettoAccumulato - _cuscinettoUtilizzato).clamp(0.0, double.infinity);

  int? _annoAperturaPiva = 2026;
  int? get annoAperturaPiva => _annoAperturaPiva;

  int? _meseAperturaPiva = 1;
  int? get meseAperturaPiva => _meseAperturaPiva;

  // 🎯 ENTRATE EXTRA DA ONBOARDING (DIPENDENTE / PENSIONE)
  double _entrataExtraMensile = 0.0;
  double get entrataExtraMensile => _entrataExtraMensile;

  int _numeroMensilitaExtra = 13; // 12, 13 o 14 mensilità
  int get numeroMensilitaExtra => _numeroMensilitaExtra;

  bool _hasDipendente = false;
  bool get hasDipendente => _hasDipendente;

  bool _hasPensione = false;
  bool get hasPensione => _hasPensione;
  // 💡 VERSION 1.1: CONTROLLO ISOLATO ACCREDITO STIPENDIO / PENSIONE
  bool get haInseritoStipendioMeseCorrente {
    final ora = DateTime.now();
    return _transactions.any((tx) {
      if (!tx.isIncome) return false;
      if (tx.date.year != ora.year || tx.date.month != ora.month) return false;

      final catLower = tx.category.toLowerCase();
      final titleLower = tx.title.toLowerCase();

      // 🛡️ Escludiamo fatture P.IVA, incassi generici e giroconti
      final bool isPivaOIncasso = tx.category == 'P.IVA' || 
                                  titleLower.startsWith('incasso') || 
                                  titleLower.startsWith('fattura');
      if (isPivaOIncasso || tx.category == 'Giroconto') return false;

      // 🎯 Il banner scompare SOLO se è stato registrato espressamente lo Stipendio o la Pensione
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

  // 💡 VERSION 1.1: METODO DI ACCREDITO RAPIDO STIPENDIO / PENSIONE
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

  // 🎯 METODI DEDICATI PER IL SALVATAGGIO DALL'ONBOARDING WIZARD
  void salvaContiIniziali(List<AccountModel> nuoviConti) {
    _accounts = List.from(nuoviConti);

    // 🛡️ Rimuove eventuali saldi iniziali precedenti per evitare duplicati se l'utente rifà l'onboarding
    _transactions.removeWhere((t) => t.id.contains('_init_'));

    // 🎯 Crea un movimento "Saldo Iniziale" per giustificare i fondi inseriti nell'Onboarding
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

  // 🎯 CALCOLA DINAMICAMENTE L'ACCUMULO E L'UTILIZZO DEL CUSCINETTO MESI OFF
  void _calcolaStatoCuscinetto() {
    if (!isPartitaIVA || _mesiAttiviIncasso == 12) {
      _cuscinettoAccumulato = 0.0;
      _cuscinettoUtilizzato = 0.0;
      return;
    }

    // 🛡️ AUTO-CORREZIONE: Se la matrice dei mesi non coincide con _mesiAttiviIncasso, la riallinea
    if (_mesiAttiviState.where((m) => m).length != _mesiAttiviIncasso) {
      _mesiAttiviState = List.generate(12, (index) => index < _mesiAttiviIncasso);
    }

    final int annoCorrente = DateTime.now().year;
    final int meseCorrenteIndex = DateTime.now().month - 1; // 0 = Gen, 7 = Ago...

    double totaleAccumulato = 0.0;
    double totaleUtilizzato = 0.0;

    // 1. ACCUMULO REALE: Quota trattenuta dagli incassi P.IVA fino al mese corrente
    for (var tx in _transactions) {
      if (tx.isIncome && tx.date.year == annoCorrente && tx.date.month <= DateTime.now().month) {
        if (tx.category == 'P.IVA' || tx.title.toLowerCase().contains('incasso')) {
          final double nettoPiva = tx.amount * (1 - aliquotaFiscaleReale);
          final double percentualeAccantonamento = (12 - _mesiAttiviIncasso) / 12;
          totaleAccumulato += (nettoPiva * percentualeAccantonamento);
        }
      }
    }

    // 2. UTILIZZO REALE: Quota erogata nei mesi OFF passati e in quello attuale
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

  // 🔄 AGGIORNA LA MATRICE DEI MESI ATTIVI (DA ONBOARDING O IMPOSTAZIONI)
  void setMesiAttiviState(List<bool> newState) {
    _mesiAttiviState = List.from(newState);
    _mesiAttiviIncasso = newState.where((m) => m).length;
    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }
  
  // ===========================================================================
  // 🔮 MOTORE PROIETTIVO: STIME E RICALIBRAZIONE
  // ===========================================================================

  bool _haRispostoRicalibrazione = false;
  bool get haRispostoRicalibrazione => _haRispostoRicalibrazione;

  void impostaRispostaRicalibrazione(bool valore) {
    _haRispostoRicalibrazione = valore;
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  /// Restituisce lo stato del ritmo di fatturato: 'in_linea', 'over', 'under'
  String get statoRitmoFatturato {
    if (!isPartitaIVA || _fatturatoStimatoAnnuo <= 0) return 'in_linea';

    final int meseCorrente = DateTime.now().month;
    // Calcoliamo quanti mesi lavorativi sono passati fino ad oggi
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

    final double scostamento = (_fatturatoTotale - targetAdOggi) / targetAdOggi;

    if (scostamento > 0.15) return 'over';   // +15% di deviazione
    if (scostamento < -0.15) return 'under'; // -15% di deviazione
    return 'in_linea';
  }

  /// Calcola l'entrata prevista per un MESE FUTURO
  double getEntrataPrevistaMeseFuturo(DateTime meseFuturo) {
    double stimaEntrata = 0.0;

    // 1. Dipendente / Pensione (Gestione precisa 12, 13 o 14 mensilità)
    if (_entrataExtraMensile > 0) {
      bool isDoppiaMensilita = false;
      if (_numeroMensilitaExtra == 13 && meseFuturo.month == 12) {
        isDoppiaMensilita = true; // 13esima a Dicembre
      } else if (_numeroMensilitaExtra == 14 && (meseFuturo.month == 6 || meseFuturo.month == 12)) {
        isDoppiaMensilita = true; // 14esima a Giugno, 13esima a Dicembre
      }
      stimaEntrata += isDoppiaMensilita ? (_entrataExtraMensile * 2) : _entrataExtraMensile;
    }

    // 2. Stima P.IVA (solo nei Mesi ON di lavoro)
    if (isPartitaIVA) {
      final int indexMeseFuturo = meseFuturo.month - 1;
      final bool isMeseLavorativo = _mesiAttiviState.length > indexMeseFuturo 
          ? _mesiAttiviState[indexMeseFuturo] 
          : true;

      if (isMeseLavorativo) {
        final int meseCorrente = DateTime.now().month; // Agosto = 8
        int mesiLavorativiRimanenti = 0;
        
        // Conta tutti i mesi ON da Settembre (indice 8) a Dicembre (indice 11)
        for (int i = meseCorrente; i < 12; i++) {
          if (_mesiAttiviState.length > i && _mesiAttiviState[i]) {
            mesiLavorativiRimanenti++;
          }
        }

        final double fatturatoResiduo = (_fatturatoStimatoAnnuo - _fatturatoTotale).clamp(0.0, double.infinity);

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

    if (testoCompleto.contains('20%') ||
        testoCompleto.contains('risparm') ||
        testoCompleto.contains('invest')) {
      return 'Risparmi';
    }

    if (testoCompleto.contains('30%') ||
        testoCompleto.contains('svag') ||
        testoCompleto.contains('variabil') ||
        testoCompleto.contains('ristorant') ||
        testoCompleto.contains('trattoria') ||
        testoCompleto.contains('pizzeria') ||
        testoCompleto.contains('pub') ||
        testoCompleto.contains('bar') ||
        testoCompleto.contains('divertiment') ||
        testoCompleto.contains('acquisti') ||
        testoCompleto.contains('viaggi')) {
      return 'Svago';
    }

    return 'Bisogni';
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
  double get fatturatoTotale => _fatturatoTotale;

  double get stimaTasseAccantonate => _fatturatoTotale * aliquotaFiscaleReale;
  double get nettoPiva => _fatturatoTotale - stimaTasseAccantonate;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  List<Map<String, dynamic>> _vociPianificate = [
    {
      'id': '1',
      'nome': 'Affitto / Mutuo',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Casa/Affitto',
      'previsto': 650.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '2',
      'nome': 'Bollette & Utenze',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Canoni/Bollette',
      'previsto': 140.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '3',
      'nome': 'Spesa Alimentare',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Alimentari',
      'previsto': 350.00,
      'tipo': 'variabile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '4',
      'nome': 'Assicurazione Auto',
      'categoria': 'Bisogni (50%)',
      'sottocategoria': 'Auto',
      'previsto': 120.00,
      'tipo': 'annuale_spalmata',
      'totaleAnnuale': 1440.00,
      'meseScadenza': 'SET',
    },
    {
      'id': '5',
      'nome': 'Ristoranti & Uscite',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Divertimento',
      'previsto': 200.00,
      'tipo': 'variabile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '6',
      'nome': 'Hobby & Palestra',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Divertimento',
      'previsto': 80.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '7',
      'nome': 'Abbonamenti Streaming',
      'categoria': 'Svago (30%)',
      'sottocategoria': 'Canoni/Bollette',
      'previsto': 30.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '8',
      'nome': 'Fondo Emergenze',
      'categoria': 'Risparmio (20%)',
      'sottocategoria': 'Altro',
      'previsto': 300.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
    {
      'id': '9',
      'nome': 'Accantonamento Vacanze',
      'categoria': 'Risparmio (20%)',
      'sottocategoria': 'Viaggi',
      'previsto': 200.00,
      'tipo': 'mensile',
      'frequenzaMensile': 'tutti',
    },
  ];

  List<Map<String, dynamic>> get vociPianificate => List.unmodifiable(_vociPianificate);

  void aggiungiSpesaPianificata(Map<String, dynamic> voce) {
    _vociPianificate.add(voce);
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void rimuoviSpesaPianificata(String id) {
    _vociPianificate.removeWhere((v) => v['id'] == id);
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void azzeraPianificazioneSpese() {
    _vociPianificate.clear();
    _salvaDatiInLocalStorage();
    notifyListeners();
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

  WalletProvider() {
    _caricaDatiDaLocalStorage();
  }

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

  bool _superaDataFine(DateTime dataVirtuale, DateTime? dataFine) {
    if (dataFine == null) return false;
    final dVirtuale = DateTime(dataVirtuale.year, dataVirtuale.month, dataVirtuale.day);
    final dFine = DateTime(dataFine.year, dataFine.month, dataFine.day);
    return dVirtuale.isAfter(dFine);
  }

  List<TransactionModel> getMovimentiPrevisti(DateTime meseRiferimento) {
    final previsti = <TransactionModel>[];
    final ricorrenti = _transactions.where((t) => t.isRecurrent).toList();

    for (var tx in ricorrenti) {
      if (tx.frequenza != 'Ogni settimana') {
        int stepMesi = 1;
        if (tx.frequenza == 'Ogni 2 mesi') stepMesi = 2;
        else if (tx.frequenza == 'Ogni 3 mesi (Trimestrale)') stepMesi = 3;
        else if (tx.frequenza == 'Ogni 6 mesi (Semestrale)') stepMesi = 6;
        else if (tx.frequenza == 'Ogni anno (Annuale)') stepMesi = 12;

        int mesiDiff = (meseRiferimento.year - tx.date.year) * 12 + (meseRiferimento.month - tx.date.month);

        if (mesiDiff >= 0 && mesiDiff % stepMesi == 0) {
          int giornoPrevisto = int.tryParse(tx.giornoRicorrenza ?? '1') ?? tx.date.day;

          int maxGiorniMese = DateTime(meseRiferimento.year, meseRiferimento.month + 1, 0).day;
          int giornoEffettivo = giornoPrevisto > maxGiorniMese ? maxGiorniMese : giornoPrevisto;

          DateTime dataVirtuale = DateTime(meseRiferimento.year, meseRiferimento.month, giornoEffettivo);

          if (_superaDataFine(dataVirtuale, tx.dataFineRicorrenza)) {
            continue;
          }

          bool isStessoMeseCreazione = dataVirtuale.year == tx.date.year && dataVirtuale.month == tx.date.month;

          if (!isStessoMeseCreazione) {
            previsti.add(TransactionModel(
              id: 'prev_${tx.id}_${dataVirtuale.year}_${dataVirtuale.month}', 
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
            if (_superaDataFine(checkDate, tx.dataFineRicorrenza)) {
              continue;
            }

            if (checkDate.isAfter(tx.date)) {
              numOccorrenze++;
              primaDataValida ??= checkDate; 
            }
          }
        }
        
        if (numOccorrenze > 0) {
          final String etichettaOccorrenze = tx.isIncome ? 'entrate' : 'uscite';
          previsti.add(TransactionModel(
            id: 'prev_${tx.id}_${meseRiferimento.year}_${meseRiferimento.month}', 
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
      } 
      else if (tx.accountId == targetAccountId) {
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

      final vociPianificateStr = prefs.getString('vociPianificate');
      if (vociPianificateStr != null) {
        final List decoded = jsonDecode(vociPianificateStr);
        _vociPianificate = decoded.map((v) => Map<String, dynamic>.from(v)).toList();
      }

      _aggiornaTasseVirtuali();
      _calcolaStatoCuscinetto();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore durante la lettura: $e');
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
      await prefs.setString('vociPianificate', jsonEncode(_vociPianificate));

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
        'vociPianificate': _vociPianificate,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Errore salvataggio Cloud: $e');
    }
  }

  double get totaleTasseDovute {
    return _fattureIncassate.fold(
      0.0,
      (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0),
    );
  }

  double get saldoSalvadanaioTasse {
    final salvadanaio = _accounts.firstWhere(
      (a) => a.role == AccountRole.taxReserve || a.id == 'tax_account' || a.id == '3',
      orElse: () => _accounts.last,
    );
    return salvadanaio.amount;
  }

  double get tasseScoperteContoPrincipale {
    final scoperte = totaleTasseDovute - saldoSalvadanaioTasse;
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

    final String dataFinale = dataIncasso ?? 'Oggi';
    DateTime dataObj = DateTime.now();

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

  void deleteTransaction(String id) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final tx = _transactions[idx];

    String? targetGemelloId;
    if (id.endsWith('_da')) {
      targetGemelloId = id.replaceAll('_da', '_verso');
    } else if (id.endsWith('_verso')) {
      targetGemelloId = id.replaceAll('_verso', '_da');
    }

    _stornaSaldoConto(tx);

    if (targetGemelloId != null) {
      final gemelloIdx = _transactions.indexWhere((t) => t.id == targetGemelloId);
      if (gemelloIdx != -1) {
        _stornaSaldoConto(_transactions[gemelloIdx]);
        _transactions.removeAt(gemelloIdx);
      }
    } else {
      final bool isGiroconto = tx.category == 'Giroconto' ||
          tx.category == 'Trasferimento' ||
          tx.title.toLowerCase().contains('giroconto') ||
          tx.title.toLowerCase().contains('salvadanaio') ||
          tx.title.toLowerCase().contains('accantonamento');

      if (isGiroconto) {
        final gemelloIdx = _transactions.indexWhere((t) =>
            t.id != tx.id &&
            t.isIncome != tx.isIncome &&
            (t.amount - tx.amount).abs() < 0.01 &&
            t.date.difference(tx.date).inHours.abs() <= 24);

        if (gemelloIdx != -1) {
          _stornaSaldoConto(_transactions[gemelloIdx]);
          _transactions.removeAt(gemelloIdx);
        }
      }
    }

    _transactions.removeWhere((t) => t.id == id);

    _aggiornaTasseVirtuali();
    _calcolaStatoCuscinetto();
    _salvaDatiInLocalStorage();
    notifyListeners();
  }

  void _stornaSaldoConto(TransactionModel tx) {
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

  void stopRecurrenceFromDate(String id, DateTime meseRiferimento) {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final tx = _transactions[idx];

      if (tx.date.year == meseRiferimento.year && tx.date.month == meseRiferimento.month) {
        stopRecurrence(id);
      } else {
        final dataFine = DateTime(meseRiferimento.year, meseRiferimento.month, 1).subtract(const Duration(days: 1));
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
          dataFineRicorrenza: dataFine,
        );
        _salvaDatiInLocalStorage();
        notifyListeners();
      }
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
      final targetAccount = _accounts.firstWhere((a) => a.id == (tx.accountId ?? 'main_account'), orElse: () => _accounts.first);

      if (tx.isIncome) {
        targetAccount.amount -= tx.amount;
      } else {
        targetAccount.amount += tx.amount;
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
      AccountModel(id: 'main_account', title: 'Conto Principale (IBAN)', subtitle: 'Conto Operativo', amount: 0.00, color: const Color(0xFF2DD4BF), role: AccountRole.principal),
      AccountModel(id: 'tax_account', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6), role: AccountRole.taxReserve),
      AccountModel(id: 'savings_account', title: 'Fondo Risparmio', subtitle: 'Riserva Liquidità', amount: 0.00, color: const Color(0xFFF59E0B), role: AccountRole.standard),
    ];

    isPartitaIVA = true; 
    _fatturatoTotale = 0.00;
    _transactions.clear();
    _fattureDaIncassare.clear();
    _fattureIncassate.clear();
    _vociPianificate.clear();

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

    // Preserva la selezione dei singoli mesi se fornita o già esistente
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

  // 🎯 AGGIORNAMENTO PREFERENZE PROFILO FISCALE (NO RETROATTIVITÀ SULLO STORICO)
  void aggiornaProfiloFiscale({
    required String nuovoAteco,
    required double nuovoCoeff,
    required double nuovaImposta,
    bool ricalcolaFattureAnnoCorrente = false, // Ignorato: il passato non si tocca
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
      AccountModel(id: 'main_account', title: 'Conto Principale (IBAN)', subtitle: 'Conto Operativo', amount: 0.00, color: const Color(0xFF2DD4BF), role: AccountRole.principal),
      AccountModel(id: 'tax_account', title: 'Salvadanaio Tasse', subtitle: 'Obiettivo Riserva', amount: 0.00, color: const Color(0xFF3B82F6), role: AccountRole.taxReserve),
      AccountModel(id: 'savings_account', title: 'Fondo Risparmio', subtitle: 'Riserva Liquidità', amount: 0.00, color: const Color(0xFFF59E0B), role: AccountRole.standard),
    ];

    _fatturatoTotale = 0.00;
    _haRispostoRicalibrazione = false;

    // 🎯 MATRICE ESATTA: Agosto (idx 7), Novembre (idx 10), Dicembre (idx 11) OFF
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