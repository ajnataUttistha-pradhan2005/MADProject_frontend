// import 'package:flutter/material.dart';
// import 'package:mathsolver/pages/home_Page.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         fontFamily: "LexendDeca",
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: HomePage(),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mathsolver/pages/sign_in_page.dart';
import 'package:mathsolver/pages/home_Page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MathSolver',
      theme: ThemeData(
        fontFamily: "LexendDeca",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInPage(),
      // home: const HomePage(),
    );
  }
}
