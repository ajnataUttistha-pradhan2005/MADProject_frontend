import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

class ChatStorage {
  static const _key = 'chat_conversations';

  static Future<List<ChatConversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('chat_conversations') ?? [];
    return jsonList
        .map((json) => ChatConversation.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveConversations(List<ChatConversation> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = chats.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('chat_conversations', jsonList);
  }

  static Future<void> saveConversation(ChatConversation conversation) async {
    final chats = await loadConversations();
    final index = chats.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      chats[index] = conversation;
    } else {
      chats.add(conversation);
    }
    await saveConversations(chats);
  }

  static Future<void> presentStoredConversations() async {
    final chats = await loadConversations();
    if (chats.isEmpty) {
      print('❌ No stored conversations.');
      return;
    }

    print('✅ Stored Conversations:');
    for (var chat in chats) {
      print('---------------------------');
      print('ID: ${chat.id}');
      print('Title: ${chat.title}');
      print('Messages Count: ${chat.messages.length}');
      print('Is Pinned: ${chat.isPinned}');
    }
    print('---------------------------');
  }
}
