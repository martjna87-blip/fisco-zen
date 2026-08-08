import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:image_picker/image_picker.dart';

import '../data/auth_provider.dart';
import '../data/wallet_provider.dart';
import '../main.dart';
import '3_4_PI_pro_upgrade.dart';
import '1_main_menu.dart';

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

  // 📸 FUNZIONE CARICAMENTO FOTO PROFILO
  Future<void> _selezionaFotoProfilo(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? immagine = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
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

  // 🗑️ FUNZIONE ELIMINAZIONE ACCOUNT
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

    // 🎨 OPZIONE 3: TITANIO FREDDO & CIANO NEONE (HI-TECH MINIMAL)
    const Color coloreSfondo = Color(0xFF12181B); // Grigio titanio freddo
    const Color coloreCard   = Color(0xFF1F2428); // Ardesia fredda
    const Color coloreCiano  = Color(0xFF06B6D4); // Ciano Neone
    const Color coloreOro    = Color(0xFFF59E0B); // Accent PRO

    return Scaffold(
      backgroundColor: coloreSfondo,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profilo & Impostazioni',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 🖼️ IMMAGINE DI SFONDO
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
          
          // 🌫️ GRADIENTE DI SFUMATURA FREDDA
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

          // 📜 CONTENUTO PRINCIPALE
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 CARD ACCOUNT (DINAMICA PRO / BASE)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: coloreCard.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: walletProvider.isProUser 
                            ? coloreOro 
                            : coloreCiano.withOpacity(0.3),
                        width: walletProvider.isProUser ? 1.5 : 1.0,
                      ),
                      boxShadow: walletProvider.isProUser
                          ? [
                              BoxShadow(
                                color: coloreOro.withOpacity(0.18),
                                blurRadius: 14,
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
                                    color: walletProvider.isProUser ? coloreOro : coloreCiano,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: (walletProvider.isProUser ? coloreOro : coloreCiano).withOpacity(0.15),
                                  backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                                      ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                                      : null,
                                  child: FirebaseAuth.instance.currentUser?.photoURL == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: walletProvider.isProUser ? coloreOro : coloreCiano,
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
                                    color: walletProvider.isProUser ? coloreOro : coloreCiano,
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
                              Row(
                                children: [
                                  if (walletProvider.isProUser) ...[
                                    const Icon(Icons.workspace_premium_rounded, color: coloreOro, size: 15),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    walletProvider.isProUser ? 'PRO ACCOUNT' : 'ACCOUNT BASE',
                                    style: TextStyle(
                                      color: walletProvider.isProUser ? coloreOro : coloreCiano,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
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

                  // 👑 SEZIONE PIANO & FISCO
                  _buildSectionHeader('ABBONAMENTO & FISCO', coloreCiano),
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
                    const Divider(color: Colors.white10, height: 1, indent: 60),
                    _buildListTile(
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: coloreCiano,
                      title: 'Profilo Fiscale & ATECO',
                      subtitle: 'ATECO: ${walletProvider.codiceAteco} • Coeff: ${(walletProvider.coeffRedditivita * 100).toInt()}%',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Modifica profilo fiscale in arrivo!')),
                        );
                      },
                    ),
                  ], coloreCard, coloreCiano),

                  const SizedBox(height: 28),

                  // ⚖️ SEZIONE LEGALE & PRIVACY
                  _buildSectionHeader('LEGALE & PRIVACY', coloreCiano),
                  const SizedBox(height: 12),
                  _buildCardGroup([
                    _buildListTile(
                      icon: Icons.shield_outlined,
                      iconColor: coloreCiano,
                      title: 'Privacy Policy',
                      subtitle: 'Informativa sul trattamento dati',
                      isExternal: true,
                      onTap: () => _apriLink(context, 'https://www.iubenda.com/privacy-policy/94892300'),
                    ),
                    const Divider(color: Colors.white10, height: 1, indent: 60),
                    _buildListTile(
                      icon: Icons.description_outlined,
                      iconColor: coloreCiano,
                      title: 'Termini e Condizioni',
                      subtitle: 'Condizioni generali di servizio',
                      isExternal: true,
                      onTap: () => _apriLink(context, 'https://www.iubenda.com/privacy-policy/94892300/cookie-policy'),
                    ),
                  ], coloreCard, coloreCiano),

                  const SizedBox(height: 28),

                  // 🧪 STRUMENTI SVILUPPO
                  _buildSectionHeader('STRUMENTI DI SVILUPPO', coloreCiano),
                  const SizedBox(height: 12),
                  _buildCardGroup([
                    _buildListTile(
                      icon: Icons.bug_report_outlined,
                      iconColor: coloreCiano,
                      title: 'Apri Test Sandbox',
                      subtitle: 'Reset dati, simulatore PRO e test offline',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfiloSandboxScreen()),
                        );
                      },
                    ),
                  ], coloreCard, coloreCiano),

                  const SizedBox(height: 36),

                  // 🚪 LOGOUT
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

                  // 🗑️ ELIMINA ACCOUNT
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

  // 🎨 HELPER COMPONENTS
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children, Color coloreCard, Color coloreBordo) {
    return Container(
      decoration: BoxDecoration(
        color: coloreCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: coloreBordo.withOpacity(0.2)),
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