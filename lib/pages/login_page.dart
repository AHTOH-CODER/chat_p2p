import 'package:flutter/material.dart'; 

 
class LoginPage extends StatefulWidget { 
  @override 
  _LoginPageState createState() => _LoginPageState(); 
} 
 
class _LoginPageState extends State<LoginPage> { 
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чаты',
          style: TextStyle(
            color: Colors.white,),
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
                          'https://example.com/profile.jpg'), // Замените на реальное изображение
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
                Navigator.pushNamed(context, '/chats');
              },
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
      body: Center(
        child: Text('login'),
      ),
    );
  }
}