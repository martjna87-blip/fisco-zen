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
import '../widgets_shared/app_bottom_sheet.dart'; // 👈 Aggiunto import del nuovo Bottom Sheet
import '../data/notifications_provider.dart';
import '../widgets_shared/fiscon_logo.dart';
import '../widgets_shared/advisor_tip_card.dart'; // 👈 Importa il consulente
import '../data/advisor_engine.dart'; // 👈 Motore delle regole del Consulente

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
  // 🙈 Mantiene in memoria i titoli dei tip chiusi con la 'X'
  final Set<String> _dismissedAdvisorTips = {};

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

  double _calcolaTasseComplete(List<Map<String, dynamic>> listaFatture) {
    double totaleTasse = 0.0;
    for (var f in listaFatture) {
      final double lordo = (f['importo'] as num?)?.toDouble() ?? 0.0;
      // 📌 Legge l'ATECO della singola fattura (fallback su quello principale)
      final double coef = (f['coefAteco'] as num?)?.toDouble() ?? _coefficienteRedditivita;
      
      final double imponibile = lordo * coef;
      final double inpsY = imponibile * _aliquotaInps;
      final double impostaY = imponibile * _aliquotaImposta;
      final double saldoY = inpsY + impostaY;
      final double accontiY1 = (inpsY * 0.80) + (impostaY * 1.00);
      
      totaleTasse += (saldoY + accontiY1);
    }
    return totaleTasse;
  }

  String _formattaValuta(double importo) {
    final parti = importo.toStringAsFixed(2).split('.');
    final intero = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$intero,${parti[1]} €';
  }

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
    AppBottomSheet.mostra(
      context: context,
      child: RegistraFatturaSheet(
        onFatturaSalvata: (cliente, importo, dataFormattata) {
          _mostraFeedback('Fattura di ${importo.toStringAsFixed(2)}€ registrata per $cliente!');
        },
      ),
    );
  }

  void _mostraDialogDettaglioTasse(double totaleInSospeso, double totaleIncassatoReale) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    AppPopupWrapper.mostra(
      context: context,
      child: TasseAccantonamentoSheet(
        codiceAteco: _codiceAteco,
        coefficienteRedditivita: _coefficienteRedditivita,
        aliquotaImposta: _aliquotaImposta,
        aliquotaInps: _aliquotaInps,
        totaleFatturatoIncassato: totaleIncassatoReale,
        totaleFatturatoInSospeso: totaleInSospeso,
        fattureIncassate: walletProvider.fattureIncassate,    // 👈 Passa le fatture incassate
        fattureDaIncassare: walletProvider.fattureDaIncassare,// 👈 Passa le fatture in sospeso
        onAtecoCambiato: (nuovoAteco, nuovoCoeff) {
          setState(() {
            _codiceAteco = nuovoAteco;
            _coefficienteRedditivita = nuovoCoeff;
          });
        },
      ),
    );
  }

  // 👈 MODIFICA 1 UNIFICATA: Helper per Dettaglio Fatture tramite AppPopupWrapper
  void _mostraDialogDettaglioFatture(List<Map<String, dynamic>> fattureIncassate) {
    AppPopupWrapper.mostra(
      context: context,
      child: DettaglioFattureSheet(
        fattureIncassate: fattureIncassate,
        coefficienteRedditivita: _coefficienteRedditivita,
        aliquotaImposta: _aliquotaImposta,
        aliquotaInps: _aliquotaInps,
      ),
    );
  }

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

    final double riservaGiaAccantonata = accounts
        .where((a) => a.title.toLowerCase().contains('salvadanaio tasse') || a.title.toLowerCase().contains('acconto tasse'))
        .fold(0.0, (sum, a) => sum + a.amount);

    final double tasseDaAccantonare = accounts.fold(0.0, (sum, acc) => sum + acc.virtualTaxAmount);
    final double tasseTotaliCalcolate = riservaGiaAccantonata + tasseDaAccantonare;
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
    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = 220 + topPadding;

    final walletProvider = context.watch<WalletProvider>();

    final double fatturato = walletProvider.fatturatoTotale;

    final fattureDaIncassare = walletProvider.fattureDaIncassare;
    final fattureIncassate = walletProvider.fattureIncassate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().verificaFattureInRitardo(fattureDaIncassare);
    });

    final double totaleInSospeso = fattureDaIncassare.fold(0.0, (sum, item) => sum + (item['importo'] as double));

    final double tasseRealiFatture = walletProvider.fattureIncassate
        .fold(0.0, (sum, f) => sum + ((f['importoTasse'] as num?)?.toDouble() ?? 0.0));
    final double tasseTotaliCalcolate = tasseRealiFatture;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. IMMAGINE DI SFONDO (Allungata per mimetizzarsi perfettamente sotto i bottoni)
                Container(
                  height: headerHeight + 100,
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
                
                // GRADIENTE MIMETICO (Integrazione pulita senza tagli netti)
                Container(
                  height: headerHeight + 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.85, 1.0],
                      colors: [
                        const Color(0xFF0F0F12).withOpacity(0.0),
                        const Color(0xFF0F0F12).withOpacity(0.5),
                        const Color(0xFF0F0F12),
                        const Color(0xFF0F0F12),
                      ],
                    ),
                  ),
                ),

                // ✨ EFFETTO GLOW (Verde Acqua / Cyan Business)
                Positioned(
                  top: -60,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2DD4BF).withOpacity(0.10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2DD4BF).withOpacity(0.10),
                          blurRadius: 110,
                          spreadRadius: 40,
                        )
                      ],
                    ),
                  ),
                ),

                // LOGO FISCON
                Positioned(
                  top: topPadding + 12,
                  left: 20,
                  child: const FiscOnLogo(
                    fontSize: 22,
                    sottotitolo: 'Gestione P.IVA',
                  ),
                ),

                // BADGE ATECO DINAMICO
                Positioned(
                  top: topPadding + 10,
                  right: 16,
                  child: FilledButton.icon(
                    onPressed: () {
                      AppNotifications.mostraInAlto(
                        context,
                        'Profilo ATECO attivo: ${walletProvider.codiceAteco} • Gestibile in Profilo & Impostazioni',
                        type: NotificationType.success,
                      );
                    },
                    icon: const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2DD4BF)),
                    label: Text(
                      'ATECO ${walletProvider.codiceAteco.split(' - ').first.trim()} (${(walletProvider.coeffRedditivita * 100).toInt()}%)',
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

                // FATTURATO LORDO & TASSE DOVUTE
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => _mostraDialogDettaglioFatture(fattureIncassate),
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
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          decoration: const BoxDecoration(color: Colors.transparent),
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
                              const SizedBox(height: 4),
                              Text(
                                '${fatturato.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${tasseTotaliCalcolate.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 18,
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

            // 🚀 TRASLAZIONE DEI BOTTONI IN PRIMA POSIZIONE
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // 1. I TRE BOTTONI OPERATIVI (Nuova Fattura, Da Incassare, Dettaglio)
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
                            child: Builder(
                              builder: (context) {
                                final bool haFattureDaIncassare = fattureDaIncassare.isNotEmpty;
                                final int totaleFatture = fattureDaIncassare.length;

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
                                      ? '⚠️ $fattureInRitardo in ritardo'
                                      : (haFattureDaIncassare
                                          ? '$totaleFatture (${totaleInSospeso.toStringAsFixed(0)} €)'
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
                          Expanded(
                            child: _buildMiniCard(
                              icon: Icons.analytics_outlined,
                              title: 'Dettaglio\nfatture',
                              value: '${fattureIncassate.length} incassate',
                              onTap: () => _mostraDialogDettaglioFatture(fattureIncassate),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🤖 IL CONSULENTE VIRTUALE (Memoria Globale nel Provider)
                    Builder(
                      builder: (context) {
                        final tips = AdvisorEngine.getBusinessTips(walletProvider);

                        if (tips.isEmpty) return const SizedBox.shrink();

                        final currentTip = tips.first;

                        return AdvisorTipCard(
                          mood: currentTip.mood,
                          title: currentTip.title,
                          message: currentTip.message,
                          actionText: currentTip.actionText,
                          icon: currentTip.icon,
                          onDismiss: () {
                            // 👈 Salva la chiusura direttamente nel WalletProvider!
                            walletProvider.dismissAdvisorTip(currentTip.title);
                          },
                          onAction: currentTip.action == null ? null : () {
                            if (currentTip.action == AdvisorAction.vediFattureInRitardo) {
                              _mostraDialogIncassoFatture(walletProvider);
                            } else if (currentTip.action == AdvisorAction.mettiAlSicuroTasse) {
                              SerbatoioTasseWidget.mostraDialog(context, cardColor: const Color(0xFF141417));
                            }
                          },
                        );
                      }
                    ),

                    // 2. SERBATOIO RISERVA TASSE (In seconda linea, aperto di default)
                    SerbatoioTasseWidget(
                      cardColor: const Color(0xFF141417),
                      isCollapsible: true,
                      initiallyExpanded: true, // 🟢 APERTO DI DEFAULT!
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
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
    final accentColor = iconColor ?? const Color(0xFF2DD4BF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141417).withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: -2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}