import 'package:flutter/material.dart';

class Integritypage extends StatefulWidget {
  const Integritypage({super.key});

  @override
  State<Integritypage> createState() => _IntegritypageState();
}

class _IntegritypageState extends State<Integritypage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('This is Integrity check'),
      ),
    );
  }
}
