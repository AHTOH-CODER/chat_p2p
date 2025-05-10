import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'messages_page.dart'; // Импортируем ваш MessagesPage

class ChatsPage extends StatefulWidget {
  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<ChatUser> chatUsers = [];
  bool _isLoading = false;
  final String currentUser = 'current_user'; // Замените на реального пользователя

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/chats?username=$currentUser'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            chatUsers = (data['chats'] as List).map((chat) => ChatUser(
              username: chat['partner'],
              lastMessage: chat['last_message'],
              timestamp: chat['timestamp'],
              unreadCount: chat['unread_count'] ?? 0,
            )).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки чатов: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки чатов')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои чаты'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : chatUsers.isEmpty
              ? Center(child: Text('Нет активных чатов'))
              : ListView.builder(
                  itemCount: chatUsers.length,
                  itemBuilder: (context, index) => _buildChatItem(chatUsers[index]),
                ),
    );
  }

  Widget _buildChatItem(ChatUser user) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.username[0].toUpperCase()),
        ),
        title: Text(user.username),
        subtitle: Text(
          user.lastMessage ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(user.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (user.unreadCount > 0)
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  user.unreadCount.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        onTap: () => _openChat(context, user),
      ),
    );
  }

  void _openChat(BuildContext context, ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesPage(
          user.username,
          recipient: user.username, // Передаем получателя
        ),
      ),
    ).then((_) => _loadChats()); // Обновляем список при возвращении
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

class ChatUser {
  final String username;
  final String? lastMessage;
  final String? timestamp;
  final int unreadCount;

  ChatUser({
    required this.username,
    this.lastMessage,
    this.timestamp,
    this.unreadCount = 0,
  });
}