import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/auth/login_or_register.dart';
import 'package:thewall/pages/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<AuthState>(
        stream: _authStream,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;

          // user is logged in
          if (session != null) {
            return const HomePage();
          }

          // user is NOT logged in
          return const LoginOrRegister();
        },
      ),
    );
  }
}
