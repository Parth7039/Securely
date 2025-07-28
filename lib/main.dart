import 'package:flutter/material.dart';
import 'package:securely/Authentication/AuthenticationPage.dart';
import 'package:securely/Vault/pages/vaultpage.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Vaultpage()
    );
  }
}
