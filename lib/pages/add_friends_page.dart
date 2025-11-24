import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'messages_page.dart';
import 'profile_page.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic> profilesMap = {};
  late StreamSubscription<List<Map<String, dynamic>>> _profilesSub;

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users on page load
  }

  // Fetch users from the database using stream()
  Future<void> _fetchUsers() async {
    _profilesSub = supabase.from('profiles').stream(primaryKey: ['id']).listen((
      profiles,
    ) {
      setState(() {
        profilesMap = {for (var p in profiles) p['id'].toString(): p};
      });
    });
  }

  // Ajouter un ami
  // Ajouter un ami
  Future<void> _addFriend(String friendId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId == friendId) {
      // Ne pas permettre d'ajouter soi-même comme ami
      return;
    }

    try {
      // Vérifier si la relation d'amitié existe déjà
      final response = await supabase.from('friends').select().match(
        {'user_id': userId, 'friend_id': friendId},
      ).maybeSingle(); // Utilisation de maybeSingle() pour éviter l'erreur si aucune ligne n'est trouvée

      // Si aucune relation d'amitié n'est trouvée, on ajoute l'ami
      if (response == null) {
        final result = await supabase.from('friends').insert([
          {'user_id': userId, 'friend_id': friendId},
        ]);

        // Vérifier si result est non null avant d'accéder à l'erreur
        if (result != null && result.error != null) {
          throw result.error!; // Lever l'exception si une erreur survient
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ami ajouté avec succès !')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous êtes déjà amis avec cet utilisateur.')),
        );
      }
    } catch (e) {
      // Gérer les erreurs potentielles
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'ami: $e')),
      );
    }
  }

  @override
  void dispose() {
    _profilesSub.cancel(); // Cancel subscription on dispose
    super.dispose();
  }

  // Handle Bottom Navigation Bar taps
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
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Center(
          child: Text("Add Friends", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: profilesMap.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Loading state
          : ListView.builder(
              itemCount: profilesMap.length,
              itemBuilder: (context, index) {
                final user = profilesMap.values.toList()[index];
                final avatarUrl = user['avatar_url'] != null
                    ? supabase.storage
                          .from('profile-pictures')
                          .getPublicUrl(user['avatar_url'])
                    : null;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                      side: BorderSide(
                        width: 2,
                        color: const Color.fromARGB(255, 142, 152, 235),
                      ), // Bold border
                    ),
                    elevation: 5, // Shadow effect
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 40, // Larger size for profile image
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      title: Text(
                        user['username'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email'] ?? "No email"),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () {
                          // Appeler la fonction d'ajout d'ami
                          _addFriend(user['id']);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Onglet "Add Friends" sélectionné
        onTap: (index) => _onNavTap(index),
        selectedItemColor: Colors.blue, // Couleur de l'élément sélectionné
        unselectedItemColor: Color.fromARGB(
          255,
          73,
          73,
          73,
        ), // Couleur des éléments non sélectionnés
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
