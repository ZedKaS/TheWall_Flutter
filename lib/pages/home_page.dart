import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/components/text_field.dart';

import 'messages_page.dart';
import 'profile_page.dart';
<<<<<<< HEAD
=======
import 'add_friends_page.dart'; // Importer la page AddFriendsPage
import '../session_manager.dart';
>>>>>>> main

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final sessionManager = SessionManager();
  final textController = TextEditingController();
  final imageController = TextEditingController();
<<<<<<< HEAD
=======

  Map<String, dynamic> profilesMap = {};
  late StreamSubscription<List<Map<String, dynamic>>> _profilesSub;

  @override
  void initState() {
    super.initState();
    sessionManager.goOnline();

    _profilesSub = supabase.from('profiles').stream(primaryKey: ['id']).listen((
      profiles,
    ) {
      setState(() {
        profilesMap = {for (var p in profiles) p['id'].toString(): p};
      });
    });
  }

  @override
  void dispose() {
    textController.dispose();
    imageController.dispose();
    _profilesSub.cancel();
    super.dispose();
  }
>>>>>>> main

  void signOut() async {
    await sessionManager.goOffline();
    await supabase.auth.signOut();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> likePublication(String pubId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profileId = user.id;

    final alreadyLiked = await supabase
        .from('publication_likes')
        .select()
        .eq('publication_id', pubId)
        .eq('profile_id', profileId)
        .maybeSingle();

    if (alreadyLiked != null) return;

    await supabase.from('publication_likes').insert({
      'publication_id': pubId,
      'profile_id': profileId,
    });

    await supabase.rpc('update_publication_likes', params: {'pub_id': pubId});
  }

  Future<void> postPublication() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

<<<<<<< HEAD
    final profileData = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .single();

    final profileId = profileData['id'];

=======
>>>>>>> main
    if (textController.text.isNotEmpty || imageController.text.isNotEmpty) {
      await supabase.from('publications').insert({
        'profile_id': user.id,
        'content': textController.text.isEmpty ? null : textController.text,
        'image': imageController.text.isEmpty ? null : imageController.text,
      });
    }

    setState(() {
      textController.clear();
      imageController.clear();
    });
  }

  void _onNavTap(int index) {
    if (index == 0) return;

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MessagesPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else if (index == 3) {
      // Navigation vers la page AddFriendsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AddFriendsPage()),
      );
    }
  }

<<<<<<< HEAD
    final profileId = profileData['id'];

    final alreadyLiked = await supabase
        .from('publication_likes')
        .select('*')
        .eq('publication_id', pubId)
        .eq('profile_id', profileId)
        .maybeSingle();

    if (alreadyLiked != null) return;

    await supabase.from('publication_likes').insert({
      'publication_id': pubId,
      'profile_id': profileId,
    });

    await supabase.rpc('update_publication_likes', params: {'pub_id': pubId});
=======
  // Helper pour interpréter différents types comme bool
  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v.toLowerCase() == 'true' || v == '1' || v == 't';
    return false;
>>>>>>> main
  }

  void _onNavTap(int index) {
    if (index == 0) return;

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MessagesPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Center(
          child: Text("The Wall", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('publications')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
<<<<<<< HEAD
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

=======
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

>>>>>>> main
                final publications = snapshot.data!;
                if (publications.isEmpty) {
                  return const Center(child: Text("No publications yet."));
                }

                return ListView.builder(
                  itemCount: publications.length,
                  itemBuilder: (context, index) {
                    final pub = publications[index];
<<<<<<< HEAD
                    final content = pub['content'] as String?;
                    final image = pub['image'] as String?;
                    final likes = pub['likes'] as int? ?? 0;

                    // 🔥 Récupération du username via jointure Supabase
                    final username = pub['profiles']?['username'] ?? 'Unknown';

                    final createdAt = pub['created_at'];

=======

                    // Récupérer le profil de l'auteur
                    final profileId = pub['profile_id'].toString();
                    final profile = profilesMap[profileId];

                    // Username correct
                    final username = profile != null
                        ? profile['username'] ?? 'Unknown'
                        : 'Unknown';

                    // Online de l'auteur
                    final authorOnline = profile != null
                        ? _toBool(profile['online'])
                        : false;

                    // URL de l'avatar
                    final avatarUrl =
                        (profile != null && profile['avatar_url'] != null)
                        ? supabase.storage
                              .from('profile-pictures')
                              .getPublicUrl(profile['avatar_url'])
                        : null;

                    // Date de création du post
                    final createdAt = pub['created_at'];
>>>>>>> main
                    String createdAtText = '';
                    if (createdAt != null) {
                      final date = DateTime.parse(
                        createdAt.toString(),
                      ).toLocal();
                      createdAtText =
                          "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                    }

<<<<<<< HEAD
=======
                    // Identification du post de l'utilisateur courant
                    final currentUser = supabase.auth.currentUser;
                    final isMyPost =
                        currentUser != null && currentUser.id == profileId;

                    final bool isGreenDot = isMyPost || authorOnline;

>>>>>>> main
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
<<<<<<< HEAD
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
=======
                            // Header: Avatar + Username + pastille + date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 15,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isGreenDot
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
>>>>>>> main
                                ),
                                Text(
                                  createdAtText,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),

<<<<<<< HEAD
                            if (content != null) ...[
                              const SizedBox(height: 5),
                              Text(content),
                            ],

                            if (image != null) ...[
                              const SizedBox(height: 5),
                              Image.network(image),
=======
                            if (pub['content'] != null) ...[
                              const SizedBox(height: 5),
                              Text(pub['content']),
                            ],

                            if (pub['image'] != null) ...[
                              const SizedBox(height: 5),
                              Image.network(pub['image']),
>>>>>>> main
                            ],

                            const SizedBox(height: 5),
                            Row(
                              children: [
<<<<<<< HEAD
                                Text('Likes: $likes'),
=======
                                Text('Likes: ${pub['likes'] ?? 0}'),
>>>>>>> main
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.thumb_up),
                                  onPressed: () =>
                                      likePublication(pub['id'].toString()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
<<<<<<< HEAD

=======
>>>>>>> main
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                MyTextField(
                  controller: textController,
                  hintText: "Write something...",
                  obscureText: false,
                ),
                const SizedBox(height: 5),
                MyTextField(
                  controller: imageController,
                  hintText: "Image URL (optional)",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: postPublication,
                  child: const Text("Post"),
                ),
              ],
            ),
          ),
        ],
      ),
<<<<<<< HEAD

=======
>>>>>>> main
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
<<<<<<< HEAD
        ],
=======
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Add Friends',
          ),
        ],
        selectedItemColor:
            Colors.blue, // Couleur pour l'élément sélectionné (accentuée)
        unselectedItemColor: Color.fromARGB(
          255,
          73,
          73,
          73,
        ), // Couleur grise pour les éléments non sélectionnés
        backgroundColor: Colors.white, // Fond de la BottomNavigationBar
        type: BottomNavigationBarType
            .fixed, // Important pour que tous les textes soient visibles
>>>>>>> main
      ),
    );
  }
}
