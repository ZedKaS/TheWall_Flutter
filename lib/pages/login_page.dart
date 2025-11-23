import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/components/button.dart';
import 'package:thewall/components/text_field.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final supabase = Supabase.instance.client;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Login sans vérification email
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pop(context);

      if (response.user != null) {
        displayMessage("Login successful!");
      } else {
        displayMessage("Login failed. Check your credentials.");
      }

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.lock, size: 100),
                const SizedBox(height: 20),
                const Text("Welcome back, you've been missed"),
                const SizedBox(height: 25),

                MyTextField(controller: emailController, hintText: 'Email', obscureText: false),
                const SizedBox(height: 15),
                MyTextField(controller: passwordController, hintText: 'Password', obscureText: true),
                const SizedBox(height: 25),

                MyButton(onTap: signIn, text: 'Sign In'),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Not a member?', style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text('Register now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
