// 📍 INIZIO CODICE COMPLETO: lib/screens/0_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:image_picker/image_picker.dart';
import '../data/auth_provider.dart';
import '../data/wallet_provider.dart';
import '../main.dart';
import '0_1_pro_upgrade.dart';
import '0_2_tax_profile.dart';
import '../widgets_shared/app_image_picker.dart';
import '../widgets_shared/app_notifications.dart';
import '../widgets_shared/fluid_wave_painter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _apriLink(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossibile aprire il link web.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Errore apertura URL: $e');
    }
  }

  Future<void> _selezionaFotoProfilo(BuildContext context) async {
    try {
      final XFile? immagine = await AppImagePickerSheet.mostra(
        context,
        titolo: 'Aggiorna Foto Profilo',
      );

      if (immagine != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePhotoURL(immagine.path);
          await user.reload();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto profilo aggiornata con successo!')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Errore caricamento foto: $e');
    }
  }

  Future<void> _confermaEliminazioneAccount(BuildContext context, AuthProvider authProvider) async {
    final confermato = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminare l\'account?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Questa azione è irreversibile. Tutti i tuoi dati salvati verranno cancellati definitivamente.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina definitivamente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confermato == true && context.mounted) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
        await authProvider.signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Per sicurezza, effettua di nuovo il login prima di eliminare l\'account.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Utente FiscON';

    final double topPadding = MediaQuery.of(context).padding.top;
    final double headerHeight = 220 + topPadding;

    const Color coloreSfondo  = Color(0xFF12181B);
    const Color coloreCard    = Color(0xFF1F2428);
    const Color coloreOttanio = Color(0xFF2DD4BF);
    const Color coloreOro     = Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: coloreSfondo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // 🚫 FRECCIA ELIMINATA COMPLETAMENTE
        title: const Text(
          'Profilo & Impostazioni',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            height: headerHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?q=80&w=1000&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
                opacity: 0.45,
              ),
            ),
          ),
          
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  coloreSfondo.withOpacity(0.5),
                  coloreSfondo,
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: coloreCard.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: walletProvider.isProUser 
                            ? coloreOro.withOpacity(0.5) 
                            : Colors.white.withOpacity(0.08),
                        width: walletProvider.isProUser ? 1.5 : 1.0,
                      ),
                      boxShadow: walletProvider.isProUser
                          ? [
                              BoxShadow(
                                color: coloreOro.withOpacity(0.15),
                                blurRadius: 16,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _selezionaFotoProfilo(context),
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: walletProvider.isProUser ? coloreOro : coloreOttanio,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: (walletProvider.isProUser ? coloreOro : coloreOttanio).withOpacity(0.15),
                                  backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                                      ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                                      : null,
                                  child: FirebaseAuth.instance.currentUser?.photoURL == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: walletProvider.isProUser ? coloreOro : coloreOttanio,
                                          size: 30,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: walletProvider.isProUser ? coloreOro : coloreOttanio,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 12,
                                    color: Color(0xFF12181B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (walletProvider.isProUser ? coloreOro : coloreOttanio).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (walletProvider.isProUser ? coloreOro : coloreOttanio).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      walletProvider.isProUser 
                                          ? Icons.workspace_premium_rounded 
                                          : Icons.verified_user_rounded,
                                      color: walletProvider.isProUser ? coloreOro : coloreOttanio,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      walletProvider.isProUser ? 'PRO ACCOUNT' : 'ACCOUNT BASE',
                                      style: TextStyle(
                                        color: walletProvider.isProUser ? coloreOro : coloreOttanio,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildSectionHeader('ABBONAMENTO & FISCO', coloreOttanio),
                  const SizedBox(height: 12),
                  _buildCardGroup([
                    _buildListTile(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: coloreOro,
                      title: walletProvider.isProUser ? 'Piano FiscON PRO Attivo' : 'Passa a FiscON PRO',
                      subtitle: walletProvider.isProUser
                          ? 'Tutte le funzionalità sbloccate'
                          : 'Calcoli avanzati e riserva automatica',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProUpgradeSheet(funzionalita: 'Profilo PRO'),
                          ),
                        );
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                    _buildListTile(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: coloreOttanio,
                      title: 'Profilo Fiscale & ATECO',
                      subtitle: 'ATECO: ${walletProvider.codiceAteco} • Coeff: ${(walletProvider.coeffRedditivita * 100).toInt()}%',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TaxProfileScreen()),
                        );
                      },
                    ),
                  ], coloreCard),

                  const SizedBox(height: 28),

                  _buildSectionHeader('LEGALE & PRIVACY', coloreOttanio),
                  const SizedBox(height: 12),
                  _buildCardGroup([
                    _buildListTile(
                      icon: Icons.shield_outlined,
                      iconColor: coloreOttanio,
                      title: 'Privacy Policy',
                      subtitle: 'Informativa sul trattamento dati',
                      isExternal: true,
                      onTap: () => _apriLink(context, 'https://www.iubenda.com/privacy-policy/94892300'),
                    ),
                    Divider(color: Colors.white.withOpacity(0.06), height: 1, indent: 60),
                    _buildListTile(
                      icon: Icons.description_outlined,
                      iconColor: coloreOttanio,
                      title: 'Termini e Condizioni',
                      subtitle: 'Condizioni generali di servizio',
                      isExternal: true,
                      onTap: () => _apriLink(context, 'https://www.iubenda.com/privacy-policy/94892300/cookie-policy'),
                    ),
                  ], coloreCard),

                  const SizedBox(height: 28),

                  _buildSectionHeader('STRUMENTI DI SVILUPPO', coloreOttanio),
                  const SizedBox(height: 12),
                  _buildCardGroup([
                    _buildListTile(
                      icon: Icons.bug_report_outlined,
                      iconColor: coloreOttanio,
                      title: 'Apri Test Sandbox',
                      subtitle: 'Reset dati, simulatore PRO e test offline',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfiloSandboxScreen()),
                        );
                      },
                    ),
                  ], coloreCard),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: coloreCard,
                      ),
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      label: const Text(
                        'Esci dall\'account',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const SplashScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white38, size: 18),
                      label: const Text(
                        'Elimina account e dati salvati',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () => _confermaEliminazioneAccount(context, authProvider),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children, Color coloreCard) {
    return Container(
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isExternal = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ),
      trailing: Icon(
        isExternal ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
        color: Colors.white38,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}

class ProfiloSandboxScreen extends StatefulWidget {
  const ProfiloSandboxScreen({super.key});

  @override
  State<ProfiloSandboxScreen> createState() => _ProfiloSandboxScreenState();
}

class _ProfiloSandboxScreenState extends State<ProfiloSandboxScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  final Color coloreSfondo = const Color(0xFF080B0C);
  final Color coloreCard = const Color(0xFF101618);
  final Color coloreOttanio = const Color(0xFF2DD4BF);
  final Color coloreRosso = const Color(0xFFEF4444);
  final Color coloreArancio = const Color(0xFFF59E0B);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: coloreSfondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Profilo & Test Sandbox',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(painter: FluidWavePainter(animationValue: _waveController.value));
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Strumenti di controllo per simulare il comportamento dell\'app.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  _buildSandboxCard(
                    icon: Icons.refresh_rounded,
                    iconColor: coloreRosso,
                    title: 'Azzera Conti e Fatture',
                    subtitle: 'Mantiene intatto il tuo profilo ATECO',
                    onTap: () async {
                      await walletProvider.resetSoloMovimentieFatture();
                      if (context.mounted) {
                        AppNotifications.mostraInAlto(
                          context,
                          'Movimenti e fatture azzerati! 🔄',
                          type: NotificationType.success,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildSandboxCard(
                    icon: Icons.restart_alt_rounded,
                    iconColor: coloreArancio,
                    title: 'Reset Totale (Primo Avvio)',
                    subtitle: 'Riavvia il questionario iniziale da zero',
                    onTap: () async {
                      await walletProvider.resetTuttiIDati();
                      if (context.mounted) {
                        AppNotifications.mostraInAlto(
                          context,
                          'Reset completo effettuato! ⚠️',
                          type: NotificationType.warning,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildSandboxCard(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: walletProvider.isProUser ? coloreOttanio : Colors.white54,
                    title: walletProvider.isProUser
                        ? 'Piano Attivo: FiscON PRO 👑'
                        : 'Piano Attivo: FiscON FREE 🔒',
                    subtitle: 'Tocca per passare da Free a Pro per i tuoi test',
                    onTap: () {
                      walletProvider.toggleProUser();
                      AppNotifications.mostraInAlto(
                        context,
                        walletProvider.isProUser
                            ? 'Passato a Piano PRO! 🚀'
                            : 'Passato a Piano FREE 🔒',
                        type: NotificationType.success,
                      );
                    },
                  ),

                  const Spacer(),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: coloreOttanio.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_outlined, color: coloreOttanio, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Versione V5.0 Stabile',
                            style: TextStyle(color: coloreOttanio, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSandboxCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        onTap: onTap,
      ),
    );
  }
}