import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:chat_p2p/pages/chats_page.dart';
import 'package:chat_p2p/pages/profile_page.dart';
import 'package:chat_p2p/pages/login_page.dart';
import 'package:chat_p2p/pages/messages_page.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // открытие порта
    final openPortResponse = await http.post(
      Uri.parse('http://localhost:5000/api/open_port'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'external_port': 15001,
        'internal_port': 15001,
        'protocol': 'TCP',
        'description': 'My Flask Server'
      }),
    );

    if (openPortResponse.statusCode != 200) {
      throw Exception('Failed to open port: ${openPortResponse.body}');
    }
    // запуск сервера
    final startServerResponse = await http.post(
      Uri.parse('http://localhost:5000/api/start_server'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'port': 15001}),
    );

    if (startServerResponse.statusCode != 200) {
      throw Exception('Failed to start server: ${startServerResponse.body}');
    }

    print('Server started and port opened successfully');
    
  } catch (e) {
    print('Error during server initialization: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MyWidget(),);
  }
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      home: ChatsPage(),
      routes: {
        '/chats': (context) => ChatsPage(),
        '/profile': (context) => ProfilePage(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}