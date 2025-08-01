import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// Note: You must add these dependencies to your pubspec.yaml file:
// dependencies:
//   flutter:
//     sdk: flutter
//   path_provider: ^2.0.15
//   open_file: ^3.3.2

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  // The root directory of the vault. Made nullable to handle initialization errors.
  Directory? _vaultDirectory;
  // The directory currently being viewed. Made nullable.
  Directory? _currentDirectory;
  // This list will store the files and folders inside the current directory.
  List<FileSystemEntity> _vaultContents = [];
  // State to track if the vault directory has been initialized.
  bool _isLoading = true;
  // State to track if the user has chosen to "open" the vault view.
  bool _isVaultOpen = false;

  @override
  void initState() {
    super.initState();
    // When the widget is first created, initialize the vault in the background.
    _initVault();
  }

  /// Initializes the vault.
  /// It gets the application's private documents directory and creates the 'SecureVault'
  /// subfolder if it doesn't exist.
  Future<void> _initVault() async {
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      _vaultDirectory = Directory('${appDocsDir.path}/SecureVault');

      if (!await _vaultDirectory!.exists()) {
        await _vaultDirectory!.create(recursive: true);
        print('SecureVault directory created at: ${_vaultDirectory!.path}');
      } else {
        print('SecureVault directory already exists at: ${_vaultDirectory!.path}');
      }

      // Initially, the current directory is the root of the vault.
      _currentDirectory = _vaultDirectory;

    } catch (e) {
      print('Error initializing vault: $e');
      // Optionally show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing vault: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Lists the files and directories inside the _currentDirectory and updates the UI.
  void _listVaultContents() {
    // Only proceed if the current directory has been initialized.
    if (_currentDirectory == null) return;

    // Get all entities from the currently viewed directory.
    final contents = _currentDirectory!.listSync();
    // Sort contents to show directories first, then files, all alphabetically.
    contents.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    if (mounted) {
      setState(() {
        _vaultContents = contents;
      });
    }
  }

  /// Sets the state to open the vault and lists its contents.
  void _enterVault() {
    // Ensure directories are initialized before entering
    if (_currentDirectory == null || _vaultDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault is not ready. Please try again.')),
      );
      return;
    }
    setState(() {
      _isVaultOpen = true;
    });
    _listVaultContents();
  }

  /// Creates a dummy file in the current directory for demonstration purposes.
  Future<void> _addDummyFile() async {
    if (_currentDirectory == null) return;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Create the new file in the _currentDirectory.
    final newFile = File('${_currentDirectory!.path}/Note_$timestamp.txt');
    await newFile.writeAsString('This is a secure note created at ${DateTime.now()}');
    print('Dummy file created: ${newFile.path}');
    _listVaultContents();
  }

  /// Shows a dialog to get a name for a new folder and creates it.
  Future<void> _createNewFolder() async {
    if (_currentDirectory == null) return;
    final folderNameController = TextEditingController();
    final newFolderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: folderNameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter folder name'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () => Navigator.pop(context, folderNameController.text),
          ),
        ],
      ),
    );

    if (newFolderName != null && newFolderName.isNotEmpty) {
      try {
        final newDir = Directory('${_currentDirectory!.path}/$newFolderName');
        if (!await newDir.exists()) {
          await newDir.create();
          print('Created new folder: ${newDir.path}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder "$newFolderName" already exists.')),
          );
        }
        _listVaultContents();
      } catch (e) {
        print('Error creating folder: $e');
      }
    }
  }

  /// Opens a file using the 'open_file' package.
  void _openFile(File file) {
    OpenFile.open(file.path);
  }

  /// Navigates into a directory.
  void _openDirectory(Directory directory) {
    setState(() {
      _currentDirectory = directory;
      _listVaultContents();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the vault is open, show the file browser UI.
    if (_isVaultOpen) {
      return _buildFileBrowser();
    }
    // Otherwise, show the initial landing page.
    return _buildLandingPage();
  }

  /// Builds the initial page with the "Open Secure Vault" button.
  Widget _buildLandingPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault'),
        backgroundColor: Colors.blueGrey[800],
      ),
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: Colors.teal, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Your private files are secure.',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Open Secure Vault'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _enterVault,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the file browser view for navigating vault contents.
  Widget _buildFileBrowser() {
    if (_currentDirectory == null || _vaultDirectory == null) {
      // Show an error state if directories aren't ready
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(child: Text("Could not load vault.", style: TextStyle(color: Colors.white)))
      );
    }
    final bool canNavigateBack = _currentDirectory!.path != _vaultDirectory!.path;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDirectory!.path.split('/').last),
        backgroundColor: Colors.blueGrey[800],
        leading: IconButton(
          // The back button now navigates up a directory or closes the vault view.
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (canNavigateBack) {
              _navigateToParentDirectory();
            } else {
              // If we are at the root, "back" closes the vault view.
              setState(() {
                _isVaultOpen = false;
              });
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _createNewFolder,
            tooltip: 'Create New Folder',
          )
        ],
      ),
      backgroundColor: Colors.blueGrey[900],
      body: _buildVaultContentsView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDummyFile,
        tooltip: 'Add Dummy File',
        backgroundColor: Colors.teal,
        child: const Icon(Icons.note_add_outlined),
      ),
    );
  }

  /// Logic for navigating to the parent directory within the file browser.
  void _navigateToParentDirectory() {
    if (_currentDirectory == null) return;
    setState(() {
      _currentDirectory = _currentDirectory!.parent;
      _listVaultContents();
    });
  }

  /// Builds the list view of the vault's contents.
  Widget _buildVaultContentsView() {
    if (_vaultContents.isEmpty) {
      return const Center(
        child: Text(
          'This folder is empty.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _vaultContents.length,
      itemBuilder: (context, index) {
        final entity = _vaultContents[index];
        final entityName = entity.path.split('/').last;
        final isDirectory = entity is Directory;

        return Card(
          color: Colors.blueGrey[700],
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ListTile(
            leading: Icon(
              isDirectory ? Icons.folder : Icons.insert_drive_file,
              color: isDirectory ? Colors.amber : Colors.white,
            ),
            title: Text(
              entityName,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              if (isDirectory) {
                _openDirectory(entity as Directory);
              } else {
                _openFile(entity as File);
              }
            },
          ),
        );
      },
    );
  }
}
