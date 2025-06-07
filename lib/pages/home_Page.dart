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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

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

  Future<void> _checkAndLoadChats() async {
    List<ChatConversation> localChats = await ChatStorage.loadConversations();
    List<ChatConversation> userLocalChats =
        localChats.where((c) => c.userId == Globals.userId).toList();

    final backendChats = await _fetchChatsFromBackend();

    if (backendChats.isNotEmpty) {
      final needsSync =
          backendChats.length != userLocalChats.length ||
          !_chatsMatch(backendChats, userLocalChats);

      if (needsSync) {
        await ChatStorage.saveConversations(backendChats);
        userLocalChats = backendChats;
      }
    }

    setState(() {
      _chatHistory = userLocalChats;
      if (userLocalChats.isNotEmpty) _loadChat(userLocalChats.last);
    });
  }

  bool _chatsMatch(List<ChatConversation> a, List<ChatConversation> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].title != b[i].title) return false;
    }
    return true;
  }

  Future<List<ChatConversation>> _fetchChatsFromBackend() async {
    try {
      final res = await http.get(
        Uri.parse('${Globals.httpURI}/user/chatsync'),
        headers: {'token': '${Globals.token}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint("chats : $data");
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

    socket = IO.io('${Globals.websocketURI}?chatId=$chatId', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,

      'extraHeaders': {'token': Globals.token!},
      'forceNew': true, // 👈 VERY IMPORTANT: Forces a new connection instance
      'reconnection': false,
    });

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
      // debugPrint('$data');
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

  Future<void> _loadChat(ChatConversation chat) async {
    if (_currentChat?.id != chat.id) {
      socket.dispose(); // Disconnect existing socket
    }

    final List<Map<String, dynamic>> processedMessages = [];

    for (final msg in chat.messages) {
      try {
        if (msg.type == 'image') {
          debugPrint("🖼️ Processing image message: ${msg.content}");

          if (msg.content is String && msg.content.toString().startsWith('/')) {
            final file = File(msg.content);
            if (await file.exists()) {
              debugPrint("✅ Found local file: ${file.path}");
              processedMessages.add({
                'type': 'image',
                'content': file,
                'fromUser': msg.fromUser,
              });
            } else {
              debugPrint("🚫 File does not exist: ${file.path}");
            }
          } else if (msg.content is String &&
              msg.content.toString().startsWith('http')) {
            debugPrint("🌐 Image URL detected: ${msg.content}");
            processedMessages.add({
              'type': 'image',
              'content': msg.content, // String URL
              'fromUser': msg.fromUser,
            });
          } else {
            debugPrint("❌ Invalid image content: ${msg.content}");
          }
        } else {
          debugPrint("💬 Received text: ${msg.content}");
          processedMessages.add({
            'type': 'text',
            'content': msg.content,
            'fromUser': msg.fromUser,
          });
        }
      } catch (e, stack) {
        debugPrint("❗ Error processing message: $e\n$stack");

        continue;
      }
    }

    setState(() {
      _currentChat = chat;
      _messages.clear();
      _messages.addAll(processedMessages);
    });

    await ChatStorage.saveConversation(chat);
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
      // debugPrint('✅ disconnected');
    } catch (e) {
      debugPrint('❌ Error disconnecting socket: $e');
    }
  }

  Future<void> _handleSend(dynamic message) async {
    _focusNode.unfocus();

    if (_currentChat == null) {
      final newChat = ChatConversation(
        userId: Globals.userId,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Chat',
        messages: [],
      );
      _chatHistory.add(newChat);
      await ChatStorage.saveConversations(_chatHistory);
      _currentChat = newChat;
    }

    final isText = message is String;
    debugPrint("✅✅✅✅✅ in handle image or text checking : $message");
    setState(() {
      _messages.add({
        'type': isText ? 'text' : 'image',
        'content': message,
        'fromUser': true,
      });
      _isLoading = true;
    });

    _scrollToBottom();

    final chatId = _currentChat!.id;
    _disposeSocket(); // Ensure fresh connection

    await _connectWebSocket(chatId); // Reconnect with updated ID

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

  Future<bool> updateChatTitle(
    String chatId,
    String newTitle,
    String? accessToken,
  ) async {
    _disposeSocket(); // 👈 Disconnect WebSocket before making HTTP call
    try {
      final response = await http.post(
        Uri.parse('${Globals.httpURI}/user/changeTitle'),
        headers: {
          'Content-Type': 'application/json',
          'token': "$accessToken",
          'chatid': chatId,
        },
        body: jsonEncode({'title': newTitle}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Chat renamed successfully on server');
        // Optional: reload updated chats from backend
        await _checkAndLoadChats();
        return true;
      } else {
        debugPrint('❌ Failed to rename chat: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in updateChatTitle: $e');
      return false;
    }
  }

  Future<String?> _showRenameDialog(String currentName) async {
    TextEditingController controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 249, 249, 249),
          title: const Text(
            'Rename Chat',
            style: TextStyle(color: Color.fromARGB(255, 28, 28, 28)),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Color.fromARGB(255, 18, 18, 18)),
            cursorColor: const Color.fromARGB(255, 16, 15, 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(255, 201, 201, 201),
              hintText: 'Enter new name',
              hintStyle: const TextStyle(
                color: Color.fromARGB(137, 44, 43, 43),
              ),
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
                style: TextStyle(color: Color.fromARGB(219, 0, 0, 0)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 6, 6, 6),
              ),
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text(
                'Rename',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> togglePinStatus(String chatId, String? accessToken) async {
    _disposeSocket(); // 👈 Disconnect WebSocket before making HTTP call
    debugPrint("🔁 Toggling pin status for chatId: $chatId");

    try {
      final response = await http.post(
        Uri.parse('${Globals.httpURI}/user/updatePin'),
        headers: {
          'Content-Type': 'application/json',
          'token': '$accessToken',
          'chatid': chatId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isPinned = data['isPinned'] as bool;
        debugPrint('📌 Chat pin status updated: $isPinned');

        return isPinned;
      } else {
        debugPrint('❌ Failed to toggle pin: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in togglePinStatus: $e');
      return null;
    }
  }

  Future<bool> deleteChatFromBackend(String chatId, String? accessToken) async {
    _disposeSocket(); // 👈 Disconnect WebSocket before HTTP call
    debugPrint("inside delete HTTP request for chatId: ${_currentChat?.id}");

    try {
      final response = await http.post(
        Uri.parse('${Globals.httpURI}/user/deleteChat'),
        headers: {
          'Content-Type': 'application/json',
          'token': '$accessToken',
          'chatid': chatId,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Chat deleted successfully from server');
        return true;
      } else {
        debugPrint('❌ Failed to delete chat: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in deleteChatFromBackend: $e');
      return false;
    }
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          // color: Colors.white70,
          color: Colors.black87,
          fontSize: 14,
          fontFamily: "LexendDeca",
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.black45),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black, fontFamily: "LexendDeca"),
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
      backgroundColor: Colors.white,

      // 🍔 Drawer
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 239, 239, 239),
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
                      "Discussions",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: "LexendDeca",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.black),
                      onPressed: () async {
                        final newChat = ChatConversation(
                          userId: Globals.userId,
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: 'New Chat',
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
                    color: const Color.fromARGB(255, 212, 211, 211),
                    border: Border.all(
                      color: const Color.fromARGB(255, 168, 168, 168),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search chats",
                      hintStyle: TextStyle(
                        color: Colors.black54,
                        fontFamily: "LexendDeca",
                      ),
                      border: InputBorder.none,

                      icon: Icon(Icons.search, color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Pinned section
              if (pinned.isNotEmpty) ...[
                _buildDrawerSectionTitle("Pinned"),
                ...pinned.map((chat) {
                  return ListTile(
                    leading: const Icon(
                      Icons.push_pin_sharp,
                      color: Color.fromARGB(255, 255, 7, 7),
                    ),
                    title: Text(
                      chat.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: "LexendDeca",
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      onSelected: (value) async {
                        if (value == 'rename') {
                          final newName = await _showRenameDialog(chat.title);

                          if (newName != null && newName.trim().isNotEmpty) {
                            debugPrint("✅✅✅✅✅ rename");
                            bool done = await updateChatTitle(
                              chat.id,
                              newName,
                              Globals.token,
                            );
                            if (done) {
                              _connectWebSocket(chat.id);
                              setState(() {
                                chat.title = newName.trim();
                              });
                              await ChatStorage.saveConversations(_chatHistory);
                            }
                          }
                        } else if (value == 'delete') {
                          debugPrint("✅✅✅✅✅ delete");
                          final success = await deleteChatFromBackend(
                            chat.id,
                            Globals.token,
                          );
                          if (success) {
                            setState(() {
                              _chatHistory.remove(chat);
                              if (_currentChat?.id == chat.id) {
                                _messages.clear();
                                _currentChat = null;
                              }
                            });
                            await ChatStorage.saveConversations(_chatHistory);
                          }
                        } else if (value == 'pin') {
                          debugPrint("✅✅✅✅✅ pin/unpin");
                          final newIsPinned = await togglePinStatus(
                            chat.id,
                            Globals.token,
                          );

                          if (newIsPinned != null &&
                              newIsPinned != chat.isPinned) {
                            setState(() {
                              chat.isPinned = newIsPinned;
                              _chatHistory.sort(
                                (a, b) =>
                                    (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0),
                              );
                            });

                            await ChatStorage.saveConversations(_chatHistory);
                          }
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
                      debugPrint("Tapped chat ID: ${chat.id}");
                      setState(() {
                        _loadChat(chat);
                      });
                      Navigator.pop(context);
                      _scrollToBottom();
                    },
                  );
                }).toList(),
                const Divider(color: Colors.black38),
              ],

              // Recent section
              _buildDrawerSectionTitle("Recent"),
              Expanded(
                child:
                    recent.isNotEmpty
                        ? ListView.builder(
                          itemCount: recent.length,
                          itemBuilder: (context, index) {
                            final reversedRecent = recent.reversed.toList();
                            if (index >= reversedRecent.length) {
                              return const SizedBox(); // Or a fallback widget
                            }
                            final chat = reversedRecent[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.forum,

                                color: Colors.black87,
                              ),
                              title: Text(
                                chat.title,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontFamily: "LexendDeca",
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.black87,
                                ),
                                onSelected: (value) async {
                                  if (value == 'rename') {
                                    final newName = await _showRenameDialog(
                                      chat.title,
                                    );

                                    if (newName != null &&
                                        newName.trim().isNotEmpty) {
                                      debugPrint("✅✅✅✅✅ rename");
                                      bool done = await updateChatTitle(
                                        chat.id,
                                        newName,
                                        Globals.token,
                                      );
                                      if (done) {
                                        _connectWebSocket(chat.id);
                                        setState(() {
                                          chat.title = newName.trim();
                                        });
                                        await ChatStorage.saveConversations(
                                          _chatHistory,
                                        );
                                      }
                                    }
                                  } else if (value == 'delete') {
                                    debugPrint("✅✅✅✅✅ delete");
                                    final success = await deleteChatFromBackend(
                                      chat.id,
                                      Globals.token,
                                    );
                                    if (success) {
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
                                    }
                                  } else if (value == 'pin') {
                                    debugPrint("✅✅✅✅✅ pin/unpin");
                                    final newIsPinned = await togglePinStatus(
                                      chat.id,
                                      Globals.token,
                                    );

                                    if (newIsPinned != null &&
                                        newIsPinned != chat.isPinned) {
                                      setState(() {
                                        chat.isPinned = newIsPinned;
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
                                debugPrint("Tapped chat ID: ${chat.id}");
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
                              color: Color.fromARGB(207, 0, 0, 0),
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
                  "assets/icons/menuBlack.svg",
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
                imagePath: Globals.profileImg ?? '',
                isAsset: Globals.profileImg == null,
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
                      final contentRaw = message['content'];

                      String contentStr = '';
                      if (contentRaw is String) {
                        contentStr = contentRaw.trim();
                      } else if (contentRaw is File) {
                        contentStr = contentRaw.path;
                      } else {
                        contentStr = contentRaw.toString().trim();
                      }

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
                                              ? const Color.fromARGB(
                                                255,
                                                215,
                                                215,
                                                215,
                                              )
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      contentStr,
                                      style: TextStyle(
                                        color:
                                            isUser
                                                ? Colors.black87
                                                : Colors.black,
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
                                                  imageContent: contentStr,
                                                ),
                                          ),
                                        );
                                      },
                                      child:
                                          contentStr.startsWith('http')
                                              ? Image.network(
                                                contentStr,
                                                width: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Text(
                                                      '🛑 Failed to load image',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                              )
                                              : Image.file(
                                                File(contentStr),
                                                width: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Text(
                                                      '🛑 Failed to load image',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
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
