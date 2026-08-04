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
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/serbatoio_tasse_widget.dart';
import '../widgets_shared/app_popup_wrapper.dart';
import '../data/notifications_provider.dart';

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
  // ⏳ CALCOLATORE GIORNI TRASCORSI DALL'EMISSIONE
  int _calcolaGiorniTrascorsi(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return 0;
    DateTime? parsedDate = DateTime.tryParse(dataStr);

    if (parsedDate == null && dataStr.contains('/')) {
      final parts = dataStr.split('/');
      if (parts.length == 3) {
        final g = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final a = int.tryParse(parts[2]);
        if (g != null && m != null && a != null) parsedDate = DateTime(a, m, g);
      }
    }

    if (parsedDate == null) {
      final List<String> mesi = [
        'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
        'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'
      ];
      final parts = dataStr.toLowerCase().split(' ');
      if (parts.length >= 3) {
        final giorno = int.tryParse(parts[0]);
        final meseIdx = mesi.indexOf(parts[1]);
        final anno = int.tryParse(parts[2]);
        if (giorno != null && meseIdx != -1 && anno != null) {
          parsedDate = DateTime(anno, meseIdx + 1, giorno);
        }
      }
    }

    if (parsedDate == null) return 0;
    final differenza = DateTime.now().difference(parsedDate).inDays;
    return differenza > 0 ? differenza : 0;
  }

  void _mostraDialogIncassoFatture(WalletProvider walletProvider) {
    AppPopupWrapper.mostra(
      context: context,
      child: IncassoFattureSheet(
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
    AppPopupWrapper.mostra(
      context: context,
      child: RegistraFatturaSheet(
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

  // 🛡️ DIALOG ACCANTONAMENTO CON MATEMATICA CORRETTA UNIFICATA
  void _mostraDialogAccantonamentoTasse(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final accounts = walletProvider.accounts;

    if (accounts.length < 2) {
      AppNotifications.mostraInAlto(
        context, 
        'Devi avere almeno due conti per accantonare le tasse', 
        type: NotificationType.warning,
      );
      return;
    }

    // 1. Soldi già messi al sicuro nel Salvadanaio
    final double riservaGiaAccantonata = accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    // 2. Tasse ancora in sospeso sul Conto Principale da spostare
    final double tasseDaAccantonare = accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);

    // 3. Totale Tasse Dovute = Già in Salvadanaio + Ancora da accantonare
    final double tasseTotaliCalcolate = riservaGiaAccantonata + tasseDaAccantonare;

    // 4. L'importo mancante reale da precompilare nel campo di testo
    final double importoMancanteReale = tasseDaAccantonare > 0.01 ? tasseDaAccantonare : 0.0;

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
                    if (contoConTasse.amount < importoInserito) {
                      AppNotifications.mostraInAlto(
                        context,
                        'Saldo insufficiente su ${contoConTasse.title} per l\'accantonamento!',
                        type: NotificationType.error,
                      );
                      return;
                    }

                    walletProvider.eseguiGiroconto(
                      daAccountId: contoConTasse.id,
                      aAccountId: salvadanaioTasse.id,
                      importo: importoInserito,
                      isAccantonamentoTasse: true,
                    );
                    Navigator.pop(ctx);
                    AppNotifications.mostraInAlto(
                      context, 
                      extraCuscinetto > 0
                      ? 'Messo al sicuro il 100% delle tasse + ${extraCuscinetto.toStringAsFixed(0)} € di cuscinetto! 🛡️'
                      : 'Hai messo al sicuro ${importoInserito.toStringAsFixed(2)} €! 🎉',
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
    AppNotifications.mostraInAlto(context, messaggio);
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
              AppNotifications.mostraInAlto(
                context, 
                'Tutti i dati sono stati azzerati con successo!🎉',
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
    final double topPadding = MediaQuery.of(context).padding.top; // 👈 Spazio hardware per orologio e notch
    final double headerHeight = 220 + topPadding; // 👈 Altezza fluida edge-to-edge

    final walletProvider = context.watch<WalletProvider>();

    final double patrimonioNetto = walletProvider.patrimonioNetto;
    final double fatturato = walletProvider.fatturatoTotale;

    final fattureDaIncassare = walletProvider.fattureDaIncassare;
    final fattureIncassate = walletProvider.fattureIncassate;
    // 🤖 Avvia la scansione in background delle fatture >15 giorni
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().verificaFattureInRitardo(fattureDaIncassare);
    });

    final double totaleInSospeso = fattureDaIncassare.fold(0.0, (sum, item) => sum + (item['importo'] as double));
    final double tasseStimateInSospeso = _calcolaTasseComplete(totaleInSospeso);
    final double nettoStimatoInSospeso = totaleInSospeso - tasseStimateInSospeso;
    final double tasseFatturatoIncassato = _calcolaTasseComplete(fatturato);
    final double stimaTasseTotaleComplessivo = tasseStimateInSospeso + tasseFatturatoIncassato;

    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    final double riservaGiaAccantonata = walletProvider.accounts
        .where((acc) => acc.title.toLowerCase().contains('salvadanaio tasse') || acc.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, acc) => sum + acc.amount);

    final double tasseDaAccantonare = walletProvider.accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double residuoTasseDaCoprire = tasseDaAccantonare;

    final double sommaContiLiquidi = walletProvider.accounts
        .where((a) => !a.title.toLowerCase().contains('salvadanaio tasse') && !a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);
    final double nettoReale = (sommaContiLiquidi - tasseDaAccantonare).clamp(0.0, double.infinity);
    
    final bool isTasseCoperte = residuoTasseDaCoprire <= 0.01;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 🎯 HEADER P.IVA IMMERSIVO & NATIVO (Stile iOS/Android)
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. Immagine di sfondo Edge-to-Edge
                Container(
                  height: headerHeight,
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
                // 2. Gradiente sfumato
                Container(
                  height: headerHeight,
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

                // 3. 🎯 TITOLO DI PAGINA IN ALTO A SINISTRA (Stile H1 Nativo)
                Positioned(
                  top: topPadding + 12,
                  left: 20,
                  child: const Text(
                    'Gestione P.IVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // 4. Pulsante ATECO in alto a destra
                Positioned(
                  top: topPadding + 10,
                  right: 16,
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

                // 5. CONTENUTO CENTRATO: FATTURATO LORDO IN EVIDENZA + TASSE DOVUTE SOTTO
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 📊 1. FATTURATO LORDO (Centrato in grande - 44pt)
                      InkWell(
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
                        onLongPress: () {
                          AppPopupWrapper.mostraInfo(
                            context: context,
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFF2DD4BF),
                            titolo: 'Fatturato Incassato (Criterio di Cassa)',
                            descrizione: 'Somma totale dei compensi realmente incassati nel periodo fiscale. È l\'importo su cui viene applicato il tuo Coefficiente di Redditività ATECO.',
                            formula: 'Incassato Reale × Coefficiente ATECO',
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'FATTURATO LORDO',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${fatturato.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 🛡️ 2. TASSE DOVUTE (Sotto il Fatturato, Font contenuto - 15pt in Badge)
                      InkWell(
                        onTap: () => _mostraDialogDettaglioTasse(totaleInSospeso, fatturato),
                        onLongPress: () {
                          AppPopupWrapper.mostraInfo(
                            context: context,
                            icon: Icons.shield_rounded,
                            color: const Color(0xFF3B82F6),
                            titolo: 'Stima Tasse Totali (Saldo + Acconti)',
                            descrizione: 'Quota complessiva da accantonare per la dichiarazione dei redditi. Include sia il Saldo dell\'anno in corso che l\'Anticipo/Acconto per l\'anno successivo (Imposta Sostitutiva + INPS).',
                            formula: 'Saldo Anno Corrente + Acconti Anno Successivo',
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 14),
                              const SizedBox(width: 6),
                              const Text(
                                'Tasse Dovute:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${tasseTotaliCalcolate.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // CONTENUTO SCROLLABILE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // 🛡️ SERBATOIO RISERVA TASSE (Tap disattivato in Home | LongPress per info attivo)
                  GestureDetector(
                    // onTap: () => _mostraDialogAccantonamentoTasse(context), // 👈 DISATTIVATO TEMPORANEAMENTE
                    onLongPress: () {
                      AppPopupWrapper.mostraInfo(
                        context: context,
                        icon: Icons.shield_rounded,
                        color: const Color(0xFF3B82F6),
                        titolo: 'Serbatoio Riserva Tasse',
                        descrizione: 'Mostra lo stato di copertura delle tue tasse stimate.',
                        formula: 'In Salvadanaio ÷ Dovuto ATECO',
                      );
                    },
                    child: const SerbatoioTasseWidget(
                      cardColor: Color(0xFF141417),
                    ),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. NUOVA FATTURA (+ Registra)
                      Expanded(
                        child: _buildMiniCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Nuova\nfattura',
                          value: '+ Registra',
                          onTap: _mostraDialogRegistraFattura,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. DA INCASSARE
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final bool haFattureDaIncassare = fattureDaIncassare.isNotEmpty;

                            final int fattureInRitardo = fattureDaIncassare
                                .where((f) => _calcolaGiorniTrascorsi(f['data']?.toString()) >= 15)
                                .length;
                            final bool haRitardi = fattureInRitardo > 0;

                            return _buildMiniCard(
                              icon: haRitardi
                                  ? Icons.warning_amber_rounded
                                  : Icons.hourglass_top_rounded,
                              title: 'Da\nincassare',
                              value: haRitardi
                                  ? '⚠️ $fattureInRitardo (>15 gg)'
                                  : (haFattureDaIncassare
                                      ? '${fattureDaIncassare.length} (${totaleInSospeso.toStringAsFixed(0)} €)'
                                      : 'Nessuna'),
                              iconColor: haRitardi
                                  ? const Color(0xFFEF4444)
                                  : (haFattureDaIncassare ? const Color(0xFFF59E0B) : null),
                              valueColor: haRitardi
                                  ? const Color(0xFFEF4444)
                                  : (haFattureDaIncassare ? const Color(0xFFF59E0B) : null),
                              onTap: () => _mostraDialogIncassoFatture(walletProvider),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. DETTAGLIO FATTURE
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
    Color? iconColor,
    Color? valueColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 86, // 👈 ALTEZZA FISSA DEFINITIVA ANTI-OVERFLOW
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF141417).withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: iconColor != null 
                ? iconColor.withOpacity(0.3) 
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}