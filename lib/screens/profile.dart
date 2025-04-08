import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatefulWidget {
  final User? user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(26, 17, 34, 1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1122),
        elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () {
        //     Navigator.of(context).pop();
        //   },
        // ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Profile Image and Name
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF211c26),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Profile Image
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.user?.photoURL ?? ''),
                  radius: 60,
                  backgroundColor: const Color(0xFF362447),
                  child: widget.user?.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                // Username
                Text(
                  widget.user?.displayName ?? 'Username',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  widget.user?.email ?? 'user@example.com',
                  style: const TextStyle(
                    color: Color(0xFFad93c8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Options List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildOptionTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    // Navigate to Settings Page
                  },
                ),
                _buildOptionTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    // Navigate to About Page
                  },
                ),
                _buildOptionTile(
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  onTap: () {
                    // Navigate to Privacy Page
                  },
                ),
                _buildOptionTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  onTap: () async {
                    await _signOut(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF211c26),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFad93c8),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFad93c8),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    // Check if the widget is still mounted before navigating
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  } catch (e) {
    // Handle errors
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }
}
}