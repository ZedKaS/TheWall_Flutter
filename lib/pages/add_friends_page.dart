import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'follow_request_page.dart'; // Importer FollowRequestsPage

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

  // Fonction pour récupérer tous les utilisateurs sauf l'utilisateur authentifié et ceux qui sont déjà amis
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
          : List<String>.from(
              friendsResponse.map((friend) => friend['friend_id']),
            );

      final usersResponse = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .neq('id', user.id);

      final List<Map<String, dynamic>> filteredUsers = usersResponse
          .where((user) => !friendIds.contains(user['id']))
          .toList();

      return filteredUsers;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Fonction pour envoyer une demande de follow à un utilisateur
  Future<void> _sendFollowRequest(String userIdToFollow) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Vérifier si une demande de follow existe déjà
      final existingRequest = await supabase
          .from('follow_requests')
          .select()
          .eq('sender_id', user.id)
          .eq('receiver_id', userIdToFollow)
          .maybeSingle();

      // Si une demande existe déjà, on ne l'envoie pas à nouveau
      if (existingRequest != null) {
        print('Follow request already sent');
        return;
      }

      // Créer la nouvelle demande de follow
      await supabase.from('follow_requests').insert({
        'sender_id': user.id,
        'receiver_id': userIdToFollow,
        'status': 'pending', // Initialement en attente
        'created_at': DateTime.now().toIso8601String(),
      });

      print('Follow request sent');
      setState(() {
        _usersFuture = _fetchUsers(); // Rafraîchir la liste des utilisateurs
      });
    } catch (e) {
      print('Error sending follow request: $e');
    }
  }

  // Fonction pour vérifier si une demande de follow existe
  Future<String> _getFollowRequestStatus(String userIdToFollow) async {
    final user = supabase.auth.currentUser;
    if (user == null) return "Follow";

    try {
      final existingRequest = await supabase
          .from('follow_requests')
          .select()
          .eq('sender_id', user.id)
          .eq('receiver_id', userIdToFollow)
          .maybeSingle();

      if (existingRequest != null) {
        if (existingRequest['status'] == 'pending') {
          return "En attente";
        } else {
          return "Follow";
        }
      }
      return "Follow";
    } catch (e) {
      print('Error checking follow request status: $e');
      return "Follow";
    }
  }

  // Gestion de la navigation pour le BottomNavigationBar
  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/messages');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/addFriends');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Friends", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FollowRequestsPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              final avatarUrl = user['avatar_url'] != null
                  ? supabase.storage
                        .from('profile-pictures')
                        .getPublicUrl(user['avatar_url'])
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: avatarUrl != null
                            ? Image.network(
                                avatarUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        user['username'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      FutureBuilder<String>(
                        future: _getFollowRequestStatus(user['id']),
                        builder: (context, statusSnapshot) {
                          if (statusSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final status = statusSnapshot.data;

                          // Si c'est sa propre requête, ne pas afficher le bouton
                          return (status == "Follow")
                              ? ElevatedButton(
                                  onPressed: () =>
                                      _sendFollowRequest(user['id']),
                                  child: const Text('Follow'),
                                )
                              : ElevatedButton(
                                  onPressed:
                                      null, // Désactiver le bouton si la demande est en attente
                                  child: const Text('En attente'),
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
        onTap:
            _onNavTap, // Utilisation de la fonction _onNavTap pour la navigation
        backgroundColor: Colors.white, // Fond de la BottomNavigationBar
        type: BottomNavigationBarType
            .fixed, // Pour garder tous les textes visibles
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
