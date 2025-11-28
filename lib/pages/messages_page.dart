import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'add_friends_page.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  String? myUsername;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _fetchFriends();
    _loadMyUsername();
  }

  Future<void> _loadMyUsername() async {
    final user = supabase.auth.currentUser!;
    final data = await supabase
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .single();

    setState(() {
      myUsername = data['username'];
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFriends() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('friends')
        .select('''
          id,
          user_id,
          friend_id,
          created_at,
          friend:user_id (username, avatar_url),
          me:friend_id (username, avatar_url)
        ''')
        .or('user_id.eq.${user.id}, friend_id.eq.${user.id}');

    final rows = List<Map<String, dynamic>>.from(response);

    final myId = user.id;
    final Map<String, Map<String, dynamic>> uniqueFriends = {};

    for (var row in rows) {
      final iAmUser = row['user_id'] == myId;
      final friendId = iAmUser ? row['friend_id'] : row['user_id'];
      final friendData = iAmUser ? row['me'] : row['friend'];

      uniqueFriends[friendId] = {
        'id': friendId,
        'username': friendData['username'],
        'avatar_url': friendData['avatar_url'],
        'created_at': row['created_at'],
      };
    }

    return uniqueFriends.values.toList();
  }

  // 🔥 Unread message count
  Future<int> _getUnreadCount(String friendId) async {
    final myId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('messages')
        .select()
        .eq('sender_id', friendId)
        .eq('receiver_id', myId)
        .eq('seen', false);

    return response.length;
  }

  Future<String> _getLastMessage(String friendId, String friendUsername) async {
    final myId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$myId,receiver_id.eq.$friendId),'
          'and(sender_id.eq.$friendId,receiver_id.eq.$myId)',
        )
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) return "No messages yet";

    final msg = response.first;

    final isMe = msg['sender_id'] == myId;
    final senderName = isMe ? "@$myUsername" : "@$friendUsername";

    final text = msg["content"];
    final image = msg["image_url"];

    if (text != null && image != null) return "$senderName 📷 + $text";
    if (image != null) return "$senderName 📷 Photo";
    if (text != null) return "$senderName $text";

    return "$senderName Message";
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AddFriendsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("Messages", style: TextStyle(color: Colors.white)),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || myUsername == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          final friends = snapshot.data!;
          if (friends.isEmpty) {
            return const Center(child: Text("You have no friends yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final friendId = friend['id'];
              final username = friend['username'];
              final avatarPath = friend['avatar_url'];

              final avatarUrl = avatarPath != null
                  ? supabase.storage
                        .from('profile-pictures')
                        .getPublicUrl(avatarPath)
                  : null;

              return FutureBuilder(
                future: Future.wait([
                  _getLastMessage(friendId, username),
                  _getUnreadCount(friendId),
                ]),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const SizedBox();
                  }

                  final lastMessage = snap.data![0] as String;
                  final unreadCount = snap.data![1] as int;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl!)
                            : const NetworkImage(
                                "https://cdn-icons-png.flaticon.com/512/149/149071.png",
                              ),
                      ),

                      title: Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      trailing: unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,

                      onTap: () async {
                        // Marquer comme lus
                        final myId = supabase.auth.currentUser!.id;

                        await supabase
                            .from('messages')
                            .update({'seen': true})
                            .eq('sender_id', friendId)
                            .eq('receiver_id', myId)
                            .eq('seen', false);

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              friendId: friendId,
                              friendUsername: username,
                              friendAvatarUrl: avatarUrl,
                            ),
                          ),
                        );

                        setState(() {
                          _friendsFuture = _fetchFriends();
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) => _onNavTap(context, index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
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
