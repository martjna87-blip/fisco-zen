import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

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

  // 🗑️ FUNZIONE ELIMINAZIONE ACCOUNT
  Future<void> _confermaEliminazioneAccount(BuildContext context, AuthProvider authProvider) async {
    final confermato = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profilo & Impostazioni',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 CARD ACCOUNT
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: walletProvider.isProUser ? const Color(0xFFF59E0B) : const Color(0xFF2DD4BF),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF2DD4BF).withOpacity(0.15),
                      child: Icon(
                        Icons.person_rounded,
                        color: walletProvider.isProUser ? const Color(0xFFF59E0B) : const Color(0xFF2DD4BF),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          walletProvider.isProUser ? 'PRO ACCOUNT' : 'ACCOUNT BASE',
                          style: TextStyle(
                            color: walletProvider.isProUser ? const Color(0xFFF59E0B) : const Color(0xFF2DD4BF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
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
            _buildSectionHeader('ABBONAMENTO & FISCO'),
            const SizedBox(height: 10),
            _buildCardGroup([
              _buildListTile(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFF59E0B),
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
                iconColor: const Color(0xFF2DD4BF),
                title: 'Profilo Fiscale & ATECO',
                subtitle: 'ATECO: ${walletProvider.codiceAteco} • Coeff: ${(walletProvider.coeffRedditivita * 100).toInt()}%',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modifica profilo fiscale in arrivo!')),
                  );
                },
              ),
            ]),

            const SizedBox(height: 28),

            // ⚖️ SEZIONE LEGALE & PRIVACY
            _buildSectionHeader('LEGALE & PRIVACY'),
            const SizedBox(height: 10),
            _buildCardGroup([
              _buildListTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF2DD4BF),
                title: 'Privacy Policy',
                subtitle: 'Informativa sul trattamento dati',
                isExternal: true,
                onTap: () => _apriLink(context, 'https://www.iubenda.com/privacy-policy/94892300'),
              ),
              const Divider(color: Colors.white10, height: 1, indent: 60),
              _buildListTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF2DD4BF),
                title: 'Termini e Condizioni',
                subtitle: 'Condizioni generali di servizio',
                isExternal: true,
                onTap: () => _apriLink(context, 'https://www.iubenda.com/privacy-policy/94892300/cookie-policy'),
              ),
            ]),

            const SizedBox(height: 28),

            // 🧪 STRUMENTI SVILUPPO
            _buildSectionHeader('STRUMENTI DI SVILUPPO'),
            const SizedBox(height: 10),
            _buildCardGroup([
              _buildListTile(
                icon: Icons.bug_report_outlined,
                iconColor: Colors.amber,
                title: 'Apri Test Sandbox',
                subtitle: 'Reset dati, simulatore PRO e test offline',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfiloSandboxScreen()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 36),

            // 🚪 LOGOUT
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.redAccent.withOpacity(0.05),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                label: const Text(
                  'Esci dall\'account',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
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
    );
  }

  // 🎨 HELPER COMPONENTS
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2DD4BF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
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