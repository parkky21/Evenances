import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential userCredential = await _auth.signInWithCredential(credential);
    
    // Save user data to Firestore
    if (userCredential.user != null) {
      await _saveUserToFirestore(userCredential.user!);
    }
    
    return userCredential;
  }

  // Sign out
  Future<void> signOut(BuildContext context) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': user.displayName,
      'email': user.email,
      'imageUrl': user.photoURL,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Update user status (online/offline)
  Future<void> updateUserStatus(bool isOnline) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'lastActive': isOnline ? FieldValue.serverTimestamp() : FieldValue.serverTimestamp(),
        'isOnline': isOnline,
      });
    }
  }
}