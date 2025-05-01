import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mathsolver/components/gradient_Avatar.dart';
import 'package:mathsolver/components/prompt_bar.dart';
import 'package:mathsolver/components/Loading_Widget.dart';
import 'package:mathsolver/components/welcome_intro.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isTextBoxFocused = false;

  void _handleSend(dynamic message) {
    setState(() {
      _messages.add({
        'type': message is String ? 'text' : 'image',
        'content': message,
        'fromUser': true,
      });
      _isLoading = true;
    });

    _scrollToBottom();
    _simulateWebSocketResponse();
  }

  void _onTextBoxFocusChanged(bool focused) {
    setState(() {
      _isTextBoxFocused = focused;
    });
  }

  Future<void> _simulateWebSocketResponse() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _messages.add({
        'type': 'text',
        'content': "This is the WebSocket response text.",
        'fromUser': false,
      });
      _isLoading = false;
    });
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(10),
          child: SvgPicture.asset(
            "assets/icons/menu.svg",
            height: 31,
            width: 37,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GradientAvatar(
              imageUrl: 'assets/icons/profileImg.jpeg',
              isAsset: true,
              size: 50,
              borderWidth: 3,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(
              bottom: 0,
              // MediaQuery.of(context).viewInsets.bottom, this line very buggy
            ),

            child: Column(
              children: [
                if (_messages.isEmpty && !_isTextBoxFocused)
                  const WelcomeIntro(),
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(content.path),
                                      width: 220,
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
                  onFocusChange: _onTextBoxFocusChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// incase want before body 
      // body: Column(
      //   children: [
      //     // Display WelcomeIntro only if _messages is empty
      //     if (_messages.isEmpty) const WelcomeIntro(),

      //     // The list of messages
      //     Expanded(
      //       child: ListView.builder(
      //         controller: _scrollController, // Set the scroll controller
      //         padding: const EdgeInsets.all(16),
      //         itemCount:
      //             _messages.length +
      //             (_isLoading ? 1 : 0), // Add 1 for the loading widget
      //         itemBuilder: (context, index) {
      //           // If loading, show the loading widget
      //           if (_isLoading && index == _messages.length) {
      //             return Padding(
      //               padding: const EdgeInsets.symmetric(vertical: 20.0),
      //               child: LoadingWidget(),
      //             );
      //           }

      //           // Check if the message is the WebSocket response (for left-alignment)
      //           bool isUserMessage = index % 2 == 0;

      //           return Align(
      //             alignment:
      //                 isUserMessage
      //                     ? Alignment
      //                         .centerRight // User messages are right-aligned
      //                     : Alignment
      //                         .centerLeft, // WebSocket responses are left-aligned
      //             child: Padding(
      //               padding: const EdgeInsets.symmetric(vertical: 5),
      //               child:
      //                   isUserMessage
      //                       ? Container(
      //                         padding: const EdgeInsets.all(12),
      //                         decoration: BoxDecoration(
      //                           color: const Color(0xFF29292B),
      //                           borderRadius: BorderRadius.circular(20),
      //                         ),
      //                         child: Text(
      //                           _messages[index],
      //                           style: const TextStyle(
      //                             color: Color(0xFFB3B3B3),
      //                             fontFamily: "LexendDeca",
      //                             fontWeight: FontWeight.w700,
      //                             fontSize: 15,
      //                           ),
      //                         ),
      //                       )
      //                       : Text(
      //                         _messages[index], // WebSocket response without box
      //                         style: const TextStyle(
      //                           color: Colors.white,
      //                           fontFamily: "LexendDeca",
      //                           fontWeight: FontWeight.w700,
      //                           fontSize: 16,
      //                         ),
      //                       ),
      //             ),
      //           );
      //         },
      //       ),
      //     ),

      //     // Pass the isLoading state to the PromptBar to toggle the icon
      //     PromptBar(
      //       controller: _controller,
      //       onSend: _handleSend,
      //       isLoading: _isLoading, // Pass the loading state to toggle the icon
      //     ),
      //   ],
      // ),
