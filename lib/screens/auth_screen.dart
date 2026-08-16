import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../data/auth_provider.dart';
import '../widgets_shared/fiscon_logo.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 🔑 Face ID / Touch ID
  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        _showError("Autenticazione biometrica non disponibile su questo dispositivo.");
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Inquadra il volto o usa l\'impronta per accedere a FiscON',
      );

      if (didAuthenticate && mounted) {
        TextInput.finishAutofillContext();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
    } catch (e) {
      _showError("Errore durante la scansione biometrica.");
    }
  }

  // 🔑 Ripristino Password via Email
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError("Inserisci prima la tua email per ricevere il link di reset.");
      return;
    }

    final error = await Provider.of<AuthProvider>(context, listen: false)
        .resetPassword(email);

    if (error != null && mounted) {
      _showError(error);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email di ripristino inviata! Controlla la tua casella."),
          backgroundColor: Color(0xFF2DD4BF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Per favore, inserisci email e password.");
      return;
    }

    if (!_isLogin) {
      if (_nomeController.text.trim().isEmpty) {
        _showError("Per favore, inserisci un nome o ragione sociale.");
        return;
      }

      if (password.length < 6) {
        _showError("La password deve contenere almeno 6 caratteri.");
        return;
      }

      if (password != confirmPassword) {
        _showError("Le password non coincidono.");
        return;
      }
    }

    String? error;
    if (_isLogin) {
      error = await authProvider.signInWithEmail(
        email: email,
        password: password,
      );
    } else {
      error = await authProvider.signUpWithEmail(
        email: email,
        password: password,
      );
    }

    if (error != null && mounted) {
      _showError(error);
    } else if (mounted) {
      TextInput.finishAutofillContext();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF101012),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: AutofillGroup(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: FiscOnLogo(
                      fontSize: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    _isLogin ? "Bentornato su FiscON" : "Crea il tuo profilo",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? "Accedi per sincronizzare il tuo portafoglio"
                        : "Registrati per salvare i tuoi dati al sicuro nel Cloud",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 📝 Nome (solo registrazione)
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nomeController,
                      keyboardType: TextInputType.name,
                      autofillHints: const [AutofillHints.name],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Nome o Ragione Sociale",
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1E1E2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 📧 Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E1E2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔒 Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: _isLogin
                        ? const [AutofillHints.password]
                        : const [AutofillHints.newPassword],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // 💡 Tasto Password Dimenticata
                  if (_isLogin) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          "Password dimenticata?",
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],

                  // 🔒 Conferma Password (solo registrazione)
                  if (!_isLogin) ...[
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Conferma Password",
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.lock_reset_outlined, color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E1E2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 12),

                  // 🔘 Pulsante Accedi / Registrati + Face ID
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DD4BF),
                              foregroundColor: const Color(0xFF101012),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF101012),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? "ACCEDI" : "REGISTRATI",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (_isLogin) ...[
                        const SizedBox(width: 12),
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.face_unlock_outlined,
                              color: Color(0xFF2DD4BF),
                              size: 28,
                            ),
                            onPressed: _authenticateWithBiometrics,
                            tooltip: "Accedi con Face ID",
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🔄 Switch Login/Registrazione
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Non hai un account? Registrati"
                          : "Hai già un account? Accedi",
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}