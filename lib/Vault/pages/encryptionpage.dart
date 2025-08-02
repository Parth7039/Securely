import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
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

  // Generate a proper 32-byte key from the passkey using SHA-256
  List<int> _generateKey(String passkey) {
    final bytes = utf8.encode(passkey);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  Future<void> _encryptFile(File file) async {
    final passkey = await _promptPasskey("Encrypt");
    if (passkey == null || passkey.isEmpty) return;

    try {
      final content = await file.readAsBytes();

      // Generate a secure key from the passkey
      final keyBytes = Uint8List.fromList(_generateKey(passkey));
      final key = encrypt.Key(keyBytes);

      // Generate a random IV for each encryption
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encryptBytes(content, iv: iv);

      // Create the encrypted file structure with IV + encrypted data
      final encryptedData = {
        'iv': iv.base64,
        'data': encrypted.base64,
      };

      final newFile = File('${file.path}.enc');
      await newFile.writeAsString(jsonEncode(encryptedData));
      await file.delete();

      setState(() {
        _status = 'Encrypted: ${path.basename(file.path)}';
      });
      _loadVaultFiles();
    } catch (e) {
      setState(() {
        _status = 'Encryption failed: $e';
      });
    }
  }

  Future<void> _decryptFile(File file) async {
    final passkey = await _promptPasskey("Decrypt");
    if (passkey == null || passkey.isEmpty) return;

    try {
      final encryptedContent = await file.readAsString();
      final encryptedData = jsonDecode(encryptedContent);

      // Extract IV and encrypted data
      final iv = encrypt.IV.fromBase64(encryptedData['iv']);
      final encryptedBytes = encrypt.Encrypted.fromBase64(encryptedData['data']);

      // Generate the same key from the passkey
      final keyBytes = Uint8List.fromList(_generateKey(passkey));
      final key = encrypt.Key(keyBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decryptedBytes = encrypter.decryptBytes(encryptedBytes, iv: iv);

      // Remove .enc extension to get original filename
      final originalPath = file.path.substring(0, file.path.length - 4);
      final decryptedFile = File(originalPath);
      await decryptedFile.writeAsBytes(decryptedBytes);

      // Delete the encrypted file
      await file.delete();

      setState(() {
        _status = 'Decrypted: ${path.basename(originalPath)}';
      });

      _loadVaultFiles();
    } catch (e) {
      setState(() {
        _status = 'Decryption failed: Invalid passkey or corrupted file.';
      });
    }
  }

  Widget _buildFileCard(File file) {
    final fileName = path.basename(file.path);
    final isEncrypted = fileName.endsWith('.enc');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(
          isEncrypted ? Icons.lock : Icons.lock_open,
          color: isEncrypted ? Colors.red : Colors.green,
        ),
        title: Text(fileName),
        subtitle: Text(isEncrypted ? 'Encrypted file' : 'Unencrypted file'),
        trailing: ElevatedButton(
          onPressed: () => isEncrypted ? _decryptFile(file) : _encryptFile(file),
          style: ElevatedButton.styleFrom(
            backgroundColor: isEncrypted ? Colors.green : Colors.blue,
          ),
          child: Text(isEncrypted ? 'Decrypt' : 'Encrypt'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Encryption'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
              'Secure File Vault',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _files.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Vault is empty", style: TextStyle(fontSize: 16)),
                  Text("Add files to the SecureVault folder to encrypt them"),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return _buildFileCard(File(file.path));
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 14,
                color: _status.contains('failed') ? Colors.red : Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}