import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';
import 'package:flutter_application_1/screens/search.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class ChatList extends StatelessWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141118),
        title: const Text(
          'Evenances',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.015,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .collection('chats')
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No conversations yet.\nUse the search button to find users.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFab9db8)),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final userId = chatData['userId'] as String;
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            leading: CircleAvatar(
                              child: CircularProgressIndicator(),
                            ),
                            title: Text('Loading...'),
                            subtitle: Text('Please wait'),
                          );
                        }
                        
                        if (userSnapshot.hasError || !userSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final name = userData['name'] ?? 'Unknown';
                        final photoUrl = userData['photoUrl'] ?? '';
                        final lastMessage = chatData['lastMessage'] ?? 'Start a conversation';
                        
                        return ChatItem(
                          name: name,
                          message: lastMessage,
                          imageUrl: photoUrl,
                          userId: userId,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF442d59),
        child: const Icon(Icons.person_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        },
      ),
    );
  }
}

class ChatItem extends StatelessWidget {
  final String name;
  final String message;
  final String imageUrl;
  final String userId;

  const ChatItem({
    Key? key,
    required this.name,
    required this.message,
    required this.imageUrl,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              name: name,
              imageUrl: imageUrl,
              userId: userId,
            ),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty ? Text(name[0]) : null,
          radius: 28,
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFab9db8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}