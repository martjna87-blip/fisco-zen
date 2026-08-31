import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;
  final Duration lockThreshold;

  const AppLockWrapper({
    super.key,
    required this.child,
    this.lockThreshold = const Duration(minutes: 1),
  });

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  
  bool _isLocked = false;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final timePassed = DateTime.now().difference(_backgroundTime!);
        _backgroundTime = null;

        if (timePassed >= widget.lockThreshold) {
          setState(() {
            _isLocked = true;
          });
          _eseguiSblocco();
        }
      }
    }
  }

  Future<void> _eseguiSblocco() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isSupported) {
        setState(() => _isLocked = false);
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Sblocca per accedere ai tuoi dati fiscali',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        setState(() => _isLocked = false);
      }
    } catch (e) {
      debugPrint("Errore Sblocco Biometrico: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        if (_isLocked)
          Positioned.fill(
            child: Material(
              color: const Color(0xFF080B0C),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF2DD4BF),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'FiscON è Bloccato',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Autenticati per accedere ai tuoi dati riservati',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _eseguiSblocco,
                          icon: const Icon(Icons.fingerprint_rounded, size: 22),
                          label: const Text(
                            'Sblocca con Biometria / PIN',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2DD4BF),
                            foregroundColor: const Color(0xFF080B0C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}