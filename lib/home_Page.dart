import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mathsolver/components/gradient_Avatar.dart';
import 'package:mathsolver/components/prompt_bar.dart'; // Import PromptBar

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  void _handleSend(String message) {
    setState(() {
      _messages.add(message);
    });
    for (var i = 0; i < _messages.length; i++) {
      print(_messages[i]);
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _messages[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          PromptBar(controller: _controller, onSend: _handleSend),
        ],
      ),
    );
  }
}
