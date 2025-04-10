import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a chat ID from two user IDs
  String getChatRoomId(String userId1, String userId2) {
    // Sort IDs to ensure consistent chat room ID regardless of who initiates
    return userId1.compareTo(userId2) > 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  // Get or create a chat conversation
  Future<String> getOrCreateChatRoom(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final chatRoomId = getChatRoomId(currentUserId!, otherUserId);
    
    // Check if chat room exists
    final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
    final chatRoom = await chatRoomRef.get();

    if (!chatRoom.exists) {
      // Create a new chat room
      await chatRoomRef.set({
        'users': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    return chatRoomId;
  }

  // Send a message
  Future<void> sendMessage(String chatRoomId, String message) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final timestamp = FieldValue.serverTimestamp();
    
    // Add message to the chat room
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'text': message,
          'timestamp': timestamp,
          'read': false,
        });

    // Update last message in chat room
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': timestamp,
    });
  }

  // Stream of messages for a specific chat room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Stream of all chat rooms for current user
  Stream<QuerySnapshot> getChatRooms() {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('chatRooms')
        .where('users', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String senderId) async {
    if (currentUserId == null || currentUserId == senderId) return;
    
    final messagesQuery = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isEqualTo: senderId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesQuery.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data();
  }

  // Update user online status
  Future<void> updateUserStatus(bool isOnline) async {
    if (currentUserId == null) return;
    
    await _firestore.collection('users').doc(currentUserId).update({
      'online': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Count unread messages
  Future<int> getUnreadMessageCount(String chatRoomId) async {
    if (currentUserId == null) return 0;
    
    final querySnapshot = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();
    
    return querySnapshot.docs.length;
  }
}