import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  final String username;
  const MessagesPage(this.username, {Key? key, required String recipient}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isLoading = false;
  List<dynamic> _messages = [];
  final String _apiUrl = 'http://localhost:5000/api/messages'; // ЗАМЕНИТЕ НА РЕАЛЬНЫЙ URL

  // Дебаг-логирование
  void _log(String message) {
    debugPrint('[${DateTime.now()}] $message');
  }

  @override
  void initState() {
    super.initState();
    _log('Инициализация чата для пользователя: ${widget.username}');
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    _log('Загрузка сообщений...');

    try {
      final uri = Uri.parse('$_apiUrl?username=${widget.username}');
      _log('GET запрос на: $uri');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      _log('Ответ сервера: ${response.statusCode}');
      _log('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('messages')) {
          setState(() {
            _messages = List<dynamic>.from(data['messages']);
            _scrollToBottom();
          });
        } else {
          throw FormatException('Неверный формат данных: ${response.body}');
        }
      } else {
        throw http.ClientException(
          'Ошибка HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      _log('Таймаут запроса');
      _showError('Сервер не отвечает. Проверьте соединение');
    } catch (e) {
      _log('Ошибка: $e');
      _showError('Ошибка загрузки: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage(String text) async {
  if (text.isEmpty || !mounted) return;
  
  setState(() => _isSending = true);
  _log('Отправка сообщения: "$text"');

  try {
    final uri = Uri.parse(_apiUrl);
    final body = jsonEncode({
      'username': widget.username, // Убедитесь, что username не null
      'message': text, // Сервер ожидает поле 'message', а не 'text'
      'timestamp': DateTime.now().toIso8601String(),
    });

    _log('POST запрос на: $uri');
    _log('Тело запроса: $body');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 15));

    _log('Ответ сервера: ${response.statusCode}');
    _log('Тело ответа: ${response.body}');

    if (response.statusCode == 200) {
      _messageController.clear();
      await _loadMessages();
    } else {
      throw http.ClientException(
        'Ошибка HTTP ${response.statusCode}: ${response.body}',
      );
    }
  } on TimeoutException {
    _log('Таймаут отправки');
    _showError('Сервер не отвечает');
  } catch (e) {
    _log('Ошибка отправки: $e');
    _showError('Ошибка: ${e.toString().replaceAll('Exception: ', '')}');
  } finally {
    if (mounted) setState(() => _isSending = false);
  }
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      return DateFormat('HH:mm dd.MM.yyyy').format(DateTime.parse(timestamp));
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат: ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['username'] == widget.username;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message['username'] ?? 'Неизвестный',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              Text(message['text'] ?? ''),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(message['timestamp'] ?? ''),
                                style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: _isSending ? null : (text) => _sendMessage(text),
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () => _sendMessage(_messageController.text),
                      ),
              ],
            ),
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