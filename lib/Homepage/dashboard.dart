import 'package:flutter/material.dart';
import 'package:securely/Settings/settingspage.dart';
import 'package:securely/Vault/pages/vaultpage.dart';
import '../components/customNavigationBar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

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
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Settingspage()),
              );
              // Reset after return
              if (mounted) setState(() => _currentIndex = -1);
            },
          ),
          NavigationItem(
            icon: Icons.lock_person_rounded,
            label: 'Vault',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Vaultpage()),
              );
              // Reset after return
              if (mounted) setState(() => _currentIndex = -1);
            },
          ),
          NavigationItem(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Settingspage()),
              );
              // Reset after return
              if (mounted) setState(() => _currentIndex = -1);
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text('This is Dashboard'),
      ),
    );
  }
}
