import 'package:flutter/material.dart';
import 'package:securely/Vault/pages/encryptionpage.dart';
import 'package:securely/Vault/pages/integritypage.dart';
import 'package:securely/Vault/pages/logspage.dart';

import '../../components/customNavigationBar.dart';

class Vaultpage extends StatefulWidget {
  const Vaultpage({super.key});

  @override
  State<Vaultpage> createState() => _VaultpageState();
}

class _VaultpageState extends State<Vaultpage> {

  int _currentIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          NavigationItem(
            icon: Icons.check,
            label: 'Integrity',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Integritypage()),
              );

              // Reset after return
              if (mounted) setState(() => _currentIndex = -1);
            },
          ),
          NavigationItem(
            icon: Icons.enhanced_encryption_outlined,
            label: 'Encryption',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Encryptionpage()),
              );

              // Reset after return
              if (mounted) setState(() => _currentIndex = -1);
            },
          ),
          NavigationItem(
            icon: Icons.settings,
            label: 'Logs',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Logspage()),
              );

              // Reset after return
              if (mounted) setState(() => _currentIndex = -1);
            },
          ),
        ],
      ),
      body: Center(
        child: Text('This is vault page'),
      ),
    );
  }
}
