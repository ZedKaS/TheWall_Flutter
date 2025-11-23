import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/components/button.dart';
import 'package:thewall/components/text_field.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabase = Supabase.instance.client;

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final usernameController = TextEditingController();

  void signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final nom = nomController.text.trim();
    final prenom = prenomController.text.trim();
    final username = usernameController.text.trim();

    if (password != confirmPassword) {
      displayMessage("Passwords do not match!");
      return;
    }

    if (email.isEmpty || password.isEmpty || nom.isEmpty || prenom.isEmpty || username.isEmpty) {
      displayMessage("Please fill all fields!");
      return;
    }

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Créer l'utilisateur dans Supabase Auth (sans mail de confirmation)
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = authResponse.user;
      if (user == null) {
        Navigator.pop(context);
        displayMessage("Failed to create user.");
        return;
      }

      // Insérer le profil dans la table "profiles"
      await supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'username': username,
        'created': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context); // fermer loader
      displayMessage("Account created successfully!");
    } on AuthException catch (e) {
      Navigator.pop(context);
      displayMessage(e.message);
    } catch (e) {
      Navigator.pop(context);
      displayMessage(e.toString());
    }
  }

  void displayMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 100),
                const SizedBox(height: 25),
                MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                const SizedBox(height: 10),
                MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                const SizedBox(height: 10),
                MyTextField(controller: confirmPasswordController, hintText: 'Confirm Password', obscureText: true),
                const SizedBox(height: 10),
                MyTextField(controller: nomController, hintText: 'Nom', obscureText: false),
                const SizedBox(height: 10),
                MyTextField(controller: prenomController, hintText: 'Prenom', obscureText: false),
                const SizedBox(height: 10),
                MyTextField(controller: usernameController, hintText: 'Username', obscureText: false),
                const SizedBox(height: 20),
                MyButton(onTap: signUp, text: 'Sign Up'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text('Login now', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
