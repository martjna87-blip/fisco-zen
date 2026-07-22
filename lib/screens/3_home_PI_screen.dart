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

  const HomeScreen({
    super.key,
    this.codiceAtecoIniziale,
    this.coefficienteIniziale,
    this.aliquotaImpostaIniziale,
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

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    final double patrimonioNetto = walletProvider.patrimonioNetto;
    final double fatturato = walletProvider.fatturatoTotale;
    final double tasseAccantonate = walletProvider.stimaTasseAccantonate;

    final fattureDaIncassare = walletProvider.fattureDaIncassare;
    final fattureIncassate = walletProvider.fattureIncassate;

    final double totaleInSospeso = fattureDaIncassare.fold(0.0, (sum, item) => sum + (item['importo'] as double));
    final double tasseStimateInSospeso = (totaleInSospeso * _coefficienteRedditivita) * (_aliquotaImposta + _aliquotaInps);
    final double nettoStimatoInSospeso = totaleInSospeso - tasseStimateInSospeso;

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
                Container(
                  height: 380,
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
                Container(
                  height: 380,
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    const Text('Portafoglio netto', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(
                      '${patrimonioNetto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} €',
                      style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _mostraDialogDettaglioTasse(totaleInSospeso, fatturato),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27272A).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFF2DD4BF), size: 13),
                                const SizedBox(width: 6),
                                Text(
                                  'ATECO (${(_coefficienteRedditivita * 100).toInt()}%)',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const WalletScreen(isPiva: true)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 13),
                                SizedBox(width: 6),
                                Text('Vai al Wallet', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                                children: const [
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

                      Expanded(
                        child: _buildMiniCard(
                          icon: Icons.shield_outlined,
                          title: 'Stima Tasse\nP.IVA',
                          value: '${tasseAccantonate.toStringAsFixed(2)} €',
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

                  const SizedBox(height: 12),

                  // PORTAFOGLIO EQUILIBRIO
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WalletScreen(isPiva: true)),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Equilibrio Portafoglio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Fatturato: ${fatturato.toStringAsFixed(0)} €', style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 8,
                              child: LinearProgressIndicator(
                                value: (patrimonioNetto / (fatturato > 0 ? fatturato : 1)).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFF27272A),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildMiniCard({required IconData icon, required String title, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFF27272A), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white70, size: 16),
            ),
            Text(title, style: const TextStyle(color: Color(0xFF71717A), fontSize: 11, height: 1.2)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}