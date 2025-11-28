import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String friendId;
  final String friendUsername;
  final String? friendAvatarUrl;

  const ChatPage({
    super.key,
    required this.friendId,
    required this.friendUsername,
    this.friendAvatarUrl,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String? myAvatarUrl;
  String? myUsername;

  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];

  File? _selectedImage; // 👉 preview image before sending

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _loadMyProfile();
    await _loadMessages();
  }

  Future<void> _loadMyProfile() async {
    final user = supabase.auth.currentUser!;
    final data = await supabase
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', user.id)
        .single();

    setState(() {
      myUsername = data['username'];
      myAvatarUrl = data['avatar_url'] != null
          ? supabase.storage
                .from('profile-pictures')
                .getPublicUrl(data['avatar_url'])
          : null;
    });
  }

  Future<void> _loadMessages() async {
    final myId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$myId,receiver_id.eq.${widget.friendId}),'
          'and(sender_id.eq.${widget.friendId},receiver_id.eq.$myId)',
        )
        .order('created_at', ascending: true);

    setState(() {
      _messages = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final user = supabase.auth.currentUser;

    if (user == null) return;
    if (_selectedImage == null && text.isEmpty) return;

    String? imageUrl;

    // 🔥 Upload image if exists
    if (_selectedImage != null) {
      final fileName = "msg_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await supabase.storage
          .from('chat-pictures')
          .upload(fileName, _selectedImage!);

      imageUrl = supabase.storage.from('chat-pictures').getPublicUrl(fileName);
    }

    final messageData = {
      'sender_id': user.id,
      'receiver_id': widget.friendId,
      'content': text.isEmpty ? null : text,
      'image_url': imageUrl,
    };

    try {
      final inserted = await supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      setState(() {
        _messages.add(inserted);
        _selectedImage = null;
        _controller.clear();
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.friendAvatarUrl != null
                  ? NetworkImage(widget.friendAvatarUrl!)
                  : const NetworkImage(
                      "https://cdn-icons-png.flaticon.com/512/149/149071.png",
                    ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.friendUsername,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ---------------- LISTE DES MESSAGES ----------------
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == myId;

                      final avatar = isMe
                          ? myAvatarUrl
                          : widget.friendAvatarUrl;
                      final username = isMe
                          ? myUsername
                          : widget.friendUsername;

                      final createdAt = DateTime.parse(msg['created_at']);
                      final formattedDate = DateFormat(
                        'dd/MM HH:mm',
                      ).format(createdAt);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe)
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: avatar != null
                                    ? NetworkImage(avatar!)
                                    : const NetworkImage(
                                        "https://cdn-icons-png.flaticon.com/512/149/149071.png",
                                      ),
                              ),
                            if (!isMe) const SizedBox(width: 6),

                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username ?? "Unknown",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),

                                  // ----- TEXT MESSAGE -----
                                  if (msg["content"] != null)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        top: 4,
                                        bottom: 3,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.blue
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        msg["content"],
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),

                                  // ----- IMAGE MESSAGE -----
                                  if (msg["image_url"] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        msg["image_url"],
                                        width: 250,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isMe) const SizedBox(width: 6),
                            if (isMe)
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: avatar != null
                                    ? NetworkImage(avatar!)
                                    : const NetworkImage(
                                        "https://cdn-icons-png.flaticon.com/512/149/149071.png",
                                      ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ---------------- PREVIEW IMAGE ----------------
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // ---------------- INPUT BAR ----------------
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.green),
                  onPressed: _pickImage,
                ),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
