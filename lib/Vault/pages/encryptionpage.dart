import 'package:flutter/material.dart';

class Encryptionpage extends StatefulWidget {
  const Encryptionpage({super.key});

  @override
  State<Encryptionpage> createState() => _EncryptionpageState();
}

class _EncryptionpageState extends State<Encryptionpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('This is Encryption'),
      ),
    );;
  }
}
