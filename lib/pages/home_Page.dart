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
import 'package:mathsolver/pages/profile_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io('wss://endpoint', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('✅ Connected to WebSocket');
    });

    socket.on('bot_response', (data) {
      print("🤖 Bot Response: $data");
      setState(() {
        _messages.add({'type': 'text', 'content': data, 'fromUser': false});
        _isLoading = false;
      });
      _scrollToBottom();
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from WebSocket');
    });

    socket.onError((err) {
      print('⚠️ Socket error: $err');
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    socket.dispose();
    super.dispose();
  }

  void _handleSend(dynamic message) async {
    _focusNode.unfocus();

    final isText = message is String;
    final messageData = {
      'type': isText ? 'text' : 'image',
      'content': message,
      'fromUser': true,
    };

    setState(() {
      _messages.add(messageData);
      _isLoading = true;
    });

    _scrollToBottom();

    if (isText) {
      socket.emit('user_message', {'type': 'text', 'text': message});
      debugPrint("✅ Text sent successfully.");
    } else if (message is XFile) {
      try {
        final bytes = await message.readAsBytes();
        final base64Image = base64Encode(bytes);
        socket.emit('user_message', {'type': 'image', 'base64': base64Image});
        debugPrint("✅ Image sent successfully (XFile).");
      } catch (e) {
        debugPrint("❌ Error sending image from XFile: $e");
      }
    } else if (message is File) {
      try {
        final bytes = await message.readAsBytes();
        final base64Image = base64Encode(bytes);
        socket.emit('user_message', {'type': 'image', 'base64': base64Image});
        debugPrint("✅ Image sent successfully (File).");
      } catch (e) {
        debugPrint("❌ Error sending image from File: $e");
      }
    } else {
      debugPrint("⚠️ Unsupported message type: ${message.runtimeType}");
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
    return Scaffold(
      backgroundColor: Colors.black,

      // 🍔 Drawer
      drawer: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  "Conversations",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: "LexendDeca",
                  ),
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
              _buildDrawerSectionTitle("📌 Pinned"),
              _buildDrawerItem("Math Doubt with AI", Icons.star),
              const Divider(color: Colors.white24),
              _buildDrawerSectionTitle("🕒 Recent"),
              _buildDrawerItem("Chat #1", Icons.chat_bubble_outline),
              _buildDrawerItem("Chat #2", Icons.chat_bubble_outline),
              const Expanded(
                child: Center(
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
                const Expanded(child: WelcomeIntro()),

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
                                    child: Image.file(
                                      content as File,
                                      width: 200,
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
