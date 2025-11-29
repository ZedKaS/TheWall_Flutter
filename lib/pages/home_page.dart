import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thewall/components/text_field.dart';

import 'messages_page.dart';
import 'profile_page.dart';
import 'add_friends_page.dart';
import '../session_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final sessionManager = SessionManager();
  final textController = TextEditingController();

  String? pickedImagePath;
  String? uploadedImageUrl;

  Map<String, dynamic> profilesMap = {};
  late StreamSubscription<List<Map<String, dynamic>>> _profilesSub;

  @override
  void initState() {
    super.initState();
    sessionManager.goOnline();

    _profilesSub = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .listen((profiles) {
      setState(() {
        profilesMap = {for (var p in profiles) p['id'].toString(): p};
      });
    });
  }

  @override
  void dispose() {
    textController.dispose();
    _profilesSub.cancel();
    super.dispose();
  }

  Future<void> signOut() async {
    await sessionManager.goOffline();
    await supabase.auth.signOut();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // -----------------------------------------------------------------------------
  // LIKE SYSTEM
  // -----------------------------------------------------------------------------
  Future<void> likePublication(String pubId, int currentLikes) async {
    await supabase.from('publications').update({
      'likes': currentLikes + 1,
    }).eq('id', pubId);
  }

  // -----------------------------------------------------------------------------
  // PICK + UPLOAD IMAGE (FIXED)
  // -----------------------------------------------------------------------------
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final ext = picked.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      // Read file bytes (supports mobile + web)
      final bytes = await picked.readAsBytes();

      // Upload using bytes (WORKS ON WEB)
      final response = await supabase.storage
          .from('post-pic')
          .uploadBinary(fileName, bytes);

      print("UPLOAD RESPONSE: $response");

      final url = supabase.storage
          .from('post-pic')
          .getPublicUrl(fileName);

      print("PUBLIC URL = $url");

      setState(() {
        uploadedImageUrl = url;
        pickedImagePath = picked.path; // just for checkmark UI
      });
    } catch (e) {
      print("UPLOAD ERROR: $e");
      setState(() {
        pickedImagePath = null;
        uploadedImageUrl = null;
      });
    }
  }


  // -----------------------------------------------------------------------------
  // POST PUBLICATION
  // -----------------------------------------------------------------------------
  Future<void> postPublication() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (textController.text.isEmpty && uploadedImageUrl == null) return;

    await supabase.from('publications').insert({
      'profile_id': user.id,
      'content': textController.text.isEmpty ? null : textController.text,
      'image': uploadedImageUrl,
      'likes': 0,
    });

    setState(() {
      textController.clear();
      pickedImagePath = null;
      uploadedImageUrl = null;
    });
  }

  // -----------------------------------------------------------------------------
  // DELETE PUBLICATION (FIXED: removes correct file)
  // -----------------------------------------------------------------------------
  Future<void> deletePublication(String id, String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final fileName = Uri.parse(imageUrl).pathSegments.last;

        await supabase.storage.from('post-pic').remove([fileName]);
      } catch (e) {
        print("DELETE ERROR: $e");
      }
    }

    await supabase.from('publications').delete().eq('id', id);
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MessagesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    } else if (index == 3) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AddFriendsPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('publications')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
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
                    final profileId = pub['profile_id'].toString();
                    final profile = profilesMap[profileId];

                    final username = profile?['username'] ?? 'Unknown';
                    final avatarFile = profile?['avatar_url'];

                    final avatarUrl = avatarFile != null
                        ? supabase.storage
                        .from('profile-pictures')
                        .getPublicUrl(avatarFile)
                        : null;

                    final createdAt = pub['created_at'] != null
                        ? DateTime.parse(pub['created_at']).toLocal()
                        : null;

                    final isMyPost =
                        supabase.auth.currentUser?.id == profileId;

                    final likes = pub['likes'] ?? 0;

                    return Card(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      backgroundColor: Colors.grey[300],
                                      child: avatarUrl == null
                                          ? const Icon(Icons.person,
                                          size: 15, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (createdAt != null)
                                      Text(
                                        "${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (isMyPost)
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => deletePublication(
                                            pub['id'], pub['image']),
                                      )
                                  ],
                                )
                              ],
                            ),

                            if (pub['content'] != null) ...[
                              const SizedBox(height: 5),
                              Text(pub['content']),
                            ],

                            if (pub['image'] != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(pub['image']),
                              ),
                            ],

                            Row(
                              children: [
                                Text("Likes: $likes"),
                                IconButton(
                                  icon: const Icon(Icons.thumb_up),
                                  onPressed: () =>
                                      likePublication(pub['id'], likes),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // POST BOX
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                MyTextField(
                  controller: textController,
                  hintText: "Write something...",
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    ElevatedButton(
                        onPressed: pickImage, child: const Text("Pick Image")),
                    const SizedBox(width: 10),
                    if (pickedImagePath != null)
                      const Icon(Icons.check_circle, color: Colors.green),

                    if (uploadedImageUrl != null)
                      Expanded(
                        child: Text(
                          uploadedImageUrl!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
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
          BottomNavigationBarItem(
              icon: Icon(Icons.post_add), label: 'Post'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add), label: 'Add Friends'),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Color.fromARGB(255, 73, 73, 73),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
