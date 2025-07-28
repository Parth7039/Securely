import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class Vaultpage extends StatefulWidget {
  const Vaultpage({super.key});

  @override
  State<Vaultpage> createState() => _VaultpageState();
}

class _VaultpageState extends State<Vaultpage> with TickerProviderStateMixin {
  List<FileSystemEntity> files = [];
  bool isLoading = true;
  String searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  static const _channel = MethodChannel('secure_vault');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadFiles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await listSecureFiles();
      setState(() {
        files = result;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar("Failed to load files: $e");
    }
  }

  Future<void> _addFile() async {
    try {
      final success = await pickAndSaveFile();
      if (success) {
        _showSuccessSnackBar("File secured successfully! Original deleted.");
        _loadFiles();
      }
    } catch (e) {
      _showErrorSnackBar("Failed to add file: $e");
    }
  }

  Future<void> _deleteFile(File file) async {
    final confirmed = await _showDeleteConfirmation(file.path.split('/').last);
    if (confirmed) {
      try {
        await file.delete();
        _showSuccessSnackBar("File deleted successfully!");
        _loadFiles();
      } catch (e) {
        _showErrorSnackBar("Failed to delete file: $e");
      }
    }
  }

  Future<void> _openFile(File file) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      _showErrorSnackBar("Failed to open file: $e");
    }
  }

  Future<bool> _showDeleteConfirmation(String fileName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Delete File', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "$fileName"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<FileSystemEntity> get filteredFiles {
    if (searchQuery.isEmpty) return files;
    return files.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(searchQuery.toLowerCase());
    }).toList();
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toUpperCase();
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      case 'zip':
      case 'rar':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.security, size: 24, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text("Secure Vault", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.greenAccent),
            tooltip: 'Open in File Manager',
            onPressed: () async {
              try {
                await openInFileManager();
              } catch (e) {
                _showErrorSnackBar("Failed to open: $e");
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.greenAccent),
            tooltip: 'Refresh Files',
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => setState(() => searchQuery = ''),
                )
                    : null,
              ),
            ),
          ),

          // File Count
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${filteredFiles.length} ${filteredFiles.length == 1 ? 'file' : 'files'}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Content Area
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 16),
                  Text("Loading files...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : filteredFiles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    searchQuery.isEmpty ? Icons.folder_open : Icons.search_off,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isEmpty
                        ? "No files in secure vault"
                        : "No files match your search",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isEmpty
                        ? "Tap the + button to add files"
                        : "Try a different search term",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredFiles.length,
                itemBuilder: (context, index) {
                  final file = filteredFiles[index] as File;
                  final fileName = file.path.split('/').last;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: const Color(0xFF2A2A2A),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.greenAccent.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getFileIconColor(fileName).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getFileIcon(fileName),
                          color: _getFileIconColor(fileName),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getFileExtension(fileName),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getFileSize(file),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white70),
                        color: const Color(0xFF2A2A2A),
                        onSelected: (value) {
                          switch (value) {
                            case 'open':
                              _openFile(file);
                              break;
                            case 'delete':
                              _deleteFile(file);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, size: 20, color: Colors.white70),
                                SizedBox(width: 8),
                                Text('Open', style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _openFile(file),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFile,
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Add File", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// Enhanced Utils
Future<Directory> getSecureFolder() async {
  // Request storage permissions
  var status = await Permission.storage.request();

  // For Android 11+ (API 30+), we might need MANAGE_EXTERNAL_STORAGE
  if (!status.isGranted) {
    status = await Permission.manageExternalStorage.request();
  }

  if (!status.isGranted) {
    throw Exception("Storage permission not granted. Please enable storage access in settings.");
  }

  // Create the secure folder in a visible location
  final visibleDir = Directory('/storage/emulated/0/SecurelyVault');

  if (!await visibleDir.exists()) {
    try {
      await visibleDir.create(recursive: true);
    } catch (e) {
      // Fallback to app-specific directory if external storage fails
      final appDir = await getExternalStorageDirectory();
      final fallbackDir = Directory('${appDir!.path}/SecurelyVault');
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir;
    }
  }

  return visibleDir;
}

Future<bool> pickAndSaveFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final secureFolder = await getSecureFolder();
      final sourceFile = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Check if file already exists and generate unique name if needed
      String finalFileName = fileName;
      int counter = 1;
      while (await File('${secureFolder.path}/$finalFileName').exists()) {
        final nameWithoutExtension = fileName.split('.').first;
        final extension = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
        finalFileName = '${nameWithoutExtension}_$counter$extension';
        counter++;
      }

      final destinationPath = '${secureFolder.path}/$finalFileName';

      // Copy the file to secure location
      await sourceFile.copy(destinationPath);

      // Delete the original file after successful copy
      // Delete the original file after successful copy
      try {
        await sourceFile.delete();

        // Optional: Verify if deletion succeeded
        if (await sourceFile.exists()) {
          print("File was not deleted successfully.");
        }
      } catch (e) {
        print("Warning: Could not delete original file: $e");
      }


      return true;
    }
    return false;
  } catch (e) {
    throw Exception("Failed to save file: $e");
  }
}

Future<List<FileSystemEntity>> listSecureFiles() async {
  try {
    final folder = await getSecureFolder();
    final entities = folder.listSync();
    return entities.whereType<File>().toList()
      ..sort((a, b) => a.path.split('/').last.toLowerCase()
          .compareTo(b.path.split('/').last.toLowerCase()));
  } catch (e) {
    throw Exception("Failed to list files: $e");
  }
}

Future<void> openInFileManager() async {
  try {
    final folder = await getSecureFolder();
    await OpenFile.open(folder.path);
  } catch (e) {
    throw Exception("Failed to open file manager: $e");
  }
}