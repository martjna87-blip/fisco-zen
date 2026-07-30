import 'dart:ui';
import '1_onboarding_wizard.dart'; // 👈 Per aprire il questionario sul "Primo Avvio"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '2_wallet_screen.dart';
import '3_1_PI_incasso_fatture.dart';
import '3_2_PI_registra_fattura.dart';
import '3_3_PI_tasse_accantonamento.dart';
import '3_5_PI_dettaglio_fatture_sheet.dart';

class HomeScreen extends StatefulWidget {
  final String? codiceAtecoIniziale;
  final double? coefficienteIniziale;
  final double? aliquotaImpostaIniziale;
  final VoidCallback? onSwipeToWallet;

  const HomeScreen({
    super.key,
    this.codiceAtecoIniziale,
    this.coefficienteIniziale,
    this.aliquotaImpostaIniziale,
    this.onSwipeToWallet,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _codiceAteco;
  late double _coefficienteRedditivita;
  late double _aliquotaImposta;
  final double _aliquotaInps = 0.2607;

  final List<String> _contiWallet = [
    'Conto Principale (IBAN)',
    'Carta Spese & Svago',
    'Salvadanaio Emergenze / Tasse',
  ];

  @override
  void initState() {
    super.initState();
    _codiceAteco = widget.codiceAtecoIniziale ?? '74.10.21 - Consulenza & Digital';
    _coefficienteRedditivita = widget.coefficienteIniziale ?? 0.78;
    _aliquotaImposta = widget.aliquotaImpostaIniziale ?? 0.05;
  }

  double _calcolaTasseComplete(double lordo) {
    if (lordo <= 0) return 0.0;
    
    final double imponibile = lordo * _coefficienteRedditivita;

    final double inpsY = imponibile * _aliquotaInps;
    final double impostaY = imponibile * _aliquotaImposta;
    final double saldoY = inpsY + impostaY;

    final double accontoInpsY1 = inpsY * 0.80;
    final double accontoImpostaY1 = impostaY * 1.00;
    final double accontiY1 = accontoInpsY1 + accontoImpostaY1;

    return saldoY + accontiY1;
  }

  String _formattaValuta(double importo) {
    final parti = importo.toStringAsFixed(2).split('.');
    final intero = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intero,${parti[1]} €';
  }

  void _mostraDialogIncassoFatture(WalletProvider walletProvider) {
    showDialog(
      context: context,
      builder: (context) => IncassoFattureSheet(
        fattureDaIncassare: walletProvider.fattureDaIncassare,
        contiWallet: _contiWallet,
        coefficienteRedditivita: _coefficienteRedditivita,
        aliquotaImposta: _aliquotaImposta,
        aliquotaInps: _aliquotaInps,
        onIncasse: (idFattura, contoDestinazione, importoLordo, importoTasse, dataFormattata) {
          _mostraFeedback('Incassata fattura con successo!');
        },
      ),
    );
  }

  void _mostraDialogRegistraFattura() {
    showDialog(
      context: context,
      builder: (context) => RegistraFatturaSheet(
        onFatturaSalvata: (cliente, importo, dataFormattata) {
          _mostraFeedback('Fattura di ${importo.toStringAsFixed(2)}€ registrata per $cliente!');
        },
      ),
    );
  }

  void _mostraDialogDettaglioTasse(double totaleInSospeso, double totaleIncassatoReale) {
    showDialog(
      context: context,
      builder: (context) => TasseAccantonamentoSheet(
        codiceAteco: _codiceAteco,
        coefficienteRedditivita: _coefficienteRedditivita,
        aliquotaImposta: _aliquotaImposta,
        aliquotaInps: _aliquotaInps,
        totaleFatturatoIncassato: totaleIncassatoReale,
        totaleFatturatoInSospeso: totaleInSospeso,
        onAtecoCambiato: (nuovoAteco, nuovoCoeff) {
          setState(() {
            _codiceAteco = nuovoAteco;
            _coefficienteRedditivita = nuovoCoeff;
          });
        },
      ),
    );
  }

  // 🛡️ DIALOG RAPIDO CON GOAL TRACKER & FEEDBACK PERCENTUALE (STESSO DEL WALLET)
  void _mostraDialogAccantonamentoTasse(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final accounts = walletProvider.accounts;

    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi avere almeno due conti per accantonare le tasse.')),
      );
      return;
    }

    final double tasseTotaliCalcolate = accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double riservaGiaAccantonata = accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double tasseScoperte = (tasseTotaliCalcolate - riservaGiaAccantonata).clamp(0.0, double.infinity);
    final double importoMancanteReale = tasseScoperte > 0.01 ? tasseScoperte : 0.0;

    final TextEditingController importoController = TextEditingController(
      text: importoMancanteReale > 0 ? importoMancanteReale.toStringAsFixed(2) : '',
    );

    final contoConTasse = accounts.firstWhere(
      (a) => a.virtualTaxAmount > 0 && !a.title.toLowerCase().contains('salvadanaio'),
      orElse: () => accounts[0],
    );

    final salvadanaioTasse = accounts.firstWhere(
      (a) => a.title.toLowerCase().contains('salvadanaio tasse'),
      orElse: () => accounts.length > 1 ? accounts[1] : accounts[0],
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final double importoInserito = double.tryParse(importoController.text.replaceAll(',', '.')) ?? 0.0;
          
          final double nuovaRiservaTotale = riservaGiaAccantonata + importoInserito;
          
          final double percentualeText = tasseTotaliCalcolate > 0.01 
              ? (nuovaRiservaTotale / tasseTotaliCalcolate * 100) 
              : (nuovaRiservaTotale > 0 ? 100.0 : 0.0);
              
          final double percentualeBarra = tasseTotaliCalcolate > 0.01 
              ? (nuovaRiservaTotale / tasseTotaliCalcolate).clamp(0.0, 1.0) 
              : (nuovaRiservaTotale > 0 ? 1.0 : 0.0);
              
          final double extraCuscinetto = nuovaRiservaTotale > tasseTotaliCalcolate 
              ? nuovaRiservaTotale - tasseTotaliCalcolate 
              : 0.0;

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C21),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 22),
                SizedBox(width: 8),
                Text('Accantona Tasse', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Totale Tasse Dovute:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('${tasseTotaliCalcolate.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Già in Salvadanaio:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('${riservaGiaAccantonata.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Copertura Totale: ${percentualeText.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (extraCuscinetto > 0)
                            Text(
                              '+${extraCuscinetto.toStringAsFixed(0)} € Cuscinetto',
                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percentualeBarra,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: importoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Importo da aggiungere (€)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (importoInserito > 0) {
                    walletProvider.eseguiGiroconto(
                      daAccountId: contoConTasse.id,
                      aAccountId: salvadanaioTasse.id,
                      importo: importoInserito,
                      isAccantonamentoTasse: true,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          extraCuscinetto > 0
                              ? 'Messo al sicuro il 100% delle tasse + ${extraCuscinetto.toStringAsFixed(0)} € di cuscinetto! 🛡️'
                              : 'Hai messo al sicuro ${importoInserito.toStringAsFixed(2)} €! 🎉',
                        ),
                        backgroundColor: const Color(0xFF3B82F6),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Metti al Sicuro', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostraFeedback(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messaggio),
        backgroundColor: const Color(0xFF2DD4BF),
      ),
    );
  }

  void _mostraConfermaResetGlobale(BuildContext context, WalletProvider walletProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Reset Completo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Vuoi davvero azzerare tutti i dati?\n\nVerranno cancellati il fatturato, le stime tasse, i conti e lo storico di tutte le fatture.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              walletProvider.resetTuttiIDati();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tutti i dati sono stati azzerati con successo!'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            child: const Text('Azzera Tutto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    final double patrimonioNetto = walletProvider.patrimonioNetto;
    final double fatturato = walletProvider.fatturatoTotale;

    final fattureDaIncassare = walletProvider.fattureDaIncassare;
    final fattureIncassate = walletProvider.fattureIncassate;

    final double totaleInSospeso = fattureDaIncassare.fold(0.0, (sum, item) => sum + (item['importo'] as double));
    final double tasseStimateInSospeso = _calcolaTasseComplete(totaleInSospeso);
    final double nettoStimatoInSospeso = totaleInSospeso - tasseStimateInSospeso;
    final double tasseFatturatoIncassato = _calcolaTasseComplete(fatturato);
    final double stimaTasseTotaleComplessivo = tasseStimateInSospeso + tasseFatturatoIncassato;

    final double tasseTotaliCalcolate = walletProvider.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double riservaGiaAccantonata = walletProvider.accounts
        .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, acc) => sum + acc.amount);

    final double residuoTasseDaCoprire = (tasseTotaliCalcolate - riservaGiaAccantonata).clamp(0.0, double.infinity);
    final double nettoReale = patrimonioNetto - tasseTotaliCalcolate;
    
    // 👈 CONDIZIONE ULTRA-SICURA
    final bool isTasseCoperte = residuoTasseDaCoprire <= 0.01;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 🎯 HEADER PORTAFOGLIO
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220, // 👈 ALTEZZA RIDOTTA
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.45,
                    ),
                  ),
                ),
                Container(
                  height: 220, // 👈 ALTEZZA RIDOTTA
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0F0F12).withOpacity(0.5),
                        const Color(0xFF0F0F12),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  left: 16,
                  child: SafeArea(
                    child: Row(
                      children: [
                        // 1️⃣ TASTO ROSSO TONDO: RESET CONTI & FATTURE (CONSERVA IL PROFILO E LA HOME)
                        InkWell(
                          onTap: () async {
                            await walletProvider.resetSoloMovimentieFatture();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fatture e conti azzerati! Profilo ATECO conservato.'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.20),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                            ),
                            child: const Icon(Icons.refresh_rounded, color: Color(0xFFEF4444), size: 16),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 2️⃣ TASTO GIALLO: RESET TOTALE & PRIMO AVVIO (TORNA AL QUESTIONARIO)
                        InkWell(
                          onTap: () async {
                            await walletProvider.resetTuttiIDati();
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingWizard(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.restart_alt_rounded, color: Color(0xFFF59E0B), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'PRIMO AVVIO',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 👈 TASTINO TEST MODE FREE / PRO
                        InkWell(
                          onTap: () {
                            walletProvider.toggleProUser();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  walletProvider.isProUser 
                                      ? '✨ Modalità PRO Attivata (Test)' 
                                      : '🔒 Modalità FREE Attivata (Test)',
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: walletProvider.isProUser 
                                    ? const Color(0xFFA855F7) 
                                    : const Color(0xFFF59E0B),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: walletProvider.isProUser 
                                  ? const Color(0xFFA855F7).withOpacity(0.2) 
                                  : const Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: walletProvider.isProUser 
                                    ? const Color(0xFFA855F7) 
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                            child: Text(
                              walletProvider.isProUser ? '✨ PRO' : '🔒 FREE',
                              style: TextStyle(
                                color: walletProvider.isProUser 
                                    ? const Color(0xFFA855F7) 
                                    : const Color(0xFFF59E0B),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 16,
                  child: SafeArea(
                    child: FilledButton.icon(
                      onPressed: () => _mostraDialogDettaglioTasse(totaleInSospeso, fatturato),
                      icon: const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2DD4BF)),
                      label: Text(
                        'ATECO (${(_coefficienteRedditivita * 100).toInt()}%)',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),

                // 🎯 CONTENUTO CENTRATO
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 0), // 👈 SPAZIO RIMOSSO PER ALZARE IL TESTO
                    const Text(
                      'PORTAFOGLIO NETTO', 
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${patrimonioNetto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                          style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  '${nettoReale.toStringAsFixed(0)} €',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.savings_rounded, color: Color(0xFF3B82F6), size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  '${tasseTotaliCalcolate.toStringAsFixed(0)} €',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                
                                // 👈 LOGICA BOTTONE AGGIORNATA
                                if (!isTasseCoperte) 
                                  InkWell(
                                    onTap: () => _mostraDialogAccantonamentoTasse(context), // 👈 APRE IL POPUP GIUSTO
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                                      ),
                                      child: const Text(
                                        'Accantona',
                                        style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                                else
                                  InkWell(
                                    onTap: () => _mostraDialogAccantonamentoTasse(context), // 👈 CLICCABILE ANCHE QUI
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                                          SizedBox(width: 3),
                                          Text(
                                            'Protette',
                                            style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // CONTENUTO SCROLLABILE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // 🛡️ 1. SERBATOIO RISERVA TASSE
                  Builder(
                    builder: (context) {
                      final double riservaAccantonata = walletProvider.accounts
                          .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
                          .fold(0.0, (sum, acc) => sum + acc.amount);

                      final double percentuale = tasseTotaliCalcolate > 0 ? (riservaAccantonata / tasseTotaliCalcolate).clamp(0.0, 2.0) : 1.0;
                      final double percentualeText = tasseTotaliCalcolate > 0 ? (riservaAccantonata / tasseTotaliCalcolate * 100) : 100;
                      final double cuscinettoExtra = riservaAccantonata > tasseTotaliCalcolate ? riservaAccantonata - tasseTotaliCalcolate : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141417).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Serbatoio Riserva Tasse',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: percentualeText >= 100 
                                        ? const Color(0xFF10B981).withOpacity(0.15) 
                                        : const Color(0xFFF59E0B).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${percentualeText.toStringAsFixed(0)}% Coperto',
                                    style: TextStyle(
                                      color: percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (percentuale / 1.0).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentualeText >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dovuto Ateco: ${tasseTotaliCalcolate.toStringAsFixed(0)} €',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                Text(
                                  'In Salvadanaio: ${riservaAccantonata.toStringAsFixed(0)} €',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (cuscinettoExtra > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🛡️ Cuscinetto di sicurezza extra: +${cuscinettoExtra.toStringAsFixed(2)} €',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  // 2. I 3 QUADRANTI D'AZIONE (Ora indistruttibili con IntrinsicHeight)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildMiniCard(
                            icon: Icons.add_circle_outline_rounded,
                            title: 'Nuova\nfattura',
                            value: '+ Registra',
                            onTap: _mostraDialogRegistraFattura,
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: _buildMiniCard(
                            icon: Icons.shield_outlined,
                            title: 'Stima Tasse\nP.IVA',
                            value: '${stimaTasseTotaleComplessivo.toStringAsFixed(2)} €',
                            onTap: () => _mostraDialogDettaglioTasse(totaleInSospeso, fatturato),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: _buildMiniCard(
                            icon: Icons.analytics_outlined,
                            title: 'Dettaglio\nfatture',
                            value: '${fattureIncassate.length} incassate',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => DettaglioFattureSheet(
                                  fattureIncassate: fattureIncassate,
                                  coefficienteRedditivita: _coefficienteRedditivita,
                                  aliquotaImposta: _aliquotaImposta,
                                  aliquotaInps: _aliquotaInps,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. FATTURE DA INCASSARE
                  GestureDetector(
                    onTap: () => _mostraDialogIncassoFatture(walletProvider),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141417).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fatture da Incassare',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                            ],
                          ),
                          
                          const SizedBox(height: 12),

                          Text(
                            _formattaValuta(totaleInSospeso),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Lordo Totale in attesa di saldo',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Netto Stimato',
                                        style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '+${_formattaValuta(nettoStimatoInSospeso)}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(height: 24, width: 1, color: const Color(0xFFF59E0B).withOpacity(0.3)),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Tasse Stimate',
                                        style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '-${_formattaValuta(tasseStimateInSospeso)}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141417).withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}