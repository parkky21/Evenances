import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chat_user.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';

class SearchPage extends StatefulWidget {
  final bool isAddingContact;

  const SearchPage({
    Key? key, 
    this.isAddingContact = false,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  List<ChatUser> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<ChatUser> users = await _chatService.searchUsers(query);
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _startChat(BuildContext context, ChatUser user) async {
    try {
      // Create chat document if it doesn't exist
      await _chatService.createChat(user.id);
      
      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: user.id,
              name: user.name,
              imageUrl: user.imageUrl,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error starting chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141118),
        elevation: 0,
        title: Text(
          widget.isAddingContact ? 'New Chat' : 'Search Users',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF302938),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFab9db8)),
                hintText: 'Search by name or email',
                hintStyle: const TextStyle(color: Color(0xFFab9db8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Loading indicator
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
            
          // Search results
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Search for users by name or email'
                          : 'No users found',
                      style: const TextStyle(color: Color(0xFFab9db8)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      ChatUser user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.imageUrl),
                          radius: 24,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(
                            color: Color(0xFFab9db8),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFF6741b9),
                          ),
                          onPressed: () {
                            _startChat(context, user);
                          },
                        ),
                        onTap: () {
                          _startChat(context, user);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}