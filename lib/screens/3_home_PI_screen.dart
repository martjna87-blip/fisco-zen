import 'dart:ui';
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

  // 🧮 HELPER UNIFICATO CALCOLI FISCALI
  double _calcolaTasseComplete(double lordo) {
    if (lordo <= 0) return 0.0;
    
    final double imponibile = lordo * _coefficienteRedditivita;

    // 1. Saldi Y
    final double inpsY = imponibile * _aliquotaInps;
    final double impostaY = imponibile * _aliquotaImposta;
    final double saldoY = inpsY + impostaY;

    // 2. Acconti Y+1
    final double accontoInpsY1 = inpsY * 0.80;
    final double accontoImpostaY1 = impostaY * 1.00;
    final double accontiY1 = accontoInpsY1 + accontoImpostaY1;

    // Totale complessivo
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

    // 🧮 CALCOLI SICURI
    final double totaleInSospeso = fattureDaIncassare.fold(0.0, (sum, item) => sum + (item['importo'] as double));
    
    final double tasseStimateInSospeso = _calcolaTasseComplete(totaleInSospeso);
    final double nettoStimatoInSospeso = totaleInSospeso - tasseStimateInSospeso;

    final double tasseFatturatoIncassato = _calcolaTasseComplete(fatturato);

    final double stimaTasseTotaleComplessivo = tasseStimateInSospeso + tasseFatturatoIncassato;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // HEADER PORTAFOGLIO
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. IMMAGINE DI SFONDO
                Container(
                  height: 280,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.25,
                    ),
                  ),
                ),
                // 2. GRADIENTE SCURO
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0F0F12).withOpacity(0.8),
                        const Color(0xFF0F0F12),
                      ],
                    ),
                  ),
                ),

                // 🔄 3. BOTTONE RESET SPOSTATO IN ALTO A DESTRA (SOLO PER DEV)
                Positioned(
                  top: 10,
                  right: 16,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () => _mostraConfermaResetGlobale(context, walletProvider),
                      icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFFEF4444), size: 22),
                      tooltip: 'Reset Dati',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
                      ),
                    ),
                  ),
                ),

                // 4. TESTO E BOTTONI CENTRALI (IDENTICI AL WALLET!)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    const Text('Portafoglio netto', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(
                      '${patrimonioNetto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                      style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    const SizedBox(height: 12),

                    // RIGA BOTTONI ATECO & WALLET (STESSO STILE DEL RIEPILOGO ANNUALE)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // BOTTONE ATECO
                        FilledButton.icon(
                          onPressed: () => _mostraDialogDettaglioTasse(totaleInSospeso, fatturato),
                          icon: const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF2DD4BF)),
                          label: Text(
                            'ATECO (${(_coefficienteRedditivita * 100).toInt()}%)',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.white.withOpacity(0.18)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // BOTTONE WALLET
                        FilledButton.icon(
                          onPressed: () {
                            if (widget.onSwipeToWallet != null) {
                              widget.onSwipeToWallet!(); 
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WalletScreen(isPiva: true)),
                              );
                            }
                          },
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.white),
                          label: const Text(
                            'Wallet',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.white.withOpacity(0.18)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // CONTENUTO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // CARD FATTURE DA INCASSARE
                  GestureDetector(
                    onTap: () => _mostraDialogIncassoFatture(walletProvider),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 8),
                                  const Text(
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
                  const SizedBox(height: 12),

                  // TRIPTICO CARDS
                  Row(
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

                      // 🛡️ STIMA TASSE P.IVA
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛠️ MINI CARD IDENTICA A QUELLA DEL WALLET (Prima immagine)
  Widget _buildMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110, // 👈 Stessa altezza del Wallet
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141417).withOpacity(0.92), // 👈 Stesso colore/opacità
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icona senza il cerchietto scuro attorno, dimensione 22px
            Icon(icon, color: Colors.white70, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70, // 👈 Colore e leggibilità identici
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12, // 👈 Stesso font del Wallet
                    fontWeight: FontWeight.bold,
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