import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'follow_request_page.dart';
import 'home_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final friendsResponse = await supabase
          .from('friends')
          .select('friend_id')
          .eq('user_id', user.id);

      final List<String> friendIds = friendsResponse.isEmpty
          ? []
          : List<String>.from(friendsResponse.map((f) => f['friend_id']));

      final usersResponse = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .neq('id', user.id);

      return usersResponse
          .where((u) => !friendIds.contains(u['id']))
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _sendFollowRequest(String userIdToFollow) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existingRequest = await supabase
        .from('follow_requests')
        .select()
        .eq('sender_id', user.id)
        .eq('receiver_id', userIdToFollow)
        .maybeSingle();

    if (existingRequest != null) return;

    await supabase.from('follow_requests').insert({
      'sender_id': user.id,
      'receiver_id': userIdToFollow,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  Future<String> _getFollowRequestStatus(String userIdToFollow) async {
    final user = supabase.auth.currentUser;
    if (user == null) return "Follow";

    final existingRequest = await supabase
        .from('follow_requests')
        .select()
        .eq('sender_id', user.id)
        .eq('receiver_id', userIdToFollow)
        .maybeSingle();

    if (existingRequest != null && existingRequest['status'] == 'pending') {
      return "En attente";
    }
    return "Follow";
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddFriendsPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("Add Friends", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowRequestsPage()));
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final avatarUrl = user['avatar_url'] != null
                  ? supabase.storage.from('profile-pictures').getPublicUrl(user['avatar_url'])
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: avatarUrl != null
                            ? Image.network(avatarUrl, width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(width: 15),
                      Text(user['username'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      FutureBuilder<String>(
                        future: _getFollowRequestStatus(user['id']),
                        builder: (context, statusSnapshot) {
                          if (!statusSnapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final status = statusSnapshot.data!;
                          return ElevatedButton(
                            onPressed: status == "Follow" ? () => _sendFollowRequest(user['id']) : null,
                            child: Text(status),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: _onNavTap,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Add Friends'),
        ],
      ),
    );
  }
}
