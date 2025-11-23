import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/components/text_field.dart';
import 'package:thewall/components/wall_post.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final textController = TextEditingController();
  final imageController = TextEditingController(); // si tu veux ajouter un URL d'image

  void signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> postPublication() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Récupérer le profile_id depuis la table profiles
    final profileData = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .single();

    final profileId = profileData['id'];

    // Post only if content or image is not empty
    if ((textController.text.isNotEmpty) || (imageController.text.isNotEmpty)) {
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

    // Vérifier si l'utilisateur a déjà liké
    final alreadyLiked = await supabase
        .from('publication_likes')
        .select('*')
        .eq('publication_id', pubId)
        .eq('profile_id', profileId)
        .single();

    if (alreadyLiked != null) return; // ne pas liker 2 fois

    // Ajouter like
    await supabase.from('publication_likes').insert({
      'publication_id': pubId,
      'profile_id': profileId,
    });

    // Mettre à jour le compteur
    await supabase.rpc('update_publication_likes', params: {'pub_id': pubId});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Center(
            child: Text("The Wall", style: TextStyle(color: Colors.white))),
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
          // Publications en temps réel
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from(
                  'publications:profile_id=profiles.id') // jointure pour récupérer le username
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final publications = snapshot.data!;
                  return ListView.builder(
                    itemCount: publications.length,
                    itemBuilder: (context, index) {
                      final pub = publications[index];
                      final content = pub['content'] as String?;
                      final image = pub['image'] as String?;
                      final likes = pub['likes'] as int? ?? 0;
                      final username = pub['profiles']['username'] as String?;

                      return Card(
                        margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(username ?? 'Unknown',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    pub['created_at'] != null
                                        ? DateTime.parse(pub['created_at'])
                                        .toLocal()
                                        .toString()
                                        : '',
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
                                    onPressed: () => likePublication(pub['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          // Ajouter une publication
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
    );
  }
}
