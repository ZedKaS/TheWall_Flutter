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
  final TextEditingController _editController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String? myAvatarUrl;
  String? myUsername;

  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _loadMyProfile();
    await _loadMessages();
    await _markAsSeen();
  }

  // Charger mon profil
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

  // Charger les messages
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

  // Marquer messages reçus comme vus
  Future<void> _markAsSeen() async {
    final myId = supabase.auth.currentUser!.id;

    await supabase
        .from('messages')
        .update({'seen': true})
        .eq('receiver_id', myId)
        .eq('sender_id', widget.friendId)
        .eq('seen', false);

    await _loadMessages();
  }

  // Scroll auto
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // 🔥 Modifier un message envoyé
  Future<void> _editMessage(String messageId, String oldText) async {
    _editController.text = oldText;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le message"),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(labelText: "Nouveau message"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = _editController.text.trim();
              if (newText.isEmpty) return;

              await supabase
                  .from('messages')
                  .update({'content': newText})
                  .eq('id', messageId);

              Navigator.pop(context);
              await _loadMessages();
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  // 🔥 Supprimer un message envoyé
  Future<void> _deleteMessage(String messageId) async {
    await supabase.from('messages').delete().eq('id', messageId);
    await _loadMessages();
  }

  // 🔥 Menu d’options (modifier / supprimer)
  void _showMessageOptions(Map msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Modifier"),
              onTap: () {
                Navigator.pop(context);
                _editMessage(msg['id'], msg['content'] ?? "");
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Supprimer"),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Annuler"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Envoyer message
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final user = supabase.auth.currentUser;

    if (user == null) return;
    if (_selectedImage == null && text.isEmpty) return;

    String? imageUrl;

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

    final inserted = await supabase
        .from('messages')
        .insert(messageData)
        .select()
        .single();

    setState(() {
      _messages.add(inserted);
      _controller.clear();
      _selectedImage = null;
    });

    _scrollToBottom();
  }

  // Choisir image
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.all(10),
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
                      final formatted = DateFormat(
                        'dd/MM HH:mm',
                      ).format(createdAt);

                      return GestureDetector(
                        onLongPress: () {
                          if (isMe) _showMessageOptions(msg);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: avatar != null
                                      ? NetworkImage(avatar!)
                                      : null,
                                ),
                              if (!isMe) const SizedBox(width: 6),

                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username ?? "",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    if (msg["content"] != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(
                                          top: 4,
                                          bottom: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.black
                                              : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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

                                    if (msg["image_url"] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          msg["image_url"],
                                          width: 250,
                                          fit: BoxFit.cover,
                                        ),
                                      ),

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formatted,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.done_all,
                                          size: 16,
                                          color: msg['seen'] == true
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ],
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
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          // Barre d’envoi
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
                      hintText: "Message…",
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
