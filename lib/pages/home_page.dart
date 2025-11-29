import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/text_field.dart';

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
        profilesMap = {for (var p in profiles) p['id']: p};
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

  // -------------------------------------------------------------------------
  // LIKE SYSTEM
  // -------------------------------------------------------------------------

  Future<bool> hasLiked(String postId) async {
    final uid = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('post_likes')
        .select()
        .eq('user_id', uid)
        .eq('post_id', postId);
    return res.isNotEmpty;
  }

  Future<int> getLikeCount(String postId) async {
    final res = await supabase
        .from('post_likes')
        .select('id')
        .eq('post_id', postId);
    return res.length;
  }

  Future<void> likePost(String postId) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('post_likes').insert({'user_id': uid, 'post_id': postId});
  }

  Future<void> unlikePost(String postId) async {
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('post_likes').delete().eq('user_id', uid).eq('post_id', postId);
  }

  // -------------------------------------------------------------------------
  // PICK + UPLOAD IMAGE
  // -------------------------------------------------------------------------
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await supabase.storage.from('post-pic').uploadBinary(fileName, bytes);
      final url = supabase.storage.from('post-pic').getPublicUrl(fileName);

      setState(() {
        uploadedImageUrl = url;
        pickedImagePath = picked.path;
      });
    } catch (_) {
      setState(() {
        pickedImagePath = null;
        uploadedImageUrl = null;
      });
    }
  }

  // -------------------------------------------------------------------------
  // POST PUBLICATION
  // -------------------------------------------------------------------------
  Future<void> postPublication() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    if (textController.text.isEmpty && uploadedImageUrl == null) return;

    await supabase.from('publications').insert({
      'profile_id': user.id,
      'content': textController.text.isEmpty ? null : textController.text,
      'image': uploadedImageUrl,
    });

    setState(() {
      textController.clear();
      pickedImagePath = null;
      uploadedImageUrl = null;
    });
  }

  // -------------------------------------------------------------------------
  // DELETE PUBLICATION (with confirmation)
  // -------------------------------------------------------------------------
  Future<void> deletePublication(String id, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete post?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete image from storage
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final fileName = Uri.parse(imageUrl).pathSegments.last;
        await supabase.storage.from('post-pic').remove([fileName]);
      } catch (e) {
        print("Error deleting image: $e");
      }
    }

    // Delete publication (likes will be deleted automatically if ON DELETE CASCADE)
    await supabase.from('publications').delete().eq('id', id);

    // Refresh UI
    setState(() {});
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddFriendsPage()));
    }
  }

  // -------------------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Center(child: Text("ΣSigma", style: TextStyle(color: Colors.white))),
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
              stream: supabase.from('publications').stream(primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final publications = snapshot.data!;
                if (publications.isEmpty) return const Center(child: Text("No publications yet."));

                return ListView.builder(
                  itemCount: publications.length,
                  itemBuilder: (context, index) {
                    final pub = publications[index];
                    final profile = profilesMap[pub['profile_id']];
                    final username = profile?['username'] ?? 'Unknown';
                    final avatarFile = profile?['avatar_url'];
                    final avatarUrl = avatarFile != null ? supabase.storage.from('profile-pictures').getPublicUrl(avatarFile) : null;
                    final isMyPost = supabase.auth.currentUser?.id == pub['profile_id'];

                    return FutureBuilder(
                      future: Future.wait([hasLiked(pub['id']), getLikeCount(pub['id'])]),
                      builder: (context, AsyncSnapshot<List<dynamic>> snap) {
                        if (!snap.hasData) return const SizedBox();

                        final bool liked = snap.data![0];
                        final int likeCount = snap.data![1];

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                          backgroundColor: Colors.grey[300],
                                          child: avatarUrl == null ? const Icon(Icons.person, size: 15) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    if (isMyPost)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deletePublication(pub['id'], pub['image']),
                                      ),
                                  ],
                                ),

                                if (pub['content'] != null) ...[
                                  const SizedBox(height: 5),
                                  Text(pub['content']),
                                ],

                                if (pub['image'] != null) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(pub['image'])),
                                ],

                                // LIKE ROW
                                Row(
                                  children: [
                                    Text("$likeCount likes"),
                                    IconButton(
                                      icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : Colors.grey),
                                      onPressed: () async {
                                        if (liked) {
                                          await unlikePost(pub['id']);
                                        } else {
                                          await likePost(pub['id']);
                                        }
                                        setState(() {});
                                      },
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
                );
              },
            ),
          ),

          // ---------------------------------------------------------------------
          // POST BOX (modified visuals)
          // ---------------------------------------------------------------------
          // POST BOX (modified for web)
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: "Write something...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.image, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // IMAGE PREVIEW IF SELECTED
                if (uploadedImageUrl != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          uploadedImageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              pickedImagePath = null;
                              uploadedImageUrl = null;
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: postPublication,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      backgroundColor: Colors.grey[900],
                    ),
                    child: const Text(
                      "Post",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
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
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Add Friends'),
        ],
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
