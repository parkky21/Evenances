import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderName;
  final String senderImage;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final String id;

  Message({
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.id,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Message(
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderImage: data['senderImage'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      id: doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}