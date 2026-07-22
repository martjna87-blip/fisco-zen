import 'package:flutter/material.dart';
import '../widgets_shared/fluid_wave_painter.dart';
import '2_wallet_screen.dart';
import '3_home_PI_screen.dart';
import 'main_dashboard_wrapper.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin {
  String? tipoProfilo; // 'piva' oppure 'dipendente'

  String? aliquotaTasse;
  double? coefficienteRedditivita;
  String? codiceAtecoSelezionato;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _waveController;

  final List<Map<String, dynamic>> _databaseAteco = [
    {'codice': '85.52.09', 'descrizione': 'Altra formazione culturale (corsi di lingua, musica, danza, pittura, formazione privata)', 'coef': 0.78},
    {'codice': '85.59.20', 'descrizione': 'Corsi di formazione e di aggiornamento professionale', 'coef': 0.78},
    {'codice': '85.51.00', 'descrizione': 'Corsi sportivi e ricreativi (yoga, arti marziali, nuoto)', 'coef': 0.78},
    {'codice': '85.52.01', 'descrizione': 'Corsi di danza e scuole di ballo', 'coef': 0.78},
    {'codice': '85.59.90', 'descrizione': 'Altri servizi di istruzione e docenza privata', 'coef': 0.78},
    {'codice': '62.01.00', 'descrizione': 'Sviluppo di software e programmazione', 'coef': 0.78},
    {'codice': '62.02.00', 'descrizione': 'Consulenza nel settore delle tecnologie dell\'informatica', 'coef': 0.78},
    {'codice': '70.22.09', 'descrizione': 'Consulenza imprenditoriale e gestionale', 'coef': 0.78},
    {'codice': '73.11.02', 'descrizione': 'Conduzione campagne di marketing, Social Media e Advertising', 'coef': 0.78},
    {'codice': '74.10.21', 'descrizione': 'Graphic design, Web design, UI/UX e Illustrazione', 'coef': 0.78},
    {'codice': '86.90.30', 'descrizione': 'Attività di psicologi e psicoterapeuti', 'coef': 0.78},
    {'codice': '74.30.00', 'descrizione': 'Traduzione e interpretariato', 'coef': 0.78},
    {'codice': '71.11.00', 'descrizione': 'Attività degli studi di architettura', 'coef': 0.78},
    {'codice': '71.12.10', 'descrizione': 'Attività degli studi di ingegneria', 'coef': 0.78},
    {'codice': '47.91.10', 'descrizione': 'Commercio al dettaglio via internet (E-commerce)', 'coef': 0.67},
    {'codice': '46.19.01', 'descrizione': 'Agenti e rappresentanti di vari prodotti', 'coef': 0.67},
    {'codice': '56.10.11', 'descrizione': 'Ristoranti, Pizzerie con somministrazione', 'coef': 0.40},
    {'codice': '56.30.00', 'descrizione': 'Bar, gelaterie e pasticcerie', 'coef': 0.40},
    {'codice': '96.02.01', 'descrizione': 'Servizi dei saloni di barbiere e parrucchiere', 'coef': 0.40},
    {'codice': '96.02.02', 'descrizione': 'Servizi degli istituti di bellezza ed estetisti', 'coef': 0.40},
    {'codice': '68.31.00', 'descrizione': 'Attività delle agenzie immobiliari', 'coef': 0.86},
    {'codice': '81.21.00', 'descrizione': 'Pulizia generale di edifici e uffici', 'coef': 0.62},
    {'codice': '47.21.00', 'descrizione': 'Commercio al dettaglio di frutta e verdura', 'coef': 0.54},
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atecoFiltrati = _databaseAteco.where((item) {
      final query = _searchQuery.toLowerCase().replaceAll('.', '').trim();
      final codiceClean = item['codice'].toString().toLowerCase().replaceAll('.', '');
      final desc = item['descrizione'].toString().toLowerCase();
      return codiceClean.contains(query) || desc.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080B0C),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: FluidWavePainter(animationValue: _waveController.value),
                );
              },
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  children: [
                    // LOGO E TITOLO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Fisco Zen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Qual è il tuo profilo lavorativo?',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // SELETTORE PROFILO PRINCIPALE
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfileCard(
                            id: 'piva',
                            icon: Icons.badge_rounded,
                            title: 'Partita IVA',
                            subtitle: 'Forfettario & Freelance',
                            activeColor: const Color(0xFF0D9488),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProfileCard(
                            id: 'dipendente',
                            icon: Icons.work_rounded,
                            title: 'Dipendente',
                            subtitle: 'Lavoratore / Privato',
                            activeColor: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 1️⃣ SEZIONE PER PARTITA IVA
                    if (tipoProfilo == 'piva') ...[
                      const Divider(color: Color(0xFF1F2937), height: 32),
                      const Text(
                        'Da quanto tempo hai aperto la Partita IVA?',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildHeaderQuickAction(
                            icon: Icons.eco,
                            label: 'Startup (5%)',
                            subtitle: 'Meno di 5 anni',
                            isSelected: aliquotaTasse == '5%',
                            onTap: () => setState(() => aliquotaTasse = '5%'),
                          ),
                          _buildHeaderQuickAction(
                            icon: Icons.work_outline_rounded,
                            label: 'Standard (15%)',
                            subtitle: 'Più di 5 anni',
                            isSelected: aliquotaTasse == '15%',
                            onTap: () => setState(() => aliquotaTasse = '15%'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (aliquotaTasse != null) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
                            child: Text(
                              'CERCA O SELEZIONA CODICE ATECO',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101618).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _searchQuery.isNotEmpty ? const Color(0xFF2DD4BF) : const Color(0xFF1F2937),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              icon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                              hintText: 'Cerca per codice (es. 855209) o professione...',
                              hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                              border: InputBorder.none,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                                      onPressed: () => setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      }),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF101618).withOpacity(0.88),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF1F2937)),
                          ),
                          child: _searchQuery.isNotEmpty
                              ? (atecoFiltrati.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Center(
                                        child: Text(
                                          'Nessun codice trovato.',
                                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: atecoFiltrati.length,
                                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF1F2937), indent: 16),
                                      itemBuilder: (context, index) {
                                        final item = atecoFiltrati[index];
                                        final isSelected = codiceAtecoSelezionato == item['codice'];
                                        final double coef = (item['coef'] as num).toDouble();
                                        return ListTile(
                                          onTap: () => setState(() {
                                            coefficienteRedditivita = coef;
                                            codiceAtecoSelezionato = '${item['codice']} - ${item['descrizione']}';
                                          }),
                                          title: Row(
                                            children: [
                                              Text(
                                                item['codice'],
                                                style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1F2937),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${(coef * 100).toInt()}%',
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            item['descrizione'],
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 20) : null,
                                        );
                                      },
                                    ))
                              : Column(
                                  children: [
                                    _buildRevolutListTile(
                                      icon: Icons.laptop_mac_rounded,
                                      title: 'Consulenza & Digital (78%)',
                                      subtitle: 'Freelance, IT, Marketing, Formazione, Psicologi',
                                      isSelected: coefficienteRedditivita == 0.78,
                                      onTap: () => setState(() {
                                        coefficienteRedditivita = 0.78;
                                        codiceAtecoSelezionato = '74.10.21 - Consulenza & Digital';
                                      }),
                                    ),
                                    const Divider(height: 1, color: Color(0xFF1F2937), indent: 64),
                                    _buildRevolutListTile(
                                      icon: Icons.storefront_rounded,
                                      title: 'Commercio & Agenti (67%)',
                                      subtitle: 'E-commerce, Negozi, Intermediazione',
                                      isSelected: coefficienteRedditivita == 0.67,
                                      onTap: () => setState(() {
                                        coefficienteRedditivita = 0.67;
                                        codiceAtecoSelezionato = '47.91.10 - Commercio & Agenti';
                                      }),
                                    ),
                                    const Divider(height: 1, color: Color(0xFF1F2937), indent: 64),
                                    _buildRevolutListTile(
                                      icon: Icons.build_rounded,
                                      title: 'Artigiani & Ristorazione (40%)',
                                      subtitle: 'Produzione, Bar, Ristoranti, Estetisti',
                                      isSelected: coefficienteRedditivita == 0.40,
                                      onTap: () => setState(() {
                                        coefficienteRedditivita = 0.40;
                                        codiceAtecoSelezionato = '56.10.11 - Artigiani & Ristorazione';
                                      }),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),

                        // BOTTONE CHE PASSA LE SCELTE ALLA HOME
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: coefficienteRedditivita == null
                                ? null
                                : () {
                                    final double imposta = aliquotaTasse == '5%' ? 0.05 : 0.15;
                                    final String atecoStr = codiceAtecoSelezionato ??
                                        (coefficienteRedditivita == 0.78
                                            ? '74.10.21 - Consulenza & Digital'
                                            : coefficienteRedditivita == 0.67
                                                ? '47.91.10 - Commercio & Agenti'
                                                : '56.10.11 - Artigiani & Ristorazione');

                                    // NUOVO NAVIGATOR PER PARTITA IVA
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainDashboardWrapper(
                                          hasPartitaIva: true, // Attiva il carosello!
                                          codiceAtecoIniziale: atecoStr,
                                          coefficienteIniziale: coefficienteRedditivita,
                                          aliquotaImpostaIniziale: imposta,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: const Color(0xFF1F2937),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],

                    // 2️⃣ SEZIONE PER DIPENDENTE
                    if (tipoProfilo == 'dipendente') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            // NUOVO NAVIGATOR PER DIPENDENTE
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainDashboardWrapper(
                                  hasPartitaIva: false, // Disattiva il carosello, mostra solo il Wallet!
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Dashboard Dipendente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color activeColor,
  }) {
    final bool isSelected = tipoProfilo == id;
    return GestureDetector(
      onTap: () => setState(() => tipoProfilo = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : const Color(0xFF101618),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF1F2937),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderQuickAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.white : const Color(0xFF101618),
              border: Border.all(
                color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF1F2937),
                width: 2,
              ),
            ),
            child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRevolutListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF1F2937),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2DD4BF) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 18),
          ],
        ),
      ),
    );
  }
}