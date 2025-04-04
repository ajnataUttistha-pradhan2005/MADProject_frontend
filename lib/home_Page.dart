import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mathsolver/components/gradient_Avatar.dart';
import 'package:mathsolver/components/prompt_bar.dart'; // Import PromptBar
import 'package:mathsolver/components/Loading_Widget.dart'; // Import the LoadingWidget
import 'package:mathsolver/components/welcome_intro.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _isLoading = false; // Track loading state
  final ScrollController _scrollController =
      ScrollController(); // ScrollController

  void _handleSend(String message) {
    setState(() {
      _messages.add(message);
      _isLoading = true; // Start loading when sending a message
    });

    // Scroll to the bottom immediately after the message is sent
    _scrollToBottom();

    // Simulate a WebSocket response delay (replace with actual WebSocket code)
    _simulateWebSocketResponse();
  }

  // Simulate a WebSocket response (you would replace this with your actual WebSocket code)
  Future<void> _simulateWebSocketResponse() async {
    // Simulate a 5-second delay to mimic WebSocket response time
    await Future.delayed(const Duration(seconds: 5));

    // Simulate the response text from the WebSocket
    String response = "This is the WebSocket response text.";

    // Update the UI after the WebSocket response
    setState(() {
      _messages.add(response); // Add the response to the messages list
      _isLoading = false; // Stop loading after receiving the response
    });

    // Scroll to the bottom after the WebSocket response is received
    _scrollToBottom();
  }

  // Scroll to the bottom of the ListView
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Scroll to the last item (with a small offset to ensure visibility)
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent +
            400, // Add a small offset to scroll up a bit
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
      body: Column(
        children: [
          // Display WelcomeIntro only if _messages is empty
          if (_messages.isEmpty) const WelcomeIntro(),

          // The list of messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Set the scroll controller
              padding: const EdgeInsets.all(16),
              itemCount:
                  _messages.length +
                  (_isLoading ? 1 : 0), // Add 1 for the loading widget
              itemBuilder: (context, index) {
                // If loading, show the loading widget
                if (_isLoading && index == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: LoadingWidget(),
                  );
                }

                // Check if the message is the WebSocket response (for left-alignment)
                bool isUserMessage = index % 2 == 0;

                return Align(
                  alignment:
                      isUserMessage
                          ? Alignment
                              .centerRight // User messages are right-aligned
                          : Alignment
                              .centerLeft, // WebSocket responses are left-aligned
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child:
                        isUserMessage
                            ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF29292B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _messages[index],
                                style: const TextStyle(
                                  color: Color(0xFFB3B3B3),
                                  fontFamily: "LexendDeca",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            )
                            : Text(
                              _messages[index], // WebSocket response without box
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: "LexendDeca",
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                  ),
                );
              },
            ),
          ),

          // Pass the isLoading state to the PromptBar to toggle the icon
          PromptBar(
            controller: _controller,
            onSend: _handleSend,
            isLoading: _isLoading, // Pass the loading state to toggle the icon
          ),
        ],
      ),
    );
  }
}
