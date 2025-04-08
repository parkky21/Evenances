import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String id;
  final String name;
  final String email;
  final String imageUrl;
  final Timestamp lastActive;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.lastActive,
  });

  factory ChatUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      lastActive: data['lastActive'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'lastActive': lastActive,
    };
  }
}