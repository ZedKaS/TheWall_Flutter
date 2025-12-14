import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'add_friends_page.dart';

class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({super.key});

  @override
  _FollowRequestsPageState createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  final supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _followRequests;

  @override
  void initState() {
    super.initState();
    _followRequests = _fetchFollowRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchFollowRequests() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('follow_requests')
          .select('''
          id,
          sender_id,
          receiver_id,
          status,
          created_at,
          sender:sender_id (
            username,
            avatar_url
          ),
          receiver:receiver_id (
            username,
            avatar_url
          )
        ''')
          .or('sender_id.eq.${user.id}, receiver_id.eq.${user.id}');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> _acceptFollowRequest(String requestId, String senderId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    await supabase.from('follow_requests').delete().eq('id', requestId);
    await supabase.from('friends').insert([
      {'user_id': currentUser.id, 'friend_id': senderId},
      {'user_id': senderId, 'friend_id': currentUser.id},
    ]);

    setState(() {
      _followRequests = _fetchFollowRequests();
    });
  }

  Future<void> _rejectFollowRequest(String requestId) async {
    await supabase.from('follow_requests').delete().eq('id', requestId);
    setState(() {
      _followRequests = _fetchFollowRequests();
    });
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddFriendsPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("Follow Requests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _followRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No follow requests."));
          }

          final requests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final senderId = request['sender_id'];
              final isSender = currentUser?.id == senderId;

              final userData = isSender ? request['receiver'] : request['sender'];
              final username = userData?['username'] ?? 'Unknown';
              final avatarPath = userData?['avatar_url'];

              final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
                  ? supabase.storage.from('profile-pictures').getPublicUrl(avatarPath)
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : const NetworkImage("https://cdn-icons-png.flaticon.com/512/149/149071.png"),
                  ),
                  title: Text(isSender ? "Request to $username" : "Request from $username"),
                  subtitle: Text("Status: ${request['status']}\nCreated at: ${request['created_at']}"),
                  trailing: isSender
                      ? null
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptFollowRequest(request['id'], senderId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectFollowRequest(request['id']),
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
        currentIndex: 3,
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
