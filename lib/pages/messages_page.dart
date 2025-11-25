import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _fetchFriends();
  }

  // --------------------------------------------------
  // Fonction pour récupérer les amis de l'utilisateur
  // --------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchFriends() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('friends')
          .select('''
          id,
          user_id,
          friend_id,
          created_at,
          friend:user_id (
            username,
            avatar_url
          ),
          me:friend_id (
            username,
            avatar_url
          )
        ''')
          .or('user_id.eq.${user.id}, friend_id.eq.${user.id}');

      final List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
        response,
      );

      final List<Map<String, dynamic>> finalList = [];

      for (var row in result) {
        final bool iAmUser = row['user_id'] == user.id;

        final friendData = iAmUser ? row['me'] : row['friend'];

        if (friendData != null) {
          finalList.add({
            'username': friendData['username'],
            'avatar_url': friendData['avatar_url'],
            'created_at': row['created_at'],
          });
        }
      }

      // 🔥 Remove duplicates (important)
      final uniqueFriends = <String, Map<String, dynamic>>{};
      for (var friend in finalList) {
        uniqueFriends[friend['username']] = friend;
      }

      return uniqueFriends.values.toList();
    } catch (e) {
      print("Error fetching friends: $e");
      return [];
    }
  }

  // --------------------------------------------------
  // Bottom Navigation
  // --------------------------------------------------
  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // already on messages
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/addFriends');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),

      // --------------------------------------------------
      // BODY – LISTE DES AMIS
      // --------------------------------------------------
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("You have no friends yet."));
          }

          final friends = snapshot.data!;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final username = friend['username'] ?? "Unknown";
              final avatarPath = friend['avatar_url'];

              final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
                  ? supabase.storage
                        .from('profile-pictures')
                        .getPublicUrl(avatarPath)
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : const NetworkImage(
                            "https://cdn-icons-png.flaticon.com/512/149/149071.png",
                          ),
                  ),
                  title: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Friends since: ${friend['created_at']}"),

                  // 👉 Ici : ouvre conversation (DM) dans le futur
                  onTap: () {
                    // Navigator.push(context, MaterialPageRoute(
                    //   builder: (_) => ChatPage(friendId: ...)
                    // ));
                  },
                ),
              );
            },
          );
        },
      ),

      // --------------------------------------------------
      // BOTTOM NAVIGATION BAR
      // --------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) => _onNavTap(context, index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: const Color.fromARGB(255, 73, 73, 73),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add Friends',
          ),
        ],
      ),
    );
  }
}
