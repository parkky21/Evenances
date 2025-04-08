import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/home.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evenances',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF141118),
        scaffoldBackgroundColor: const Color(0xFF141118),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141118),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const ChatList();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_application_1/screens/splach_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Evenances',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: const Color(0xFF6741b9),
//         scaffoldBackgroundColor: const Color(0xFF141118),
//         fontFamily: 'Roboto',
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFF141118),
//           elevation: 0,
//         ),
//       ),
//       home: SplashScreen(),
//     );
//   }
// }