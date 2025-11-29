import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../session_manager.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'add_friends_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final sessionManager = SessionManager();
  Map<String, dynamic> profilesMap = {};
  late StreamSubscription<List<Map<String, dynamic>>> _profilesSub;

  @override
  void initState() {
    super.initState();
    sessionManager.goOnline();
    _profilesSub = supabase.from('profiles').stream(primaryKey: ['id']).listen((profiles) {
      setState(() {
        profilesMap = {for (var p in profiles) p['id'].toString(): p};
      });
    });
  }

  @override
  void dispose() {
    _profilesSub.cancel();
    super.dispose();
  }

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

  void _onNavTap(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddFriendsPage()));
    }
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v.toLowerCase() == 'true' || v == '1' || v == 't';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ΣSigma",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('publications')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          final publications = snapshot.data!;
          if (publications.isEmpty) {
            return const Center(
              child: Text("No publications yet.", style: TextStyle(color: Colors.black)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: publications.length,
            itemBuilder: (context, index) {
              final pub = publications[index];
              final profileId = pub['profile_id'].toString();
              final profile = profilesMap[profileId];

              final username = profile != null ? profile['username'] ?? 'Unknown' : 'Unknown';
              final authorOnline = profile != null ? _toBool(profile['online']) : false;

              final avatarUrl = (profile != null && profile['avatar_url'] != null)
                  ? supabase.storage.from('profile-pictures').getPublicUrl(profile['avatar_url'])
                  : null;

              final createdAt = pub['created_at'];
              String createdAtText = '';
              if (createdAt != null) {
                final date = DateTime.parse(createdAt).toLocal();
                createdAtText =
                "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
              }

              final currentUser = supabase.auth.currentUser;
              final isMyPost = currentUser != null && currentUser.id == profileId;
              final bool isGreenDot = isMyPost || authorOnline;

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl == null
                                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isGreenDot ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            createdAtText,
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                      if (pub['content'] != null) ...[
                        const SizedBox(height: 10),
                        Text(pub['content'], style: const TextStyle(color: Colors.black)),
                      ],
                      if (pub['image'] != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(pub['image']),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Likes: ${pub['likes'] ?? 0}',
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.thumb_up, color: Colors.black),
                            onPressed: () => likePublication(pub['id'].toString()),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
