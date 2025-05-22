import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mathsolver/components/gradient_Avatar.dart';
import 'package:mathsolver/components/prompt_bar.dart';
import 'package:mathsolver/components/Loading_Widget.dart';
import 'package:mathsolver/components/welcome_intro.dart';
import 'package:mathsolver/globals.dart';
import 'package:mathsolver/pages/profile_page.dart';
import 'package:mathsolver/pages/image_viewer_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mathsolver/models/chat_models.dart';
import 'package:mathsolver/services/chat_storage.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  late FocusNode _focusNode;

  bool _isLoading = false;
  bool _isTextBoxFocused = false;
  late IO.Socket socket = IO.io('wss://dummy', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  List<ChatConversation> _chatHistory = [];
  ChatConversation? _currentChat;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // _initSocket();
    if (Globals.token != null) {
      _checkAndLoadChats();
    }
  }

  void _checkAndLoadChats() async {
    List<ChatConversation> localChats = await ChatStorage.loadConversations();

    // If local is empty, fetch from backend
    if (localChats.isEmpty) {
      final fetched = await _fetchChatsFromBackend();
      if (fetched.isNotEmpty) {
        await ChatStorage.saveConversations(fetched);
        localChats = fetched;
      }
    }

    setState(() {
      _chatHistory = localChats;
      if (localChats.isNotEmpty) _loadChat(localChats.last);
    });
  }

  Future<List<ChatConversation>> _fetchChatsFromBackend() async {
    try {
      final res = await http.get(
        Uri.parse('${Globals.httpURI}/chatsync'),
        headers: {'token': '${Globals.token}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['chats'] as List)
            .map((c) => ChatConversation.fromJson(c))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch chats: $e');
    }
    return [];
  }

  Future<void> _connectWebSocket(String chatId) async {
    if (Globals.token == null || Globals.token!.isEmpty) return;

    // Dispose previous if any
    try {
      if (socket.connected) socket.disconnect();
      socket.dispose();
    } catch (_) {}

    debugPrint("berfore chatId : $chatId");
    debugPrint("token : ${Globals.token}");

    socket = IO.io(
      '${Globals.websocketURI}?chatId=$chatId', // 👈 Make URI unique
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        // 'query': {'token': Globals.token!, 'chatId': chatId},
        'extraHeaders': {'token': Globals.token!},
        'forceNew': true, // 👈 VERY IMPORTANT: Forces a new connection instance
        'reconnection': false,
      },
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('✅ Connected to WebSocket');
      debugPrint('🔗 Connecting socket with chatId: $chatId');
    });

    socket.on('bot_response', (data) {
      String message;

      if (data is String) {
        message = data;
      } else if (data is Map && data.containsKey('text')) {
        message = data['text'];
      } else {
        message = jsonEncode(data); // fallback to avoid crash
      }
      debugPrint('$data');
      setState(() {
        _messages.add({'type': 'text', 'content': message, 'fromUser': false});
        _isLoading = false;
      });
      _scrollToBottom();

      if (_currentChat != null) {
        _currentChat!.messages.add(
          ChatMessage(type: 'text', content: message, fromUser: false),
        );
        ChatStorage.saveConversation(_currentChat!);
      }
    });

    socket.onDisconnect((_) => debugPrint('❌ Disconnected'));
    socket.onError((err) => debugPrint('⚠️ Error: $err'));
  }

  void _loadChat(ChatConversation chat) {
    if (_currentChat?.id != chat.id) {
      socket.dispose(); // Disconnect existing socket
    }

    setState(() {
      _currentChat = chat;
      _messages.clear();
      _messages.addAll(
        chat.messages
            .map((m) {
              if (m.type == 'image') {
                final file = File(m.content);
                return {
                  'type': 'image',
                  'content': file.existsSync() ? file : null,
                  'fromUser': m.fromUser,
                };
              } else {
                return {
                  'type': 'text',
                  'content': m.content,
                  'fromUser': m.fromUser,
                };
              }
            })
            .where((m) => m['content'] != null)
            .toList(),
      );
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    socket.dispose();
    super.dispose();
  }

  void _disposeSocket() {
    try {
      if (socket.connected) socket.disconnect();
      socket.dispose();
    } catch (e) {
      debugPrint('Socket disposal error: $e');
    }
  }

  void _handleSend(dynamic message) async {
    _focusNode.unfocus();

    // Step 1: Create a new chat if needed
    if (_currentChat == null) {
      final newChat = ChatConversation(
        userId: Globals.userId,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Chat',
        messages: [],
      );
      _chatHistory.add(newChat);
      await ChatStorage.saveConversations(_chatHistory);
      _currentChat = newChat; // ✅ No setState here – avoid race condition
    }

    final isText = message is String;

    // Step 2: Add user message to UI
    setState(() {
      _messages.add({
        'type': isText ? 'text' : 'image',
        'content': message,
        'fromUser': true,
      });
      _isLoading = true;
    });

    _scrollToBottom();

    // ✅ Step 3: Connect socket with guaranteed correct chat ID
    final chatId = _currentChat!.id;
    _disposeSocket();
    if (!socket.connected ||
        socket.io.uri != Globals.websocketURI ||
        socket.io.options?['extraHeaders']?['chatId'] != chatId) {
      await _connectWebSocket(chatId);
    }

    // Step 4: Emit message
    if (isText) {
      socket.emit('user_message', {'type': 'text', 'text': message});
    } else {
      try {
        final file =
            message is XFile
                ? await message.readAsBytes()
                : await (message as File).readAsBytes();
        final base64Image = base64Encode(file);
        socket.emit('user_message', {'type': 'image', 'base64': base64Image});
      } catch (e) {
        debugPrint("❌ Error sending image: $e");
      }
    }

    // Step 5: Save message locally
    if (_currentChat != null) {
      _currentChat!.messages.add(
        ChatMessage(
          type: isText ? 'text' : 'image',
          content: isText ? message : (message as File).path,
          fromUser: true,
        ),
      );
      final index = _chatHistory.indexWhere((c) => c.id == _currentChat!.id);
      if (index != -1) _chatHistory[index] = _currentChat!;
      await ChatStorage.saveConversations(_chatHistory);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 400,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onTextBoxFocusChanged(bool focused) {
    setState(() {
      _isTextBoxFocused = focused;
    });
  }

  Future<String?> _showRenameDialog(String currentName) async {
    TextEditingController controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Rename Chat',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              hintText: 'Enter new name',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 227, 230, 227),
              ),
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontFamily: "LexendDeca",
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontFamily: "LexendDeca"),
      ),
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinned = _chatHistory.where((c) => c.isPinned).toList();
    final recent = _chatHistory.where((c) => !c.isPinned).toList();

    return Scaffold(
      backgroundColor: Colors.black,

      // 🍔 Drawer
      drawer: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Conversations",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: "LexendDeca",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        final newChat = ChatConversation(
                          userId: Globals.userId,
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: 'New Chat', // Changed from 'Chat X'
                          messages: [],
                        );
                        setState(() {
                          _chatHistory.add(newChat);
                          _currentChat = newChat;
                          _messages.clear();
                        });
                        await ChatStorage.saveConversations(_chatHistory);
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search chats",
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontFamily: "LexendDeca",
                      ),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Pinned section
              if (pinned.isNotEmpty) ...[
                _buildDrawerSectionTitle("📌 Pinned"),
                ...pinned.map((chat) {
                  return ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(
                      chat.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "LexendDeca",
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onSelected: (value) async {
                        if (value == 'rename') {
                          final newName = await _showRenameDialog(chat.title);
                          if (newName != null && newName.trim().isNotEmpty) {
                            setState(() {
                              chat.title = newName.trim();
                            });
                            await ChatStorage.saveConversations(_chatHistory);
                          }
                        } else if (value == 'delete') {
                          setState(() {
                            _chatHistory.remove(chat);
                            if (_currentChat?.id == chat.id) {
                              _messages.clear();
                              _currentChat = null;
                            }
                          });
                          await ChatStorage.saveConversations(_chatHistory);
                        } else if (value == 'pin') {
                          setState(() {
                            chat.isPinned = !chat.isPinned;
                            _chatHistory.sort(
                              (a, b) =>
                                  (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0),
                            );
                          });
                          await ChatStorage.saveConversations(_chatHistory);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(chat.isPinned ? 'Unpin' : 'Pin'),
                            ),
                          ],
                    ),
                    onTap: () {
                      setState(() {
                        _loadChat(chat);
                      });
                      Navigator.pop(context);
                      _scrollToBottom();
                    },
                  );
                }).toList(),
                const Divider(color: Colors.white24),
              ],

              // Recent section
              _buildDrawerSectionTitle("🕒 Recent"),
              Expanded(
                child:
                    recent.isNotEmpty
                        ? ListView.builder(
                          itemCount: recent.length,
                          itemBuilder: (context, index) {
                            final chat = recent[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white70,
                              ),
                              title: Text(
                                chat.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: "LexendDeca",
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white70,
                                ),
                                onSelected: (value) async {
                                  if (value == 'rename') {
                                    final newName = await _showRenameDialog(
                                      chat.title,
                                    );
                                    if (newName != null &&
                                        newName.trim().isNotEmpty) {
                                      setState(() {
                                        chat.title = newName.trim();
                                      });
                                      await ChatStorage.saveConversations(
                                        _chatHistory,
                                      );
                                    }
                                  } else if (value == 'delete') {
                                    setState(() {
                                      _chatHistory.remove(chat);
                                      if (_currentChat?.id == chat.id) {
                                        _messages.clear();
                                        _currentChat = null;
                                      }
                                    });
                                    await ChatStorage.saveConversations(
                                      _chatHistory,
                                    );
                                  } else if (value == 'pin') {
                                    setState(() {
                                      chat.isPinned = !chat.isPinned;
                                      _chatHistory.sort(
                                        (a, b) =>
                                            (b.isPinned ? 1 : 0) -
                                            (a.isPinned ? 1 : 0),
                                      );
                                    });
                                    await ChatStorage.saveConversations(
                                      _chatHistory,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Text('Rename'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                      PopupMenuItem(
                                        value: 'pin',
                                        child: Text(
                                          chat.isPinned ? 'Unpin' : 'Pin',
                                        ),
                                      ),
                                    ],
                              ),
                              onTap: () {
                                setState(() {
                                  _loadChat(chat);
                                });
                                Navigator.pop(context);
                                _scrollToBottom();
                              },
                            );
                          },
                        )
                        : const Center(
                          child: Text(
                            "No more chats yet",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontFamily: "LexendDeca",
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: SvgPicture.asset(
                  "assets/icons/menu.svg",
                  height: 31,
                  width: 37,
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: GradientAvatar(
                imageUrl: 'assets/icons/profileImg.jpeg',
                isAsset: true,
                size: 50,
                borderWidth: 3,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              if (_messages.isEmpty && !_isTextBoxFocused)
                const Flexible(child: WelcomeIntro()),

              if (_messages.isNotEmpty || _isTextBoxFocused)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: LoadingWidget(),
                        );
                      }

                      final message = _messages[index];
                      final isUser = message['fromUser'] ?? false;
                      final type = message['type'];
                      final content = message['content'];

                      return Align(
                        alignment:
                            isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child:
                              type == 'text'
                                  ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isUser
                                              ? const Color(0xFF29292B)
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      content,
                                      style: TextStyle(
                                        color:
                                            isUser
                                                ? const Color(0xFFB3B3B3)
                                                : Colors.white,
                                        fontFamily: "LexendDeca",
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ImageViewerPage(
                                                  imageFile: content,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Image.file(
                                        content as File,
                                        width: 200,
                                      ),
                                    ),
                                  ),
                        ),
                      );
                    },
                  ),
                ),

              PromptBar(
                controller: _controller,
                onSend: _handleSend,
                isLoading: _isLoading,
                focusNode: _focusNode,
                onFocusChange: _onTextBoxFocusChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
