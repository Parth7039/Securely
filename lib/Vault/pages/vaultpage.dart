import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:securely/Vault/pages/encryptionpage.dart';
import 'package:securely/Vault/pages/integritypage.dart';
import 'package:securely/Vault/pages/logspage.dart';

import '../../components/customNavigationBar.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  Directory? _vaultDirectory;
  List<FileSystemEntity> _files = [];
  final String _logFileName = 'vault_logs.txt';

  @override
  void initState() {
    super.initState();
    _initializeVault();
  }

  Future<void> _initializeVault() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory vaultDir = Directory('${appDocDir.path}/SecureVault');

    if (!await vaultDir.exists()) {
      await vaultDir.create();
    }

    setState(() {
      _vaultDirectory = vaultDir;
    });

    await _createLogFile();
    _refreshVaultContents();
  }

  Future<void> _createLogFile() async {
    final File logFile = File('${_vaultDirectory!.path}/$_logFileName');
    if (!await logFile.exists()) {
      await logFile.writeAsString('Vault log initialized: ${DateTime.now()}\n');
    }
  }

  Future<void> _logAction(String action) async {
    final File logFile = File('${_vaultDirectory!.path}/$_logFileName');
    await logFile.writeAsString('${DateTime.now()} - $action\n', mode: FileMode.append);
  }

  Future<void> _refreshVaultContents() async {
    if (_vaultDirectory != null) {
      final files = _vaultDirectory!.listSync();
      setState(() {
        _files = files.where((file) => path.basename(file.path) != _logFileName).toList();
      });
    }
  }

  Future<void> _addFileToVault() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final fileName = path.basename(pickedFile.path);
      final newFile = File('${_vaultDirectory!.path}/$fileName');

      await pickedFile.copy(newFile.path);
      await _logAction('File added: $fileName');
      _refreshVaultContents();
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      final fileName = path.basename(file.path);
      await file.delete();
      await _logAction('File deleted: $fileName');
      _refreshVaultContents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete file: $e")),
      );
    }
  }

  Future<void> _openFile(File file) async {
    final result = await OpenFile.open(file.path);
    await _logAction('File opened: ${path.basename(file.path)} (${result.message})');
  }

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
                MaterialPageRoute(builder: (_) => Integritypage()),
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
                MaterialPageRoute(builder: (_) => Encryptionpage()),
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
                MaterialPageRoute(builder: (_) => Logspage()),
              );
              // Reset after return
              if (mounted) setState(() => _currentIndex = -1);
            },
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text("Secure Vault"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addFileToVault,
            tooltip: 'Add File to Vault',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _refreshVaultContents,
            child: const Text("Open Vault"),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _files.isEmpty
                ? const Center(child: Text("Vault is empty"))
                : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final fileName = path.basename(file.path);
                return ListTile(
                  title: Text(fileName),
                  subtitle: const Text("Tap to open (content not shown here)"),
                  leading: const Icon(Icons.lock),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFile(file),
                  ),
                  onTap: () => _openFile(File(file.path)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
