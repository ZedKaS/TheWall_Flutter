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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
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

      await supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'username': username,
        'created': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
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
      backgroundColor: Colors.white, // fond blanc comme LoginPage
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO ---
                SizedBox(
                  width: 250,
                  height: 150,
                  child: Image.asset(
                    'lib/assets/sigmawall.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 15),

                // --- Champs texte ---
                SizedBox(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MyTextField(controller: confirmPasswordController, hintText: 'Confirm Password', obscureText: true),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MyTextField(controller: nomController, hintText: 'Nom', obscureText: false),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MyTextField(controller: prenomController, hintText: 'Prenom', obscureText: false),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MyTextField(controller: usernameController, hintText: 'Username', obscureText: false),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Bouton Sign Up avec icône ---
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: MyButton(
                      onTap: signUp,
                      text: '',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_add, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // --- Lien Login ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already a member?',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Login now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4BA3FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
