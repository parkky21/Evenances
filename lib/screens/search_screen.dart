import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Search by name (case insensitive prefix match)
    try {
      final results = await _firestore
        .collection('users')
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .get();
      
      // Filter out current user
      setState(() {
        _searchResults = results.docs
          .where((doc) => doc.id != _auth.currentUser!.uid)
          .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }
  
  Future<String> _getOrCreateChatId(String userId) async {
    final currentUser = _auth.currentUser!;
    
    // Check if chat already exists
    final chatQuery = await _firestore
      .collection('chats')
      .where('participants', arrayContains: currentUser.uid)
      .get();
    
    for (var doc in chatQuery.docs) {
      List<String> participants = List<String>.from(doc['participants']);
      if (participants.contains(userId)) {
        return doc.id;
      }
    }
    
    // Create new chat
    final chatDoc = await _firestore.collection('chats').add({
      'participants': [currentUser.uid, userId],
      'createdAt': Timestamp.now(),
    });
    
    return chatDoc.id;
  }
  
  void _startChat(String userId, String name, String photoUrl) async {
    try {
      final chatId = await _getOrCreateChatId(userId);
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            receiverUserId: userId,
            receiverName: name,
            receiverPhotoUrl: photoUrl,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? const Center(
                    child: Text('No users found', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var userData = _searchResults[index].data() as Map<String, dynamic>;
                      String userId = _searchResults[index].id;
                      String name = userData['name'] ?? 'User';
                      String photoUrl = userData['photoUrl'] ?? '';
                      String email = userData['email'] ?? '';
                      
                      return ListTile(
                        leading: photoUrl.isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(photoUrl))
                          : CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(email),
                        trailing: IconButton(
                          icon: const Icon(Icons.chat, color: Colors.purpleAccent),
                          onPressed: () => _startChat(userId, name, photoUrl),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}