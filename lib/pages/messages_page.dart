import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> friendsList = [];

  @override
  void initState() {
    super.initState();
    _fetchFriends(); // Récupérer les amis de l'utilisateur connecté
  }

  // Fonction pour récupérer les amis de l'utilisateur connecté
  Future<void> _fetchFriends() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null)
      return; // Si l'utilisateur n'est pas connecté, on ne fait rien

    try {
      // 1. Récupérer les amis de l'utilisateur connecté depuis la table 'friends'
      final response = await supabase
          .from('friends')
          .select('friend_id') // On sélectionne les ID des amis
          .or(
            'user_id.eq.$userId,friend_id.eq.$userId',
          ); // Filtrer par user_id ou friend_id égal à l'ID de l'utilisateur connecté

      // Accéder directement aux données et vérifier s'il y a des amis
      if (response.isEmpty) {
        throw Exception('Aucun ami trouvé.');
      }

      // Extraire les IDs des amis
      final friendIdsList = response.map((e) => e['friend_id']).toList();

      // 2. Récupérer les informations des amis dans la table 'profiles'
      for (var friendId in friendIdsList) {
        final profileResponse = await supabase
            .from('profiles')
            .select('id, username, avatar_url')
            .eq('id', friendId)
            .single();

        setState(() {
          // Ajouter le profil à la liste des amis
          friendsList.add(profileResponse);
        });
      }
    } on AuthException catch (e) {
      // Gestion des erreurs liées à l'authentification
      print('Erreur d\'authentification: ${e.message}');
    } on PostgrestException catch (e) {
      // Gestion des erreurs liées à la base de données
      print('Erreur de base de données: ${e.message}');
    } catch (e) {
      // Gestion des autres erreurs
      print('Erreur générale: $e');
    }
  }

  // Fonction pour gérer les taps de la BottomNavigationBar
  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      // déjà sur messages
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
          child: Text("Messages", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: friendsList.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Chargement des amis
          : ListView.builder(
              itemCount: friendsList.length,
              itemBuilder: (context, index) {
                final friend = friendsList[index];
                final avatarUrl = friend['avatar_url'] != null
                    ? supabase.storage
                          .from('profile-pictures')
                          .getPublicUrl(friend['avatar_url'])
                    : null;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        width: 2,
                        color: const Color.fromARGB(255, 142, 152, 235),
                      ),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 40,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      title: Text(
                        friend['username'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(friend['username'] ?? "No username"),
                      onTap: () {
                        // Gérer l'ouverture des messages avec l'ami sélectionné
                      },
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Onglet Message sélectionné
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
