import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_application_1/screens/search.dart';
import 'package:flutter_application_1/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141118),
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(isAddingContact: true),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar for filtering chats
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF302938),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFab9db8)),
                hintText: 'Search conversations',
                hintStyle: const TextStyle(color: Color(0xFFab9db8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // Implement local filtering
                setState(() {});
              },
            ),
          ),
          // Chat list
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _chatService.getUserChats(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!chatSnapshot.hasData || chatSnapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No conversations yet.\nTap + to start a new chat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFab9db8)),
                    ),
                  );
                }

                List<String> chatIds = chatSnapshot.data!;
                return ListView.builder(
                  itemCount: chatIds.length,
                  itemBuilder: (context, index) {
                    String chatId = chatIds[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: _firestore.collection('chats').doc(chatId).snapshots(),
                      builder: (context, chatDataSnapshot) {
                        if (!chatDataSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        Map<String, dynamic> chatData = 
                            chatDataSnapshot.data!.data() as Map<String, dynamic>;
                        
                        List<dynamic> participants = chatData['participants'] ?? [];
                        String otherUserId = participants.firstWhere(
                          (id) => id != _auth.currentUser!.uid,
                          orElse: () => '',
                        );

                        if (otherUserId.isEmpty) return const SizedBox.shrink();

                        return FutureBuilder<ChatUser?>(
                          future: _chatService.getUserById(otherUserId),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            ChatUser otherUser = userSnapshot.data!;
                            String lastMessage = chatData['lastMessage'] ?? '';
                            Timestamp lastMessageTime = chatData['lastMessageTime'] ?? Timestamp.now();
                            String formattedTime = DateFormat.jm().format(lastMessageTime.toDate());

                            return ChatListItem(
                              user: otherUser,
                              lastMessage: lastMessage,
                              timestamp: formattedTime,
                            );
                          },
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
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatUser user;
  final String lastMessage;
  final String timestamp;

  const ChatListItem({
    Key? key,
    required this.user,
    required this.lastMessage,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              backgroundImage: NetworkImage(user.imageUrl),
              radius: 28,
            ),
            const SizedBox(width: 16),
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          color: Color(0xFFab9db8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFab9db8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}