import 'package:flutter/material.dart';
import 'package:google_map/page/Home_page.dart';
import 'package:google_map/page/Login_page.dart';
import 'package:google_map/page/Register_page.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Absen',
      home: LoginPage(),
      routes: {
        '/Login': (context) => LoginPage(),
        '/Register': (context) => RegisterPage(),
        '/Home': (context) => HomePage(username: 'username')},
        );
  }
}
