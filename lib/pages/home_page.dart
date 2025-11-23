import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/components/text_field.dart';

import 'messages_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final textController = TextEditingController();
  final imageController = TextEditingController();

  void signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> postPublication() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profileData = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .single();

    final profileId = profileData['id'];

    if (textController.text.isNotEmpty || imageController.text.isNotEmpty) {
      await supabase.from('publications').insert({
        'profile_id': profileId,
        'content': textController.text.isEmpty ? null : textController.text,
        'image': imageController.text.isEmpty ? null : imageController.text,
      });
    }

    setState(() {
      textController.clear();
      imageController.clear();
    });
  }

  Future<void> likePublication(String pubId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profileData = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .single();

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
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final publications = snapshot.data!;
                if (publications.isEmpty) {
                  return const Center(child: Text("No publications yet."));
                }

                return ListView.builder(
                  itemCount: publications.length,
                  itemBuilder: (context, index) {
                    final pub = publications[index];
                    final content = pub['content'] as String?;
                    final image = pub['image'] as String?;
                    final likes = pub['likes'] as int? ?? 0;

                    // 🔥 Récupération du username via jointure Supabase
                    final username = pub['profiles']?['username'] ?? 'Unknown';

                    final createdAt = pub['created_at'];

                    String createdAtText = '';
                    if (createdAt != null) {
                      final date = DateTime.parse(
                        createdAt.toString(),
                      ).toLocal();
                      createdAtText =
                          "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                    }

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  createdAtText,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),

                            if (content != null) ...[
                              const SizedBox(height: 5),
                              Text(content),
                            ],

                            if (image != null) ...[
                              const SizedBox(height: 5),
                              Image.network(image),
                            ],

                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text('Likes: $likes'),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
