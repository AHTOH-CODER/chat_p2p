import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  final String username;
  
  const MessagesPage(this.username, {Key? key}) : super(key: key);
  
  @override 
  _MessagesPageState createState() => _MessagesPageState(); 
} 

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isLoading = false;
  List<dynamic> _messages = [];
  final String _apiUrl = 'http://your-api-url.com/api'; // Замените на реальный URL

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/messages?username=${widget.username}'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _messages = jsonDecode(response.body)['messages'];
          _scrollToBottom();
        });
      } else {
        _showError('Ошибка загрузки сообщений');
      }
    } catch (e) {
      _showError('Ошибка сети: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;
    
    setState(() => _isSending = true);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'message': text,
        }),
      );
      
      if (response.statusCode == 200) {
        _messageController.clear();
        await _loadMessages(); // Обновляем список сообщений
      } else {
        _showError('Ошибка отправки сообщения');
      }
    } catch (e) {
      _showError('Ошибка сети: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      )
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('HH:mm dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: _isLoading && _messages.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message['username'] == widget.username;
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            margin: EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe 
                                  ? Colors.blue.withOpacity(0.2) 
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    message['username'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                SizedBox(height: 4),
                                Text(
                                  message['text'],
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(message['timestamp']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Мой профиль',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Чаты'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/chats');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Настройки'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Введите сообщение...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (text) => _sendMessage(text),
            ),
          ),
          SizedBox(width: 8),
          _isSending
              ? CircularProgressIndicator()
              : IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}