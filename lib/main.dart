import 'package:flutter/material.dart';
import 'package:thewall/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lnfgzxcvmampnfzhkgal.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxuZmd6eGN2bWFtcG5memhrZ2FsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4MTI5OTAsImV4cCI6MjA3OTM4ODk5MH0.CBhAXQ-Sj09UKy2GfXt-iCeCNKllBeq68LQPG6EWvL0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthPage());
  }
}
