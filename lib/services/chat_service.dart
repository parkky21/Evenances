import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/message.dart';
import 'package:flutter_application_1/models/chat_user.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Get all users
  Stream<List<ChatUser>> getUsers() {
    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatUser.fromFirestore(doc)).toList();
    });
  }

  // Search users
  Future<List<ChatUser>> searchUsers(String query) async {
    // Convert to lowercase for case-insensitive search
    String searchQuery = query.toLowerCase();
    
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    
    List<ChatUser> users = snapshot.docs
        .map((doc) => ChatUser.fromFirestore(doc))
        .where((user) => 
            user.id != currentUserId && 
            (user.name.toLowerCase().contains(searchQuery) || 
             user.email.toLowerCase().contains(searchQuery)))
        .toList();
    
    return users;
  }

  // Get user chats (conversations)
  Stream<List<String>> getUserChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Get chat ID between two users
  String getChatID(String userId1, String userId2) {
    // Always put the smaller ID first to ensure consistency
    return userId1.compareTo(userId2) < 0
        ? '$userId1-$userId2'
        : '$userId2-$userId1';
  }

  // Create a new chat
  Future<void> createChat(String otherUserId) async {
    if (currentUserId == null) return;
    
    String chatId = getChatID(currentUserId!, otherUserId);
    
    // Check if chat already exists
    DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      // Create new chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get chat messages
  Stream<List<Message>> getChatMessages(String otherUserId) {
    if (currentUserId == null) return Stream.value([]);
    
    String chatId = getChatID(currentUserId!, otherUserId);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String receiverId, String text) async {
  if (currentUserId == null) return;
  
  User? currentUser = _auth.currentUser;
  if (currentUser == null) return;
  
  String chatId = getChatID(currentUserId!, receiverId);
  
  // Get user data for metadata
  DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUserId).get();
  Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
  String senderName = userData['name'] ?? '';
  String senderImage = userData['imageUrl'] ?? '';
  
  // Create message
  Message message = Message(
    senderId: currentUserId!,
    senderName: senderName,
    senderImage: senderImage,
    receiverId: receiverId,
    text: text,
    timestamp: Timestamp.now(),
    id: '', // Will be assigned by Firestore
  );
    
    // Add message to chat
    await _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .add(message.toMap());
  
  // Update chat metadata
  await _firestore.collection('chats').doc(chatId).update({
    'lastMessage': text,
    'lastMessageTime': FieldValue.serverTimestamp(),
  });
  
  // Update or create user's chat reference - for current user
  await _firestore
      .collection('users')
      .doc(currentUserId)
      .collection('chats')
      .doc(receiverId)
      .set({
    'userId': receiverId,
    'lastMessage': text,
    'lastMessageTime': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  
  // Update or create user's chat reference - for other user
  await _firestore
      .collection('users')
      .doc(receiverId)
      .collection('chats')
      .doc(currentUserId)
      .set({
    'userId': currentUserId,
    'lastMessage': text,
    'lastMessageTime': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

  // Get user by ID
  Future<ChatUser?> getUserById(String userId) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return ChatUser.fromFirestore(doc);
    }
    return null;
  }
}