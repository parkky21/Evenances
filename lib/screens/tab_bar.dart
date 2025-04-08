import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/chat_list.dart';
import 'package:flutter_application_1/screens/search.dart';
import 'package:flutter_application_1/screens/profile.dart';

class MyHomePage extends StatefulWidget {


  const MyHomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Track selected tab

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Move _screens inside build to correctly use widget.user
    final List<Widget> _screens = [
      const ChatList(),   // Home Screen (Chat List)
      const SearchPage(), // Search Screen
      ProfilePage(user: FirebaseAuth.instance.currentUser), // Pass user correctly
    ];

    return Scaffold(
      body: IndexedStack( // Preserve screen state when switching
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF211c26),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFab9db8),
        currentIndex: _selectedIndex, // Highlight active tab
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
