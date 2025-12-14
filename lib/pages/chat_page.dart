import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

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

  /// ✅ IMAGE (Mobile / Web)
  File? _selectedImage; // Android / iOS
  Uint8List? _webImageBytes; // Web

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

  // -------------------- PROFIL --------------------

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

  // -------------------- MESSAGES --------------------

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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // -------------------- IMAGE PICK --------------------

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImageBytes = bytes;
        _selectedImage = null;
      });
    } else {
      setState(() {
        _selectedImage = File(picked.path);
        _webImageBytes = null;
      });
    }
  }

  // -------------------- SEND MESSAGE --------------------

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final user = supabase.auth.currentUser;
    if (user == null) return;
    if (text.isEmpty && _selectedImage == null && _webImageBytes == null)
      return;

    String? imageUrl;

    /// ✅ UPLOAD IMAGE
    if (_selectedImage != null || _webImageBytes != null) {
      final fileName = 'msg_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb && _webImageBytes != null) {
        await supabase.storage
            .from('chat-pictures')
            .uploadBinary(
              fileName,
              _webImageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else if (_selectedImage != null) {
        await supabase.storage
            .from('chat-pictures')
            .upload(fileName, _selectedImage!);
      }

      imageUrl = supabase.storage.from('chat-pictures').getPublicUrl(fileName);
    }

    final inserted = await supabase
        .from('messages')
        .insert({
          'sender_id': user.id,
          'receiver_id': widget.friendId,
          'content': text.isEmpty ? null : text,
          'image_url': imageUrl,
        })
        .select()
        .single();

    setState(() {
      _messages.add(inserted);
      _controller.clear();
      _selectedImage = null;
      _webImageBytes = null;
    });

    _scrollToBottom();
  }

  // -------------------- UI --------------------

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
          // -------------------- LIST MESSAGES --------------------
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == myId;
                      final createdAt = DateTime.parse(msg['created_at']);
                      final formatted = DateFormat(
                        'dd/MM HH:mm',
                      ).format(createdAt);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (msg['content'] != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  msg['content'],
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),

                            if (msg['image_url'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    msg['image_url'],
                                    width: 250,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            Text(
                              formatted,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // -------------------- IMAGE PREVIEW --------------------
          if (_selectedImage != null || _webImageBytes != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.memory(
                            _webImageBytes!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() {
                      _selectedImage = null;
                      _webImageBytes = null;
                    }),
                  ),
                ],
              ),
            ),

          // -------------------- INPUT --------------------
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
