import 'package:flutter/material.dart';
import 'package:thewall/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/pages/home_page.dart';
import 'package:thewall/pages/messages_page.dart';
import 'package:thewall/pages/profile_page.dart';
import 'package:thewall/pages/add_friends_page.dart'; // Assurez-vous d'importer cette page
import 'session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lnfgzxcvmampnfzhkgal.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxuZmd6eGN2bWFtcG5memhrZ2FsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MTI5OTAsImV4cCI6MjA3OTM4ODk5MH0.CBhAXQ-Sj09UKy2GfXt-iCeCNKllBeq68LQPG6EWvL0',
  );

  // Mettre online si déjà connecté
  await SessionManager().goOnline();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    SessionManager()
        .goOffline(); // assure que l'utilisateur est offline à la fermeture
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Si l'app est fermée
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      sessionManager.goOffline(); // seulement ici
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      routes: {
        '/home': (_) => const HomePage(),
        '/messages': (_) => const MessagesPage(),
        '/profile': (_) => const ProfilePage(),
        '/addFriends': (_) => const AddFriendsPage(), // Ajoutez cette ligne
      },
    );
  }
}
