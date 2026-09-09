import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/wallet_provider.dart';
import '../screens/0_1_pro_upgrade.dart';
import '../widgets_shared/app_bottom_sheet.dart';
import '../widgets_shared/app_secondary_popup.dart';

class AnnualSummarySheet extends StatefulWidget {
  const AnnualSummarySheet({super.key});

  @override
  State<AnnualSummarySheet> createState() => _AnnualSummarySheetState();
}

class _AnnualSummarySheetState extends State<AnnualSummarySheet> {
  final PageController _pageController = PageController(viewportFraction: 0.88, initialPage: 1);
  int _selectedYearIndex = 1; // 0: Anno Scorso, 1: Anno Corrente, 2: Anno Prossimo
  int? _expandedMeseIdx; // Indice del mese aperto a tendina
  final Map<int, String> _meseViewMode = {}; // Traccia il tab attivo per mese: 'Bussola', 'Categorie', 'Movimenti'
  String? _expandedSubKey; // Traccia la sotto-tendina aperta (Bussola o Categorie)
  int? _selectedGraphMonthIndex; // Mese toccato sul grafico per il dettaglio puntuale

  bool _isSpesaFissa(String category) {
    final c = category.toLowerCase();
    return c.contains('mutuo') || c.contains('affitto') || c.contains('bollet') ||
           c.contains('utenz') || c.contains('spesa') || c.contains('alimentar') ||
           c.contains('supermercat') || c.contains('polizz') || c.contains('assicuraz') ||
           c.contains('finanziam') || c.contains('rate') || c.contains('scuola') ||
           c.contains('infanz') || c.contains('auto') || c.contains('carburant') ||
           c.contains('trasport') || c.contains('tv') || c.contains('internet') ||
           c.contains('telefon') || c.contains('casa');
  }

  final Color oceanCyan   = const Color(0xFF38BDF8);
  final Color greenProfit = const Color(0xFF10B981);
  final Color goldAccent  = const Color(0xFFFBBF24);
  final Color purpleZen   = const Color(0xFFC084FC);
  final Color taxBlue     = const Color(0xFF3B82F6);
  final Color alertRed    = const Color(0xFFEF4444);

  final List<String> _nomiMesiBrevi = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
  ];

  String _formattaValuta(double importo) {
    if (importo.abs() < 0.01) return '0 €';
    final parti = importo.abs().toStringAsFixed(0).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${importo < 0 ? '-' : ''}$intPart €';
  }

  String _formattaValutaDecimale(double importo) {
    final parti = importo.abs().toStringAsFixed(2).split('.');
    final intPart = parti[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${importo < 0 ? '-' : ''}$intPart,${parti[1]} €';
  }

  // ⚡ CALCOLATORE DINAMICO DATI REALI PER ANNO (CON DETTAGLI FISCALI & F24)
  List<Map<String, dynamic>> _calcolaDatiReali(WalletProvider wallet) {
    final DateTime ora = DateTime.now();
    final List<int> anni = [ora.year - 1, ora.year, ora.year + 1];
    final List<String> immagini = [
      'https://images.unsplash.com/photo-1499750310107-5fef28a66643?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=800&auto=format&fit=crop',
    ];

    final double coefAteco = wallet.coeffRedditivita > 0 ? wallet.coeffRedditivita : 0.78;
    final double aliquotaImposta = wallet.aliquotaImposta > 0 ? wallet.aliquotaImposta : 0.05;
    final double aliquotaInps = wallet.aliquotaInps > 0 ? wallet.aliquotaInps : 0.2607;

    return anni.asMap().entries.map((entry) {
      final int i = entry.key;
      final int anno = entry.value;

      double pivaLordaAnno = 0.0;
      double stipendioNettoAnno = 0.0;
      double extraNettoAnno = 0.0;
      double totSpesoAnno = 0.0;
      double imponibilePivaAnno = 0.0;
      double inpsSaldoAnno = 0.0;
      double impostaSaldoAnno = 0.0;

      // 💡 Recupera la matrice calcolata dal WalletProvider con i cuscinetti aggiornati
      final matriceProvider = wallet.calcolaMatriceProiezioneAnnuale(annoSelezionato: anno);

      final List<Map<String, dynamic>> storicoMesi = List.generate(12, (mIdx) {
        final int meseNum = mIdx + 1;
        final DateTime dtMese = DateTime(anno, meseNum);
        final bool isPassato = (anno < ora.year) || (anno == ora.year && meseNum <= ora.month);

        // 💡 Estrazione garantita dei dati di cuscinetto per mesi passati, presenti e futuri
        final meseMatrice = matriceProvider.firstWhere(
          (m) => m['meseIdx'] == meseNum, 
          orElse: () => <String, dynamic>{
            'quotaCuscinetto': 0.0,
            'erogazioneCuscinetto': 0.0,
            'isMeseOFF': false,
          },
        );
        final double quotaCuscinettoMatrice = (meseMatrice['quotaCuscinetto'] as num?)?.toDouble() ?? 0.0;
        final double erogazioneCuscinettoMatrice = (meseMatrice['erogazioneCuscinetto'] as num?)?.toDouble() ?? 0.0;
        final bool isMeseOFFMatrice = meseMatrice['isMeseOFF'] == true;

        final txMese = wallet.transactions.where((t) => t.date.year == anno && t.date.month == meseNum && !t.id.startsWith('rule_'));

        // P.IVA
        final double pivaMeseLorda = txMese.where((t) {
          final cat = t.category.toLowerCase();
          final title = t.title.toLowerCase();
          return t.isIncome && (cat.contains('p.iva') || cat.contains('fattura') || title.contains('incasso'));
        }).fold(0.0, (s, t) => s + t.amount);

        // Stipendio / Pensione
        final double stipMeseNetto = txMese.where((t) {
          final cat = t.category.toLowerCase();
          final title = t.title.toLowerCase();
          return t.isIncome && (cat.contains('stipendio') || cat.contains('pensione') || title.contains('stipendio'));
        }).fold(0.0, (s, t) => s + t.amount);

        // Extra
        final double extraMese = txMese.where((t) {
          if (!t.isIncome) return false;
          final cat = t.category.toLowerCase();
          final title = t.title.toLowerCase();
          return !cat.contains('p.iva') && !cat.contains('fattura') && !title.contains('incasso') &&
                 !cat.contains('stipendio') && !cat.contains('pensione') && !title.contains('stipendio') &&
                 !cat.contains('giroconto');
        }).fold(0.0, (s, t) => s + t.amount);

        // Spese (Escludiamo Giroconti e pagamenti F24/Tasse per evitare il doppio conteggio nel Risparmio Netto)
        final double spesoMese = txMese.where((t) {
          if (t.isIncome) return false;
          final String cat = t.category.toLowerCase();
          final String title = t.title.toLowerCase();
          
          final bool isGiroconto = cat.contains('giroconto');
          final bool isPagamentoTasse = cat.contains('tasse') || cat.contains('f24') || title.contains('f24');
          
          return !isGiroconto && !isPagamentoTasse;
        }).fold(0.0, (s, t) => s + t.amount);

        final previstiMese = wallet.getMovimentiPrevisti(dtMese);
        final double budgetMese = previstiMese.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

        // Calcoli fiscali mese
        final double impMese = pivaMeseLorda * coefAteco;
        final double inpsMese = impMese * aliquotaInps;
        final double impostaMese = impMese * aliquotaImposta;
        final double pivaMeseNetta = pivaMeseLorda - (inpsMese + impostaMese);

        pivaLordaAnno += pivaMeseLorda;
        stipendioNettoAnno += stipMeseNetto;
        extraNettoAnno += extraMese;
        totSpesoAnno += spesoMese;
        imponibilePivaAnno += impMese;
        inpsSaldoAnno += inpsMese;
        impostaSaldoAnno += impostaMese;

        return {
          'meseIdx': meseNum,
          'mese': _nomiMesiBrevi[mIdx],
          'pivaLorda': pivaMeseLorda,
          'pivaNetta': pivaMeseNetta,
          'stipendioNetto': stipMeseNetto,
          'extraNetto': extraMese,
          'incassatoTotaleNetto': pivaMeseNetta + stipMeseNetto + extraMese,
          'speso': spesoMese,
          'budget': budgetMese > 0 ? budgetMese : spesoMese,
          'isPassato': isPassato,
          'anno': anno,
          'quotaCuscinetto': quotaCuscinettoMatrice,
          'erogazioneCuscinetto': erogazioneCuscinettoMatrice,
          'isMeseOFF': isMeseOFFMatrice,
        };
      });

      // Recupero acconti già versati nell'anno precedente per l'anno in corso
      final double accontiGiaVersati = (anno == wallet.annoFiscaleCorrente)
          ? wallet.accontiVersatiAnnoPrecedente
          : 0.0;

      final double saldoTasseLordo = inpsSaldoAnno + impostaSaldoAnno;
      final double saldoTasseNetto = (saldoTasseLordo - accontiGiaVersati).clamp(0.0, double.infinity);
      final double accontiAnnoSuccessivo = (inpsSaldoAnno * 0.80) + (impostaSaldoAnno * 1.00);
      final double totaleF24Accantonare = saldoTasseNetto + accontiAnnoSuccessivo;

      final double pivaNettaAnno = (pivaLordaAnno - saldoTasseLordo).clamp(0.0, double.infinity);
      final double totaleIncassatoNetto = pivaNettaAnno + stipendioNettoAnno + extraNettoAnno;
      final double risparmioNetto = totaleIncassatoNetto - totSpesoAnno;

      return {
        'annoNum': anno,
        'anno': anno == ora.year + 1 ? '$anno (Previsione)' : '$anno',
        'pivaLorda': pivaLordaAnno,
        'pivaNetta': pivaNettaAnno,
        'stipendioNetto': stipendioNettoAnno,
        'extraNetto': extraNettoAnno,
        'totaleIncassatoNetto': totaleIncassatoNetto,
        'incassato': totaleIncassatoNetto,
        'speso': totSpesoAnno,
        'saldoTasseLordo': saldoTasseLordo,
        'accontiGiaVersati': accontiGiaVersati,
        'saldoTasse': saldoTasseNetto,
        'accontiF24ProssimoAnno': accontiAnnoSuccessivo,
        'totaleF24Accantonare': totaleF24Accantonare,
        'risparmioNetto': risparmioNetto,
        'bgImage': immagini[i % immagini.length],
        'storicoMesi': storicoMesi,
      };
    }).toList();
  }

  void _apriUpgradePro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProUpgradeSheet(
          funzionalita: 'Panoramica Annuale e Previsioni F24',
        ),
      ),
    );
  }

  // 📊 MODALE REPORT SINTESI ANNUALE CON DETTAGLIO FISCALE & ACCONTI F24
  void _mostraReportAnalitico(Map<String, dynamic> annoData) {
    final wallet = context.read<WalletProvider>();
    final int annoNum = annoData['annoNum'] as int;
    final int prossimoAnno = annoNum + 1;
    final int annoPrec = annoNum - 1;

    // Label dinamica legata all'Onboarding
    final String etichettaEntrataFissa = wallet.hasPensione ? 'Pensione' : 'Stipendio';

    final double pivaLorda = (annoData['pivaLorda'] as num?)?.toDouble() ?? 0.0;
    final double pivaNetta = (annoData['pivaNetta'] as num?)?.toDouble() ?? 0.0;
    final double stipendioNetto = (annoData['stipendioNetto'] as num?)?.toDouble() ?? 0.0;
    final double extraNetto = (annoData['extraNetto'] as num?)?.toDouble() ?? 0.0;
    final double totaleIncassatoNetto = (annoData['totaleIncassatoNetto'] as num?)?.toDouble() ?? 0.0;

    final double saldoTasse = (annoData['saldoTasse'] as num?)?.toDouble() ?? 0.0;
    final double saldoTasseLordo = (annoData['saldoTasseLordo'] as num?)?.toDouble() ?? saldoTasse;
    final double accontiGiaVersati = (annoData['accontiGiaVersati'] as num?)?.toDouble() ?? 0.0;
    final double accontiF24 = (annoData['accontiF24ProssimoAnno'] as num?)?.toDouble() ?? 0.0;
    final double totaleF24 = (annoData['totaleF24Accantonare'] as num?)?.toDouble() ?? 0.0;

    final double speso = (annoData['speso'] as num?)?.toDouble() ?? 0.0;
    final double risparmioNetto = (annoData['risparmioNetto'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: oceanCyan.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.stars_rounded, color: oceanCyan, size: 26),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Sintesi Fiscale & Bilancio ${annoData['anno']}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // 🟢 1. ENTRATE NETTE & COMPOSIZIONE DETTAGLIATA
                const Text('INCASSI & ENTRATE NETTE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _buildReportRow('TOTALE ENTRATE NETTE:', _formattaValutaDecimale(totaleIncassatoNetto), greenProfit, isBold: true),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      if (wallet.isPartitaIVA) ...[
                        _buildReportRow('Fatturato P.IVA (Lordo):', _formattaValutaDecimale(pivaLorda), Colors.white70),
                        const SizedBox(height: 4),
                        _buildReportRow('Fatturato P.IVA (Netto):', _formattaValutaDecimale(pivaNetta), greenProfit),
                        const SizedBox(height: 4),
                      ],
                      _buildReportRow('$etichettaEntrataFissa (Netto):', _formattaValutaDecimale(stipendioNetto), greenProfit),
                      if (extraNetto > 0) ...[
                        const SizedBox(height: 4),
                        _buildReportRow('Entrate Extra / Altro:', _formattaValutaDecimale(extraNetto), greenProfit),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🛡️ 2. SCHEMINO F24 (TOTALE + DETTAGLIO ACCONTI & SALDO) - SOLO SE P.IVA
                if (wallet.isPartitaIVA) ...[
                  const Text('IMPOSTE & PREVISIONE ACCONTI F24', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  _buildReportRow('TOTALE F24 DA ACCANTONARE:', '-${_formattaValutaDecimale(totaleF24)}', taxBlue, isBold: true),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: taxBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: taxBlue.withOpacity(0.35)),
                    ),
                    child: Column(
                      children: [
                        if (accontiGiaVersati > 0) ...[
                          _buildReportRow('(-) Acconti Versati $annoPrec:', '+${_formattaValutaDecimale(accontiGiaVersati)}', greenProfit),
                          const SizedBox(height: 4),
                        ],
                        _buildReportRow('Saldo Tasse $annoNum:', '-${_formattaValutaDecimale(saldoTasse)}', goldAccent),
                        const SizedBox(height: 4),
                        _buildReportRow('(+) Acconto Tasse $prossimoAnno:', '-${_formattaValutaDecimale(accontiF24)}', const Color(0xFFF97316)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 💰 3. SPESE E RISPARMIO NETTO
                const Text('BILANCIO & RISPARMIO REALE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _buildReportRow('TOTALE USCITE / SPESE:', '-${_formattaValutaDecimale(speso)}', alertRed, isBold: true),
                const Divider(color: Colors.white10, height: 16),
                _buildReportRow('RISPARMIO NETTO REALE:', _formattaValutaDecimale(risparmioNetto), risparmioNetto >= 0 ? purpleZen : alertRed, isBold: true),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Chiudi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔍 MODALE DETTAGLIO MESE PER MESE SU TAP
  void _mostraDettaglioMese(BuildContext context, WalletProvider wallet, Map<String, dynamic> meseData) {
    final int anno = meseData['anno'] as int;
    final int meseIdx = meseData['meseIdx'] as int;
    final String nomeMese = meseData['mese'] as String;

    final txsMese = wallet.transactions.where((t) => t.date.year == anno && t.date.month == meseIdx && !t.id.startsWith('rule_')).toList();
    txsMese.sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder: (ctx) => AppSecondaryPopup(
        backgroundColor: const Color(0xFF18181B),
        icon: Icons.calendar_month_rounded,
        iconColor: oceanCyan,
        titolo: 'Plancia Mese: $nomeMese $anno',
        testoAnnulla: 'Chiudi',
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 RIEPILOGO MESE
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    if ((meseData['pivaLorda'] as double) > 0) ...[
                      _buildReportRow('Fatturato P.IVA (Lordo):', _formattaValutaDecimale(meseData['pivaLorda']), Colors.white70),
                      const SizedBox(height: 4),
                      _buildReportRow('Fatturato P.IVA (Netto):', _formattaValutaDecimale(meseData['pivaNetta']), greenProfit, isBold: true),
                      const SizedBox(height: 4),
                    ],
                    if ((meseData['stipendioNetto'] as double) > 0) ...[
                      _buildReportRow('Stipendio / Pensione:', _formattaValutaDecimale(meseData['stipendioNetto']), greenProfit),
                      const SizedBox(height: 4),
                    ],
                    // 💡 MOSTRA LA RIGA DEL CUSCINETTO PULITA IN TUTTI I MESI (SENZA SEGNO SE ZERO)
                    Builder(
                      builder: (context) {
                        final bool isOFF = meseData['isMeseOFF'] == true;
                        final double valErogato = (meseData['erogazioneCuscinetto'] as num?)?.toDouble() ?? 0.0;
                        final double valAccantonato = (meseData['quotaCuscinetto'] as num?)?.toDouble() ?? 0.0;
                        final double valoreReale = isOFF ? valErogato : valAccantonato;

                        String testoValuta;
                        if (valoreReale.abs() < 0.01) {
                          testoValuta = '0 €';
                        } else if (isOFF) {
                          testoValuta = '+${_formattaValuta(valoreReale.abs())}';
                        } else {
                          testoValuta = '-${_formattaValuta(valoreReale.abs())}';
                        }

                        final String etichettaDesc = isOFF 
                            ? 'Integrazione Cuscinetto Ferie:' 
                            : 'Accantonamento Cuscinetto Ferie:';

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildReportRow(etichettaDesc, testoValuta, purpleZen),
                            const SizedBox(height: 4),
                          ],
                        );
                      },
                    ),
                    _buildReportRow('Uscite Sostenute:', '-${_formattaValutaDecimale(meseData['speso'])}', alertRed),
                    const Divider(color: Colors.white10, height: 12),
                    _buildReportRow('Risparmio Mese:', _formattaValutaDecimale((meseData['incassatoTotaleNetto'] as double) - (meseData['speso'] as double)), purpleZen, isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const Text('TRANSAZIONI REGISTRATE NEL MESE', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              const SizedBox(height: 8),

              if (txsMese.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Nessuna transazione registrata in questo mese.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
                )
              else
                Column(
                  children: txsMese.map((tx) {
                    final Color colorTx = tx.isIncome ? greenProfit : alertRed;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text('${tx.category} • ${tx.date.day}/${tx.date.month}', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.isIncome ? '+' : '-'}${_formattaValutaDecimale(tx.amount)}',
                            style: TextStyle(color: colorTx, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildListaTransazioniSub(List<dynamic> txs) {
    if (txs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        children: txs.map((tx) {
          final Color colorTx = tx.isIncome ? greenProfit : alertRed;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.02)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('${tx.category} • ${tx.date.day}/${tx.date.month}', style: const TextStyle(color: Colors.white38, fontSize: 8)),
                    ],
                  ),
                ),
                Text(
                  '${tx.isIncome ? '+' : '-'}${_formattaValutaDecimale(tx.amount)}',
                  style: TextStyle(color: colorTx, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final bool isUserPro = walletProvider.isProUser;

    final List<Map<String, dynamic>> anniInUso = _calcolaDatiReali(walletProvider);

    final currentAnno = anniInUso[_selectedYearIndex.clamp(0, anniInUso.length - 1)];
    final List<Map<String, dynamic>> storicoMesiInUso = List<Map<String, dynamic>>.from(currentAnno['storicoMesi']);

    final double maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ➖ BARRETTA TRASCINAMENTO & HEADER
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 14),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Center(
              child: Text(
                'Panoramica Annuale',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            

            // 1. CAROSELLO HERO CARD PER ANNO
            SizedBox(
              height: 410,
              child: PageView.builder(
                controller: _pageController,
                itemCount: anniInUso.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedYearIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = anniInUso[index];
                  final bool isSelected = index == _selectedYearIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: isSelected ? 0 : 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      image: DecorationImage(
                        image: NetworkImage(item['bgImage']),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 6),

                          Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formattaValuta(item['risparmioNetto']),
                                  style: TextStyle(
                                    color: (item['risparmioNetto'] as double) >= 0 ? Colors.white : alertRed,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Risparmio Netto Accumulato', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  'Anno ${item['anno']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),

                          GestureDetector(
                            onTap: () {
                              if (!isUserPro) {
                                _apriUpgradePro(context);
                              } else {
                                _mostraReportAnalitico(item);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C21).withOpacity(0.88),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.arrow_upward_rounded, color: greenProfit, size: 18),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Netto Incassato', 
                                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '+${_formattaValuta(item['totaleIncassatoNetto'])}', 
                                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '-${_formattaValuta(item['speso'])}',
                                        style: TextStyle(color: alertRed, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isUserPro ? 'Vedi dettagli dell\'anno & F24' : '🔒 Richiede PRO',
                                        style: TextStyle(
                                          color: isUserPro ? oceanCyan : goldAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: isUserPro ? oceanCyan : goldAccent,
                                        size: 11,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 🚀 SEZIONE SBLOCCO PRO (STILE PIANIFICAZIONE STRATEGICA)
            if (!isUserPro) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            'Anteprima Simulata - PRO',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _apriUpgradePro(context),
                        icon: const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
                        label: const Text(
                          'Sblocca Panoramica Reale',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 2. GRAFICO DEL BUDGET OBIETTIVO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Andamento Entrate vs Uscite', 
                            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            _buildLegendaItem('Entrate', greenProfit),
                            const SizedBox(width: 8),
                            _buildLegendaItem('Uscite', oceanCyan),
                            const SizedBox(width: 8),
                            _buildLegendaItem('Pianificato', Colors.white38),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: greenProfit.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: greenProfit.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Entrate: +${_formattaValuta(currentAnno['incassato'])}',
                            style: TextStyle(color: greenProfit, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: oceanCyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: oceanCyan.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Uscite: -${_formattaValuta(currentAnno['speso'])}',
                            style: TextStyle(color: oceanCyan, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.insights_rounded, color: oceanCyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Risparmio Cumulato: ${_formattaValuta((currentAnno['incassato'] as double) - (currentAnno['speso'] as double))}',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    GestureDetector(
                      onTapUp: (details) {
                        final double localX = details.localPosition.dx;
                        final double totalWidth = MediaQuery.of(context).size.width - 76; // Larghezza netta dell'area di disegno
                        final double stepX = totalWidth / (storicoMesiInUso.length == 1 ? 1 : storicoMesiInUso.length - 1);
                        final int touchedIdx = (localX / stepX).round().clamp(0, storicoMesiInUso.length - 1);

                        setState(() {
                          _selectedGraphMonthIndex = (_selectedGraphMonthIndex == touchedIdx) ? null : touchedIdx;
                        });
                      },
                      child: SizedBox(
                        height: 110,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _FuturisticTrendPainter(
                            datiMesi: storicoMesiInUso,
                            selectedIndex: _selectedGraphMonthIndex,
                          ),
                        ),
                      ),
                    ),

                    // 🎯 BADGE DETTAGLIO MESE TOCCATO SUL GRAFICO
                    if (_selectedGraphMonthIndex != null && _selectedGraphMonthIndex! < storicoMesiInUso.length) ...[
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final mGraph = storicoMesiInUso[_selectedGraphMonthIndex!];
                          final bool isPass = mGraph['isPassato'] == true;
                          final double inM = (mGraph['incassatoTotaleNetto'] as num?)?.toDouble() ?? 0.0;
                          final double outM = (mGraph['speso'] as num?)?.toDouble() ?? 0.0;
                          final double diffM = inM - outM;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: oceanCyan.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dettaglio ${mGraph['mese']} ${mGraph['anno']}:',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Entrate: +${_formattaValuta(inM)}',
                                      style: TextStyle(color: greenProfit, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Uscite: -${_formattaValuta(outM)}',
                                      style: TextStyle(color: alertRed, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. STORICO MESI PER MESE (CLICCABILI)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STORICO MESE PER MESE (${currentAnno['anno']})',
                    style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const Text('Tocca per dettaglio', style: TextStyle(color: Colors.white38, fontSize: 9, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: storicoMesiInUso.length,
              itemBuilder: (context, index) {
                final m = storicoMesiInUso[index];
                final bool isPassato = m['isPassato'] == true;
                final double incassatoMese = (m['incassatoTotaleNetto'] as num?)?.toDouble() ?? 0.0;
                final double spesoMese = (m['speso'] as num?)?.toDouble() ?? 0.0;
                final double delta = incassatoMese - spesoMese;
                final bool isVirtuoso = delta >= 0;
                final bool isEspanso = _expandedMeseIdx == index;

                final int annoMese = m['anno'] as int;
                final int idxMese = m['meseIdx'] as int;
                final txsMese = walletProvider.transactions
                    .where((t) => t.date.year == annoMese && t.date.month == idxMese && !t.id.startsWith('rule_'))
                    .toList();
                txsMese.sort((a, b) => b.date.compareTo(a.date));

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isEspanso ? oceanCyan.withOpacity(0.5) : Colors.white.withOpacity(0.06),
                      width: isEspanso ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          if (!isUserPro) {
                            _apriUpgradePro(context);
                          } else {
                            setState(() {
                              _expandedMeseIdx = isEspanso ? null : index;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPassato
                                      ? (isVirtuoso ? greenProfit.withOpacity(0.12) : alertRed.withOpacity(0.12))
                                      : Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPassato
                                      ? (isVirtuoso ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded)
                                      : Icons.schedule_rounded,
                                  color: isPassato
                                      ? (isVirtuoso ? greenProfit : alertRed)
                                      : Colors.white38,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(m['mese'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        if (!isPassato) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('Previsto', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isPassato
                                          ? 'In: +${_formattaValuta(incassatoMese)} • Out: -${_formattaValuta(spesoMese)}'
                                          : 'Budget Stimato: ${_formattaValuta(m['budget'])}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Text(
                                    isPassato
                                        ? '${isVirtuoso ? '+' : ''}${_formattaValuta(delta)}'
                                        : _formattaValuta(m['speso']),
                                    style: TextStyle(
                                      color: isPassato
                                          ? (isVirtuoso ? oceanCyan : alertRed)
                                          : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isEspanso ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: isEspanso ? oceanCyan : Colors.white24,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 📂 TENDINA MULTI-VISTA (BUSSOLA / CATEGORIE / MOVIMENTI)
                      if (isEspanso) ...[
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        
                        // 🔘 TAB SELECTOR
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: Row(
                            children: ['Bussola', 'Categorie', 'Movimenti'].map((mode) {
                              final String currentView = _meseViewMode[index] ?? 'Bussola';
                              final bool isSel = currentView == mode;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _meseViewMode[index] = mode;
                                    _expandedSubKey = null; // Resetta sotto-tendina al cambio tab
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: isSel ? Colors.white.withOpacity(0.12) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isSel ? Colors.white.withOpacity(0.2) : Colors.transparent),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      mode,
                                      style: TextStyle(
                                        color: isSel ? Colors.white : Colors.white54,
                                        fontSize: 10,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // 📄 CONTENUTO DELLA VISTA SELEZIONATA
                        Container(
                          padding: const EdgeInsets.all(14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                          ),
                          child: Builder(
                            builder: (context) {
                              final String currentView = _meseViewMode[index] ?? 'Bussola';

                              // 🧭 VISTA 1: BUSSOLA (Espandibile per macrocategorie 50/30/20)
                              if (currentView == 'Bussola') {
                                final entrateTxs = txsMese.where((t) => t.isIncome).toList();
                                final usciteTxs = txsMese.where((t) => !t.isIncome).toList();

                                final fisseTxs = <dynamic>[];
                                final variabiliTxs = <dynamic>[];
                                final risparmioTxs = <dynamic>[];

                                for (var tx in usciteTxs) {
                                  final bussolaRule = walletProvider.ottieniBussolaSemplificata(tx);
                                  if (bussolaRule == 'Risparmi') {
                                    risparmioTxs.add(tx);
                                  } else if (bussolaRule == 'Bisogni') {
                                    fisseTxs.add(tx);
                                  } else {
                                    variabiliTxs.add(tx);
                                  }
                                }

                                final double totEntrate = entrateTxs.fold(0.0, (s, t) => s + t.amount);
                                final double totFisse = fisseTxs.fold(0.0, (s, t) => s + t.amount);
                                final double totVariabili = variabiliTxs.fold(0.0, (s, t) => s + t.amount);
                                final double totRisparmio = risparmioTxs.fold(0.0, (s, t) => s + t.amount);

                                final List<Map<String, dynamic>> gruppiBussola = [
                                  if (entrateTxs.isNotEmpty || totEntrate > 0)
                                    {'key': 'entrate', 'title': 'Entrate', 'total': totEntrate, 'txs': entrateTxs, 'color': greenProfit, 'sign': '+'},
                                  {'key': 'fisse', 'title': '50% Spese Fisse', 'total': totFisse, 'txs': fisseTxs, 'color': alertRed, 'sign': '-'},
                                  {'key': 'variabili', 'title': '30% Spese Variabili', 'total': totVariabili, 'txs': variabiliTxs, 'color': alertRed, 'sign': '-'},
                                  if (risparmioTxs.isNotEmpty)
                                    {'key': 'risparmio', 'title': '20% Risparmio / Accantonamenti', 'total': totRisparmio, 'txs': risparmioTxs, 'color': purpleZen, 'sign': '-'},
                                ];

                                return Column(
                                  children: gruppiBussola.map((grp) {
                                    final String subKey = '${annoMese}_${idxMese}_bussola_${grp['key']}';
                                    final bool isOpen = _expandedSubKey == subKey;
                                    final List txsGrp = grp['txs'] as List;

                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: txsGrp.isEmpty ? null : () {
                                            setState(() {
                                              _expandedSubKey = isOpen ? null : subKey;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isOpen ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                                                      color: txsGrp.isNotEmpty ? Colors.white54 : Colors.white12,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(grp['title'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                                Text(
                                                  '${grp['sign']}${_formattaValutaDecimale(grp['total'])}',
                                                  style: TextStyle(color: grp['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isOpen) _buildListaTransazioniSub(txsGrp),
                                        const Divider(color: Colors.white10, height: 1),
                                      ],
                                    );
                                  }).toList(),
                                );
                              }

                              // 🥧 VISTA 2: CATEGORIE (Raggruppate per Macro-categoria Padre)
                              if (currentView == 'Categorie') {
                                final Map<String, Map<String, dynamic>> catMap = {};

                                for (var tx in txsMese.where((t) => !t.isIncome)) {
                                  final String name = walletProvider.ottieniCategoriaPadre(tx.category, isIncome: tx.isIncome);

                                  if (!catMap.containsKey(name)) {
                                    catMap[name] = {
                                      'name': name,
                                      'total': 0.0,
                                      'txs': <dynamic>[],
                                    };
                                  }
                                  catMap[name]!['total'] = (catMap[name]!['total'] as double) + tx.amount;
                                  (catMap[name]!['txs'] as List).add(tx);
                                }

                                if (catMap.isEmpty) {
                                  return const Center(child: Text('Nessuna uscita registrata in questo mese.', style: TextStyle(color: Colors.white38, fontSize: 11)));
                                }

                                final sortedCats = catMap.values.toList()
                                  ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

                                return Column(
                                  children: sortedCats.map((cat) {
                                    final String name = cat['name'] as String;
                                    final double tot = cat['total'] as double;
                                    final List catTxs = cat['txs'] as List;
                                    final String subKey = '${annoMese}_${idxMese}_cat_$name';
                                    final bool isOpen = _expandedSubKey == subKey;

                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _expandedSubKey = isOpen ? null : subKey;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(10),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isOpen ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                                                      color: Colors.white54,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                                Text('-${_formattaValutaDecimale(tot)}', style: TextStyle(color: alertRed, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isOpen) _buildListaTransazioniSub(catTxs),
                                        const Divider(color: Colors.white10, height: 1),
                                      ],
                                    );
                                  }).toList(),
                                );
                              }

                              // 📜 VISTA 3: MOVIMENTI (Lista diretta transazioni)
                              if (txsMese.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: Text('Nessuna transazione registrata.', style: TextStyle(color: Colors.white38, fontSize: 11))),
                                );
                              }
                              return _buildListaTransazioniSub(txsMese);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _FuturisticTrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> datiMesi;
  final int? selectedIndex;

  _FuturisticTrendPainter({required this.datiMesi, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (datiMesi.isEmpty) return;

    final double heightGraph = size.height - 22;
    final double stepX = size.width / (datiMesi.length == 1 ? 1 : datiMesi.length - 1);

    // Calcolo del picco massimo per scalare il grafico correttamente
    double maxVal = 1000.0;
    for (var m in datiMesi) {
      final double inVal = (m['incassatoTotaleNetto'] as num?)?.toDouble() ?? 0.0;
      final double outVal = (m['speso'] as num?)?.toDouble() ?? 0.0;
      if (inVal > maxVal) maxVal = inVal;
      if (outVal > maxVal) maxVal = outVal;
    }
    maxVal *= 1.15; // Margine superiore del 15%

    List<Offset> entrateReali = [];
    List<Offset> entratePianificate = [];
    List<Offset> usciteReali = [];
    List<Offset> uscitePianificate = [];

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < datiMesi.length; i++) {
      final double x = i * stepX;
      final double inVal = (datiMesi[i]['incassatoTotaleNetto'] as num?)?.toDouble() ?? 0.0;
      final double outVal = (datiMesi[i]['speso'] as num?)?.toDouble() ?? 0.0;
      final bool isPassato = datiMesi[i]['isPassato'] == true;

      final double yIn = heightGraph - ((inVal / maxVal) * heightGraph).clamp(0.0, heightGraph);
      final double yOut = heightGraph - ((outVal / maxVal) * heightGraph).clamp(0.0, heightGraph);

      final offsetIn = Offset(x, yIn);
      final offsetOut = Offset(x, yOut);

      if (isPassato) {
        entrateReali.add(offsetIn);
        usciteReali.add(offsetOut);
      } else {
        if (entrateReali.isNotEmpty && entratePianificate.isEmpty) {
          entratePianificate.add(entrateReali.last);
        }
        if (usciteReali.isNotEmpty && uscitePianificate.isEmpty) {
          uscitePianificate.add(usciteReali.last);
        }
        entratePianificate.add(offsetIn);
        uscitePianificate.add(offsetOut);
      }

      final bool isSelected = selectedIndex == i;

      if (isSelected) {
        final paintHighlight = Paint()..color = const Color(0xFF38BDF8);
        canvas.drawCircle(offsetOut, 4, paintHighlight);
        canvas.drawCircle(offsetIn, 4, Paint()..color = const Color(0xFF10B981));
      }

      textPainter.text = TextSpan(
        text: datiMesi[i]['mese'],
        style: TextStyle(
          color: isSelected ? const Color(0xFF38BDF8) : (isPassato ? Colors.white70 : Colors.white24),
          fontSize: 9,
          fontWeight: (isPassato || isSelected) ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2).clamp(0, x), heightGraph + 6));
    }

    // 🟢 1. TRACCIAMENTO ENTRATE (Verde)
    if (entrateReali.length >= 2) {
      final pathInReale = _creaPathMorbido(entrateReali);
      final paintInReale = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(pathInReale, paintInReale);
    }
    if (entratePianificate.length >= 2) {
      final pathInPianificato = _creaPathMorbido(entratePianificate);
      final paintInPianificato = Paint()
        ..color = const Color(0xFF10B981).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      _disegnaLineaTratteggiata(canvas, pathInPianificato, paintInPianificato);
    }

    // 🔵 2. TRACCIAMENTO USCITE (Azzurro)
    if (usciteReali.length >= 2) {
      final pathOutReale = _creaPathMorbido(usciteReali);

      final pathFillOut = Path.from(pathOutReale)
        ..lineTo(usciteReali.last.dx, heightGraph)
        ..lineTo(usciteReali.first.dx, heightGraph)
        ..close();

      final paintGradientOut = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF38BDF8).withOpacity(0.25),
            const Color(0xFF38BDF8).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, heightGraph));

      canvas.drawPath(pathFillOut, paintGradientOut);

      final paintOutReale = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(pathOutReale, paintOutReale);
    }
    if (uscitePianificate.length >= 2) {
      final pathOutPianificato = _creaPathMorbido(uscitePianificate);
      final paintOutPianificato = Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      _disegnaLineaTratteggiata(canvas, pathOutPianificato, paintOutPianificato);
    }
  }

  Path _creaPathMorbido(List<Offset> punti) {
    final path = Path();
    if (punti.isEmpty) return path;

    path.moveTo(punti[0].dx, punti[0].dy);

    for (int i = 0; i < punti.length - 1; i++) {
      final p0 = punti[i];
      final p1 = punti[i + 1];

      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    return path;
  }

  void _disegnaLineaTratteggiata(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      const double dashWidth = 5.0;
      const double dashSpace = 4.0;

      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}