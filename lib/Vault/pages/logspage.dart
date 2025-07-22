import 'package:flutter/material.dart';

class Logspage extends StatefulWidget {
  const Logspage({super.key});

  @override
  State<Logspage> createState() => _LogspageState();
}

class _LogspageState extends State<Logspage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('This is Logs '),
      ),
    );;
  }
}
