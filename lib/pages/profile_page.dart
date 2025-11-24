import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../session_manager.dart';
import 'messages_page.dart';
import 'add_friends_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  final sessionManager = SessionManager();

  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> userPublications = [];

  late StreamSubscription<List<Map<String, dynamic>>> _profileSub;
  late StreamSubscription<List<Map<String, dynamic>>> _pubSub;

  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    if (user == null) return;

    currentUserId = user.id;
    sessionManager.goOnline();

    // ---- PROFIL STREAM ----
    _profileSub = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', currentUserId)
        .listen((profiles) {
          setState(() {
            userProfile = profiles.first;
          });
        });

    // ---- MES PUBLICATIONS ----
    _pubSub = supabase
        .from('publications')
        .stream(primaryKey: ['id'])
        .eq('profile_id', currentUserId)
        .order('created_at', ascending: false)
        .listen((pubs) async {
          for (var p in pubs) {
            final owner = await supabase
                .from('profiles')
                .select()
                .eq('id', p['profile_id'])
                .single();
            p['owner'] = owner;
          }
          setState(() {
            userPublications = pubs;
          });
        });
  }

  @override
  void dispose() {
    _profileSub.cancel();
    _pubSub.cancel();
    super.dispose();
  }

  Future<void> signOut(BuildContext context) async {
    await sessionManager.goOffline();
    await supabase.auth.signOut();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  String relativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return "${diff.inMinutes} min";
    if (diff.inHours < 24) return "${diff.inHours} h";
    return "${diff.inDays} j";
  }

  Future<void> uploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final fileBytes = await pickedFile.readAsBytes();
    final fileName =
        '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.png';

    // Upload du fichier
    await supabase.storage
        .from('profile-pictures')
        .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: FileOptions(upsert: true),
        );

    // Mettre à jour le profil
    await supabase
        .from('profiles')
        .update({'avatar_url': fileName})
        .eq('id', currentUserId);

    setState(() {
      userProfile!['avatar_url'] = fileName;
    });
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/messages');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/profile');
    } else if (index == 3) {
      // Navigation vers la page AddFriendsPage
      Navigator.pushReplacementNamed(context, '/addFriends');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isOnline = userProfile!['online'] ?? false;

    // Obtenir l'URL publique de l'avatar
    final avatarUrl = userProfile!['avatar_url'] != null
        ? supabase.storage
              .from('profile-pictures')
              .getPublicUrl(userProfile!['avatar_url'])
        : null;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Center(
          child: Text("Profile", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- AVATAR + USERNAME + PASTILLE ----------
            Center(
              child: GestureDetector(
                onTap: uploadAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "@${userProfile!['username']}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ------ INFOS ------
            Text(
              "Prénom : ${userProfile!['prenom'] ?? ''}",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Nom : ${userProfile!['nom'] ?? ''}",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Email : ${userProfile!['email'] ?? ''}",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Date de création : ${userProfile!['created'] != null ? DateTime.parse(userProfile!['created']).toLocal().toString().split('.')[0] : ''}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () => signOut(context),
                child: const Text("Logout"),
              ),
            ),
            const SizedBox(height: 35),

            const Text(
              "Mes publications",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (userPublications.isEmpty)
              const Text("Aucune publication pour le moment."),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userPublications.length,
              itemBuilder: (context, index) {
                final pub = userPublications[index];
                final owner = pub['owner'];

                final bool ownerOnline = owner['online'] ?? false;
                final bool isMyPost = pub['profile_id'] == currentUserId;

                final bool green = isMyPost || ownerOnline;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------ HEADER AVEC NOM + PASTILLE ------
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: green ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "@${owner['username']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              relativeTime(DateTime.parse(pub['created_at'])),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(pub['content'] ?? ''),
                        if (pub['image'] != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(pub['image']),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.favorite_border),
                            const SizedBox(width: 5),
                            Text("${pub['likes'] ?? 0}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Onglet Profile sélectionné
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
