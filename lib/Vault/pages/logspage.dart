import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Logspage extends StatefulWidget {
  const Logspage({super.key});

  @override
  State<Logspage> createState() => _LogspageState();
}

class _LogspageState extends State<Logspage> {
  String _logContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogFile();
  }

  Future<void> _loadLogFile() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final File logFile = File('${appDocDir.path}/SecureVault/vault_logs.txt');

      if (await logFile.exists()) {
        final content = await logFile.readAsString();
        setState(() {
          _logContent = content.isEmpty ? 'No logs yet.' : content;
        });
      } else {
        setState(() {
          _logContent = 'Log file not found.';
        });
      }
    } catch (e) {
      setState(() {
        _logContent = 'Error loading logs: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vault Logs')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(
            _logContent,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}
