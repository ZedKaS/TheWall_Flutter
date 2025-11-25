import 'package:supabase_flutter/supabase_flutter.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final supabase = Supabase.instance.client;
  bool _isOnline = false;

  Future<void> goOnline() async {
    if (_isOnline) return;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final updated = await supabase
          .from('profiles')
          .update({'online': true})
          .eq('id', user.id)
          .select()
          .single(); // <- récupère la ligne mise à jour
      print("goOnline updated row: $updated");
      _isOnline = true;
    }
  }

  Future<void> goOffline() async {
    if (!_isOnline) return;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final updated = await supabase
          .from('profiles')
          .update({'online': false})
          .eq('id', user.id)
          .select()
          .single(); // récupère la ligne mise à jour
      print("goOffline updated row: $updated");
      _isOnline = false;
    }
  }

}
