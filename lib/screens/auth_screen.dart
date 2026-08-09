import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/auth_provider.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nomeController = TextEditingController(); // 👈 Aggiunto per il nome
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // Permette di alternare tra Login e Registrazione

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    // Il nome potrai passarlo al provider se decidi di salvarlo nel database
    // final nome = _nomeController.text.trim(); 

    if (email.isEmpty || password.isEmpty) {
      _showError("Per favore, inserisci email e password.");
      return;
    }

    if (!_isLogin && _nomeController.text.trim().isEmpty) {
      _showError("Per favore, inserisci un nome o ragione sociale.");
      return;
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
        // nome: nome, // Decommenta se nel tuo AuthProvider aggiungi il parametro nome
      );
    }

    if (error != null && mounted) {
      _showError(error);
    } else if (mounted) {
      // Reindirizza alla SplashScreen per entrare nell'app
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
              // 🖼️ LOGO FISCON (Misura grande + Centrato)
Transform.translate(
  offset: const Offset(60.0, 0.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Text(
        'Fisc',
        style: TextStyle(
          color: Colors.white,
          fontSize: 52,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
        ),
      ),
      Transform.translate(
        offset: const Offset(-60.0, -3.0),
        child: Image.asset(
          'assets/fiscon_symbol.png',
          height: 170,
          fit: BoxFit.contain,
        ),
      ),
      Transform.translate(
        offset: const Offset(-120.0, 0.0),
        child: const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
      ),
    ],
  ),
),
                const SizedBox(height: 16),
                
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

                // 📝 Campo Nome (Visibile SOLO in registrazione)
                if (!_isLogin) ...[
                  TextField(
                    controller: _nomeController,
                    keyboardType: TextInputType.name,
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

                // 📧 Campo Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
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

                // 🔒 Campo Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E1E2C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 🔘 Pulsante principale Accedi / Registrati
                SizedBox(
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
                const SizedBox(height: 20),

                // 🔄 Tasto per alternare Login e Registrazione
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
    );
  }
}