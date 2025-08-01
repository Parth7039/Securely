import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Encryptionpage extends StatefulWidget {
  const Encryptionpage({super.key});

  @override
  State<Encryptionpage> createState() => _EncryptionpageState();
}

class _EncryptionpageState extends State<Encryptionpage> {
  Directory? _vaultDirectory;
  List<FileSystemEntity> _files = [];
  String _status = 'No action performed.';

  @override
  void initState() {
    super.initState();
    _loadVaultFiles();
  }

  Future<void> _loadVaultFiles() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDocDir.path}/SecureVault');

    if (!await vaultDir.exists()) {
      await vaultDir.create();
    }

    setState(() {
      _vaultDirectory = vaultDir;
    });

    final allFiles = vaultDir.listSync();
    setState(() {
      _files = allFiles.where((file) {
        final name = path.basename(file.path);
        return name != 'vault_logs.txt';
      }).toList();
    });
  }

  Future<String?> _promptPasskey(String action) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action - Enter Passkey'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter a passkey'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key.padRight(32, '0').substring(0, 32); // AES-256 requires 32 bytes
  }

  Future<void> _encryptFile(File file) async {
    final passkey = await _promptPasskey("Encrypt");
    if (passkey == null) return;

    final content = await file.readAsBytes();
    final key = encrypt.Key.fromUtf8(_formatKey(passkey));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(content, iv: iv);
    final newFile = File('${file.path}.enc');

    // Save Base64 string instead of raw bytes
    await newFile.writeAsString(encrypted.base64);
    await file.delete();

    setState(() {
      _status = 'Encrypted: ${path.basename(file.path)}';
    });
    _loadVaultFiles();
  }

  Future<void> _decryptFile(File file) async {
    final passkey = await _promptPasskey("Decrypt");
    if (passkey == null) return;

    try {
      final encryptedBase64 = await file.readAsString();
      final encryptedBytes = encrypt.Encrypted.fromBase64(encryptedBase64);

      final key = encrypt.Key.fromUtf8(_formatKey(passkey));
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decryptedBytes = encrypter.decryptBytes(encryptedBytes, iv: iv);

      final decryptedFile = File(file.path.replaceAll('.enc', ''));
      await decryptedFile.writeAsBytes(decryptedBytes);

      setState(() {
        _status = 'Decrypted: ${path.basename(file.path)}';
      });

      _loadVaultFiles();
    } catch (e) {
      setState(() {
        _status = 'Decryption failed: Invalid passkey or file.';
      });
    }
  }

  Widget _buildFileCard(File file) {
    final fileName = path.basename(file.path);
    final isEncrypted = fileName.endsWith('.enc');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(isEncrypted ? Icons.lock : Icons.lock_open),
        title: Text(fileName),
        subtitle: Text(isEncrypted ? 'Encrypted file' : 'Unencrypted file'),
        trailing: ElevatedButton(
          onPressed: () => isEncrypted ? _decryptFile(file) : _encryptFile(file),
          child: Text(isEncrypted ? 'Decrypt' : 'Encrypt'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vault Encryption')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: _files.isEmpty
                ? const Center(child: Text("Vault is empty"))
                : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return _buildFileCard(File(file.path));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _status,
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }
}
