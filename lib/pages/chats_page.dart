import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chat_p2p/pages/messages_page.dart';

class ChatsPage extends StatefulWidget {
  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<String> chatUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChatUsers();
  }

  Future<void> fetchChatUsers() async {
    try {
      // In a real app, you would replace 'current_user' with the actual logged-in user
      final response = await http.get(
        Uri.parse('http://your-server-ip:5000/api/messages?username=current_user'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Extract unique users from messages
        // Note: This is a simplified approach - in a real app you'd have a proper user list endpoint
        final messages = data['messages'] as List;
        final users = messages.map((msg) => msg['username'] as String).toSet().toList();
        
        setState(() {
          chatUsers = users;
          isLoading = false;
        });
      } else {
        // If the server returns an error response, use default users
        setState(() {
          chatUsers = ['user1', 'user2', 'user3'];
          isLoading = false;
        });
      }
    } catch (e) {
      // If there's an error (like no internet), use default users
      print('Error fetching users: $e');
      setState(() {
        chatUsers = ['user1', 'user2', 'user3'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
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
                      backgroundImage: NetworkImage(
                          'https://example.com/profile.jpg'),
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Мой профиль',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
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
              },
              tileColor: const Color.fromARGB(50, 33, 149, 243),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Настройки'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: chatUsers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(chatUsers[index]),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessagesPage(chatUsers[index]),
                          ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}