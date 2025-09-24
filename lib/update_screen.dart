import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'code_service.dart';
import 'flutter_service.dart';
import 'package:flutter/services.dart';

class ProjectFile {
  final String name;
  final String path;
  IconData icon;
  final bool isDirectory;
  List<ProjectFile> children;
  ProjectFile({
    required this.name,
    required this.path,
    required this.icon,
    this.isDirectory = false,
    this.children = const [],
  });
}

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});
  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with SingleTickerProviderStateMixin {
  final CodeService _codeService = CodeService();
  final FlutterService _flutterService = FlutterService();
  final TextEditingController _updateController = TextEditingController();
  final TextEditingController _codeEditorController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  String _code = '';
  String _status = 'Ready to update your app';
  bool _isProcessing = false;
  String _buildTarget = 'apk';
  late String _projectName;
  bool _isManualEdit = false;
  String _currentFile = 'lib/main.dart';
  bool _isPromptWindowExpanded = false;
  final List<String> _openFiles = ['lib/main.dart'];
  final bool _includeBackend = false;
  int _currentCredits = 0;
  late AnimationController _typingAnimationController;
  String _explanationContent = '';
  double _promptWindowHeight = 200;
  String _rightPanelTab = 'explanation';
  String _errors = 'No errors found.';
  String _terminalOutput = 'No terminal output yet.';
  List<ProjectFile> _projectFiles = [];
  String _basePath = '';
  double _explorerWidth = 250;
  double _rightPanelWidth = 300;
  bool _supabaseHelperExists = false;
  int _autoSolveAttempts = 0;
  String? _lastRunPlatform; // 'windows', 'edge', 'chrome'

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkSupabaseHelperExists();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _projectName = ModalRoute.of(context)!.settings.arguments as String;
    _codeService.setProjectDir(_projectName);
    _flutterService.setProjectDir(_projectName);
    _loadExistingCode();
    _initializeBasePath();
    _fetchExplanationContent();
  }

  Future<void> _initializeBasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    _basePath = '${directory.path}\\crazzy_dev\\projects\\$_projectName';
    _loadProjectStructure();
  }

  void _loadProjectStructure() async {
    try {
      Directory projectDir = Directory(_basePath);
      if (!await projectDir.exists()) {
        setState(() {
          _status = 'Project directory not found: $_basePath';
          _terminalOutput +=
              '\n> Error: Project directory not found: $_basePath\n';
        });
        return;
      }
      List<ProjectFile> structure = await _createProjectStructure(projectDir);
      setState(() {
        _projectFiles = structure;
        _terminalOutput += '\n> Project structure loaded successfully\n';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading project structure: ${e.toString()}';
        _terminalOutput +=
            '\n> Error loading project structure: ${e.toString()}\n';
      });
    }
  }

  Future<List<ProjectFile>> _createProjectStructure(Directory directory) async {
    List<FileSystemEntity> entities = await directory.list().toList();
    entities.sort((a, b) {
      bool aIsDir = a is Directory;
      bool bIsDir = b is Directory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return path.basename(a.path).compareTo(path.basename(b.path));
    });

    List<ProjectFile> result = [];
    for (FileSystemEntity entity in entities) {
      String name = path.basename(entity.path);
      String relativePath =
          entity.path.replaceFirst(_basePath, '').replaceAll('\\', '/');
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
      if (relativePath.isEmpty) relativePath = '.';
      if (name.startsWith('.')) continue;

      if (entity is Directory) {
        if (['build', '.dart_tool', '.pub', '.idea', '.gradle', '.txt']
            .contains(name)) {
          continue;
        }
        List<ProjectFile> children = await _createProjectStructure(entity);
        result.add(ProjectFile(
          name: name,
          path: relativePath,
          icon: _getDirectoryIcon(name),
          isDirectory: true,
          children: children,
        ));
      } else if (entity is File) {
        result.add(ProjectFile(
          name: name,
          path: relativePath,
          icon: _getFileIcon(name),
          isDirectory: false,
        ));
      }
    }
    return result;
  }

  IconData _getDirectoryIcon(String dirName) {
    switch (dirName.toLowerCase()) {
      case 'lib':
        return Icons.source;
      case 'assets':
        return Icons.folder_special;
      case 'test':
        return Icons.science;
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.window;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.folder;
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.dart':
        return Icons.code;
      case '.txt':
        return Icons.text_fields;
      case '.yml':
      case '.yaml':
        return Icons.file_copy;
      case '.md':
        return Icons.description;
      case '.json':
        return Icons.data_object;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.svg':
        return Icons.image;
      case '.ttf':
      case '.otf':
        return Icons.text_fields;
      case '.cpp':
      case '.c':
      case '.h':
        return Icons.terminal;
      case '.gradle':
        return Icons.build;
      case '.xml':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _loadExistingCode() async {
    try {
      final code = await _codeService.getCurrentCode();
      setState(() {
        _code = code;
        _codeEditorController.text = code;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading code: ${e.toString()}';
        _terminalOutput += '\n> Error loading code: ${e.toString()}\n';
      });
    }
  }

  Future<void> _loadFileContent(String filePath) async {
    try {
      File file = File(path.join(_basePath, filePath));
      if (await file.exists()) {
        String content = await file.readAsString();
        setState(() {
          _code = content;
          _codeEditorController.text = content;
          _terminalOutput += '\n> Loaded file: $filePath\n';
        });
      } else {
        setState(() {
          _status = 'File not found: $filePath';
          _terminalOutput += '\n> Error: File not found: $filePath\n';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error loading file: ${e.toString()}';
        _terminalOutput += '\n> Error loading file: ${e.toString()}\n';
      });
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title:
            Text('Solve Error', style: GoogleFonts.roboto(color: Colors.white)),
        content: TextButton(
            onPressed: () => _showErrorMessageDialog(errorMessage),
            child: const Text(
              "Show Error \n (face 3-4 time regenerate code by giving prompt:regenerate code with no error)",
              style: TextStyle(color: Colors.red),
            )),
        actions: [
          ElevatedButton(
            onPressed: () {
              _executeAction(() async {
                final result = await _codeService.solveCode(errorMessage);
                return result['updatedCode'] as String;
              }, 'Solve Error');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child:
                Text('Solve', style: GoogleFonts.roboto(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showErrorMessageDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text('Error', style: GoogleFonts.roboto(color: Colors.white)),
        content: SingleChildScrollView(
          child: Container(
            child: Text(errorMessage),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(
      Future<String> Function() action, String buttonText,
      {bool force = false}) async {
    if (_isProcessing && !force) return;

    setState(() {
      _isProcessing = true;
      _status = 'Processing...';
      _terminalOutput += '\n> Running $buttonText...\n';
    });
    try {
      final result = await action();
      if (buttonText == 'Update App') {
        _promptController.clear();
        await _fetchExplanationContent();
      }
      setState(() {
        if (buttonText == 'Update App' || buttonText == 'Save') {
          _code = result;
          _codeEditorController.text = result;
        }
        _status = 'Success';
        _terminalOutput += '$result\n';
        _errors = 'No errors found.';
        _autoSolveAttempts = 0; // Reset attempts on success
      });
    } catch (e) {
      final errStr = e.toString();
      final apiErrorKeywords = [
        'SocketException',
        'Timeout',
        'Failed host lookup',
        'API',
        'Network',
        'Connection refused',
        'HandshakeException',
        'HttpException',
        'Supabase',
      ];
      bool isApiError = apiErrorKeywords.any((kw) => errStr.contains(kw));
      if (errStr ==
          "type 'Null' is not a subtype of type 'String' in type cast") {
        setState(() {
          _status = 'Success';
          _terminalOutput += 'Success\n';
          _autoSolveAttempts = 0;
        });
      }
      // else if (isApiError) {
      //   setState(() {
      //     _status = 'Error';
      //     _terminalOutput += '\n> Error:\nSorry AI is Busy!!\n';
      //     _errors = 'Sorry AI is Busy!!';
      //     print(errStr);
      //     _isProcessing = false;
      //   });
      // }
      else {
        // Auto-solve error logic
        await _autoSolveError(errStr);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _autoSolveError(String error) async {
    _autoSolveAttempts++;
    if (_autoSolveAttempts > 4) {
      setState(() {
        _status = 'Error';
        _terminalOutput += '\n> Error:\n$error\n';
        _errors = error;
      });
      _showErrorDialog(error);
      _autoSolveAttempts = 0;
      return;
    }
    setState(() {
      _status = 'Solving error... (Attempt $_autoSolveAttempts/4)';
      _terminalOutput +=
          '\n> Solving error... (Attempt $_autoSolveAttempts/4)\n';
    });
    try {
      final result = await _codeService.solveCode(error);
      setState(() {
        _code = result['updatedCode'] ?? _code;
        _codeEditorController.text = result['updatedCode'] ?? _code;
        _status = 'Error solved, re-running app...';
        _terminalOutput += '> Error solved, re-running app...\n';
        _errors = 'No errors found.';
      });
      await _autoRunOnLastPlatform();
    } catch (e) {
      await _autoSolveError(e.toString());
    }
  }

  Future<void> _autoRunOnLastPlatform() async {
    if (_lastRunPlatform == null) return;
    if (_autoSolveAttempts > 4) {
      setState(() {
        _status = 'Error';
        _terminalOutput += '\n> Error:\nExceeded 4 attempts\n';
        _errors = 'Exceeded 4 attempts';
      });
      _showErrorDialog('Exceeded 4 attempts');
      _autoSolveAttempts = 0;
      return;
    }
    try {
      switch (_lastRunPlatform) {
        case 'windows':
          await _executeAction(
              () => _flutterService.runAppOnWindows(), 'Run on Windows',
              force: true);
          break;
        case 'edge':
          await _executeAction(
              () => _flutterService.runAppOnEdge(), 'Run on Edge',
              force: true);
          break;
        case 'chrome':
          await _executeAction(
              () => _flutterService.runAppOnChrome(), 'Run on Chrome',
              force: true);
          break;
      }
    } catch (e) {
      await _autoSolveError(e.toString());
    }
  }

  void _openFile(String filePath) {
    if (!_openFiles.contains(filePath)) {
      setState(() => _openFiles.add(filePath));
    }
    setState(() {
      _currentFile = filePath;
      _loadFileContent(filePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildMainContent()),
              _buildStatusBar(),
              GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse('https://crazzy.dev'));
                },
                child: Container(
                  //color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Build with Flutter for Flutter',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rive Animation Container
                        SizedBox(
                          width: 300,
                          height: 300,
                          child: LoadingAnimationWidget.beat(
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      color: const Color(0xFF2D2D2D),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              launchUrl(Uri.parse('https://crazzy.dev'));
            },
            child: Container(
              //color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Need Production-Ready Code With Advanced Features? Visit',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    ' Crazzy.dev',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                  ),
                  Text(
                    ' for Free!!',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Text(_projectName,
                  style: GoogleFonts.roboto(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 32),
              _buildActionGroup([
                _buildActionButton('Run', Icons.play_arrow,
                    () => _showDeviceSelectionDialog()),
                _buildActionButton(
                    'Build', Icons.build, () => _showBuildTargetDialog()),
              ]),

              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to Projects'),
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    _loadProjectStructure();
                    _loadFileContent(_currentFile);
                  },
                  tooltip: 'Refresh'),
              //Export Code Button
              IconButton(
                icon: const Icon(Icons.file_upload, color: Colors.white),
                onPressed: _isProcessing ? null : _showExportCodeDialog,
                tooltip: 'Export Code',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionGroup(List<Widget> buttons) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Row(
        children: buttons.map((button) {
          final isLast = button == buttons.last;
          return Container(
            decoration: BoxDecoration(
              border: !isLast
                  ? const Border(
                      right: BorderSide(color: Color(0xFF3C3C3C)),
                    )
                  : null,
            ),
            child: button,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: _isProcessing ? Colors.white38 : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: _isProcessing ? Colors.white38 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        SizedBox(width: _explorerWidth, child: _buildProjectExplorer()),
        GestureDetector(
          onHorizontalDragUpdate: (details) => setState(() {
            _explorerWidth += details.delta.dx;
            if (_explorerWidth < 100) _explorerWidth = 100;
            if (_explorerWidth > 400) _explorerWidth = 400;
          }),
          child: Container(
              width: 5,
              color: const Color(0xFF3C3C3C),
              child: const Center(
                  child: Icon(Icons.drag_handle,
                      color: Colors.white70, size: 16))),
        ),
        Expanded(child: _buildCodeSection()),
        GestureDetector(
          onHorizontalDragUpdate: (details) => setState(() {
            _rightPanelWidth -= details.delta.dx;
            if (_rightPanelWidth < 100) _rightPanelWidth = 100;
            if (_rightPanelWidth > 500) _rightPanelWidth = 500;
          }),
          child: Container(
              width: 5,
              color: const Color(0xFF3C3C3C),
              child: const Center(
                  child: Icon(Icons.drag_handle,
                      color: Colors.white70, size: 16))),
        ),
        SizedBox(width: _rightPanelWidth, child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildProjectExplorer() {
    return Container(
      color: const Color(0xFF252526),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExplorerHeader(),
          Expanded(child: _buildFileTreeView()),
        ],
      ),
    );
  }

  Widget _buildExplorerHeader() {
    return Container(
      height: 35,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: const Color(0xFF252526),
      child: Row(
        children: [
          Text('EXPLORER',
              style: GoogleFonts.roboto(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
              onPressed: _loadProjectStructure,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Refresh'),
          const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.create_new_folder,
                  color: Colors.white70, size: 16),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'New Folder'),
          const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.white70, size: 16),
              onPressed: _createNewFile,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'New File'),
        ],
      ),
    );
  }

  Widget _buildFileTreeView() {
    return Container(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(_basePath,
                style: GoogleFonts.roboto(color: Colors.white60, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _projectFiles.isEmpty
                  ? [
                      const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0E639C)))))
                    ]
                  : _buildFileTree(_projectFiles, 0),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFileTree(List<ProjectFile> files, int level) {
    return files.map((file) {
      if (file.isDirectory) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                EdgeInsets.only(left: 16.0 + (level * 16.0), right: 8.0),
            title: Text(file.name,
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 13)),
            leading: Icon(file.icon, color: Colors.white70, size: 16),
            collapsedIconColor: Colors.white70,
            iconColor: Colors.white70,
            initiallyExpanded: level == 0 || file.name == 'lib',
            children: _buildFileTree(file.children, level + 1),
          ),
        );
      } else {
        return ListTile(
          leading: Icon(file.icon, color: Colors.white70, size: 16),
          title: Text(file.name,
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 13)),
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              EdgeInsets.only(left: 16.0 + (level * 16.0), right: 8.0),
          selected: _currentFile == file.path,
          selectedTileColor: const Color(0xFF37373D),
          onTap: () => _openFile(file.path),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white70, size: 16),
            onPressed: () => _deleteFile(file.path),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete File',
          ),
        );
      }
    }).toList();
  }

  Widget _buildRightPanel() {
    return Container(
      color: const Color(0xFF252526),
      child: Column(
        children: [
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF252526),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rightPanelTab = 'terminal'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _rightPanelTab == 'terminal'
                          ? const Color(0xFF1E1E1E)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('TERMINAL',
                        style: GoogleFonts.roboto(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _rightPanelTab = 'explanation');
                    _fetchExplanationContent();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _rightPanelTab == 'explanation'
                          ? const Color(0xFF1E1E1E)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('EXPLANATION',
                        style: GoogleFonts.roboto(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const Spacer(),
                if (_rightPanelTab == 'terminal')
                  IconButton(
                      icon: const Icon(Icons.refresh,
                          color: Colors.white70, size: 16),
                      onPressed: () {
                        setState(() {
                          _terminalOutput = 'Terminal cleared.\n';
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Clear Terminal'),
                if (_rightPanelTab == 'explanation')
                  IconButton(
                      icon: const Icon(Icons.copy,
                          color: Colors.white70, size: 16),
                      onPressed: () {
                        if (_explanationContent.isNotEmpty) {
                          Clipboard.setData(
                              ClipboardData(text: _explanationContent));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Explanation copied!')),
                          );
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy Explanation'),
              ],
            ),
          ),
          Expanded(
            child: _rightPanelTab == 'terminal'
                ? _buildTerminalSection()
                : _buildExplanationSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF3C3C3C))),
      child: SingleChildScrollView(
          child: SelectableText(
        _terminalOutput,
        style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
      )),
    );
  }

  Widget _buildExplanationSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF3C3C3C))),
      child: SingleChildScrollView(
        child: SelectableText(
          _explanationContent,
          style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCodeSection() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(child: _buildCodeEditor()),
        _buildPromptWindow(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 36,
      color: const Color(0xFF2D2D2D),
      child: Row(
        children: _openFiles.map((file) {
          return GestureDetector(
            onTap: () => _openFile(file),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: file == _currentFile
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFF2D2D2D),
                border: Border(
                    bottom: BorderSide(
                        color: file == _currentFile
                            ? const Color(0xFF0E639C)
                            : Colors.transparent,
                        width: 2)),
              ),
              child: Row(
                children: [
                  Icon(_getFileIcon(file), color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(path.basename(file),
                      style: GoogleFonts.roboto(
                          color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _openFiles.remove(file);
                      if (_currentFile == file && _openFiles.isNotEmpty) {
                        _currentFile = _openFiles.first;
                        _loadFileContent(_currentFile);
                      }
                    }),
                    child: const Icon(Icons.close,
                        color: Colors.white70, size: 16),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          if (!_isManualEdit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: HighlightView(
                  _code,
                  language: _getLanguageFromFile(_currentFile),
                  theme: vs2015Theme,
                  padding: const EdgeInsets.all(16),
                  textStyle: GoogleFonts.sourceCodePro(fontSize: 14),
                ),
              ),
            ),
          if (_isManualEdit)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _codeEditorController,
                decoration: const InputDecoration(
                    border: InputBorder.none, contentPadding: EdgeInsets.zero),
                style: GoogleFonts.sourceCodePro(
                    color: Colors.white, fontSize: 14),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                expands: true,
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isManualEdit = !_isManualEdit;
                      if (!_isManualEdit &&
                          _codeEditorController.text != _code) {
                        _executeAction(() async {
                          try {
                            File file =
                                File(path.join(_basePath, _currentFile));
                            await file
                                .writeAsString(_codeEditorController.text);
                            return "File saved: $_currentFile";
                          } catch (e) {
                            throw Exception(
                                "Error saving file: ${e.toString()}");
                          }
                        }, 'Save');
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C3C3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8)),
                  child: Text(_isManualEdit ? 'View Mode' : 'Edit Mode',
                      style: GoogleFonts.roboto(fontSize: 12)),
                ),
                if (_isManualEdit) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _executeAction(() async {
                              try {
                                File file =
                                    File(path.join(_basePath, _currentFile));
                                await file
                                    .writeAsString(_codeEditorController.text);
                                return "File saved: $_currentFile";
                              } catch (e) {
                                throw Exception(
                                    "Error saving file: ${e.toString()}");
                              }
                            }, 'Save'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E639C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8)),
                    child:
                        Text('Save', style: GoogleFonts.roboto(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageFromFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.dart':
        return 'dart';
      case '.txt':
        return 'txt';
      case '.java':
        return 'java';
      case '.kt':
        return 'kotlin';
      case '.swift':
        return 'swift';
      case '.js':
        return 'javascript';
      case '.json':
        return 'json';
      case '.yml':
      case '.yaml':
        return 'yaml';
      case '.md':
        return 'markdown';
      case '.xml':
        return 'xml';
      case '.html':
        return 'html';
      case '.css':
        return 'css';
      case '.cpp':
        return 'cpp';
      case '.c':
        return 'c';
      case '.h':
        return 'cpp';
      case '.sh':
        return 'bash';
      case '.properties':
        return 'properties';
      default:
        return 'plaintext';
    }
  }

  Widget _buildPromptWindow() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isPromptWindowExpanded ? _promptWindowHeight : 40,
      color: const Color(0xFF252526),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(
                () => _isPromptWindowExpanded = !_isPromptWindowExpanded),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF2D2D2D),
              child: Row(
                children: [
                  Text('PROMPT',
                      style: GoogleFonts.roboto(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const SizedBox(width: 8),
                  Icon(
                      _isPromptWindowExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.white70,
                      size: 16),
                ],
              ),
            ),
          ),
          if (_isPromptWindowExpanded)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (!_supabaseHelperExists)
                          ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () async {
                                      final anonKeyController =
                                          TextEditingController();
                                      final urlController =
                                          TextEditingController();
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              const Color(0xFF2D2D2D),
                                          title: Text('Add Supabase',
                                              style: GoogleFonts.roboto(
                                                  color: Colors.white)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: urlController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Supabase URL',
                                                  labelStyle: TextStyle(
                                                      color: Colors.white70),
                                                  filled: true,
                                                  fillColor: Color(0xFF424242),
                                                ),
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              const SizedBox(height: 16),
                                              TextField(
                                                controller: anonKeyController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Anon Key',
                                                  labelStyle: TextStyle(
                                                      color: Colors.white70),
                                                  filled: true,
                                                  fillColor: Color(0xFF424242),
                                                ),
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text('Cancel',
                                                  style: GoogleFonts.roboto(
                                                      color: Colors.white70)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                setState(() {
                                                  _isProcessing = true;
                                                  _status =
                                                      'Adding Supabase...';
                                                  _terminalOutput +=
                                                      '\n> Adding Supabase...\n';
                                                });
                                                try {
                                                  await _codeService
                                                      .addSupabase(
                                                          urlController.text
                                                              .trim(),
                                                          anonKeyController.text
                                                              .trim());
                                                  setState(() {
                                                    _status =
                                                        'Successfully added Supabase';
                                                    _terminalOutput +=
                                                        '> Successfully added Supabase\n';
                                                  });
                                                  await _checkSupabaseHelperExists();
                                                } catch (e) {
                                                  setState(() {
                                                    _status =
                                                        'Error adding Supabase';
                                                    _terminalOutput +=
                                                        '> Error: \u001b[31m"+e.toString()+"\n';
                                                  });
                                                } finally {
                                                  setState(() {
                                                    _isProcessing = false;
                                                  });
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green.shade800),
                                              child: Text('Add',
                                                  style: GoogleFonts.roboto(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade800),
                              child: Text(
                                "Add Supabase",
                                style: GoogleFonts.roboto(color: Colors.white),
                              )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: InputDecoration(
                          hintText: _includeBackend
                              ? 'e.g., Add a login screen with email and password fields with Supabase authentication'
                              : 'e.g., Add a login screen with email and password fields',
                          hintStyle: GoogleFonts.roboto(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF3C3C3C),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: GoogleFonts.roboto(color: Colors.white),
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          setState(() {
                            // Calculate the number of lines in the text
                            final lines = value.split('\n').length;
                            // Set a minimum height of 200 and add 20 pixels per line after the first line
                            final newHeight = 200.0 + ((lines - 1) * 20.0);
                            // Limit the maximum height to 400 pixels
                            _promptWindowHeight = newHeight.clamp(200.0, 400.0);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _isProcessing
                                ? null
                                : _executeAction(() async {
                                    String prompt = _promptController.text;
                                    if (_includeBackend) {
                                      prompt += '''
                              
Please implement Supabase as the backend for this feature. Include:
1. Supabase client setup and configuration
2. Authentication screens (if needed)
3. Database tables and relationships
4. API integration with Supabase
5. Error handling and loading states
6. Proper state management for backend operations
''';
                                    }
                                    final result =
                                        await _codeService.updateCode(prompt);
                                    return result['updatedCode'] as String;
                                  }, 'Update App');
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _isProcessing
                                  ? Colors.grey
                                  : const Color(0xFF0E639C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8)),
                          child: Text('Update With AI',
                              style: GoogleFonts.roboto(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 22,
      color: const Color(0xFF007ACC),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(_status,
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 12)),
          const Spacer(),
          Text(_getLanguageFromFile(_currentFile).toUpperCase(),
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 12)),
          const SizedBox(width: 16),
          Text('UTF-8',
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _fetchExplanationContent() async {
    try {
      final explanationContent =
          await _codeService.getFileContent('_Explanation.dart');
      setState(() {
        _explanationContent = explanationContent;
      });
    } catch (e) {
      setState(() {
        _explanationContent = 'No explanation found.';
      });
    }
  }

  void _showDeviceSelectionDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text('Select Platform',
            style: GoogleFonts.roboto(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _lastRunPlatform = 'windows';
                });
                _executeAction(
                    () => _flutterService.runAppOnWindows(), 'Run on Windows');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 40),
              ),
              child: Text('Run on Windows',
                  style: GoogleFonts.roboto(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _lastRunPlatform = 'edge';
                });
                _executeAction(
                    () => _flutterService.runAppOnEdge(), 'Run on Edge');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 40),
              ),
              child: Text('Run on Edge',
                  style: GoogleFonts.roboto(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _lastRunPlatform = 'chrome';
                });
                _executeAction(
                    () => _flutterService.runAppOnChrome(), 'Run on Chrome');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 40),
              ),
              child: Text('Run on Chrome',
                  style: GoogleFonts.roboto(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _createNewFile() async {
    final TextEditingController fileNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text('Create New File',
            style: GoogleFonts.roboto(color: Colors.white)),
        content: TextField(
          controller: fileNameController,
          style: GoogleFonts.roboto(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter file name (e.g., new_file.dart)',
            hintStyle: GoogleFonts.roboto(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final fileName = fileNameController.text.trim();
              if (fileName.isNotEmpty) {
                Navigator.pop(context);
                setState(() {
                  _isProcessing = true;
                  _status = 'Creating new file...';
                  _terminalOutput += '\n> Creating new file: $fileName\n';
                });
                try {
                  final file = File(path.join(_basePath, 'lib', fileName));
                  if (await file.exists()) {
                    throw Exception('File already exists');
                  }
                  await file.create(recursive: true);
                  await file.writeAsString('''
import 'package:flutter/material.dart';

// Your code here
''');
                  setState(() {
                    _status = 'File created successfully';
                    _terminalOutput += '> File created successfully\n';
                    _loadProjectStructure();
                    _openFile('lib/$fileName');
                  });
                } catch (e) {
                  setState(() {
                    _status = 'Error creating file';
                    _terminalOutput += '> Error: ${e.toString()}\n';
                  });
                } finally {
                  setState(() {
                    _isProcessing = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C),
                foregroundColor: Colors.white),
            child:
                Text('Create', style: GoogleFonts.roboto(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteFile(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title:
            Text('Delete File', style: GoogleFonts.roboto(color: Colors.white)),
        content: Text('Are you sure you want to delete $filePath?',
            style: GoogleFonts.roboto(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isProcessing = true;
                _status = 'Deleting file...';
                _terminalOutput += '\n> Deleting file: $filePath\n';
              });
              try {
                final file = File(path.join(_basePath, filePath));
                if (!await file.exists()) {
                  throw Exception('File does not exist');
                }
                await file.delete();
                setState(() {
                  _status = 'File deleted successfully';
                  _terminalOutput += '> File deleted successfully\n';
                  _loadProjectStructure();
                  if (_currentFile == filePath) {
                    _currentFile = 'lib/main.dart';
                    _loadFileContent(_currentFile);
                  }
                });
              } catch (e) {
                setState(() {
                  _status = 'Error deleting file';
                  _terminalOutput += '> Error: ${e.toString()}\n';
                });
              } finally {
                setState(() {
                  _isProcessing = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white),
            child:
                Text('Delete', style: GoogleFonts.roboto(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSupabaseHelperExists() async {
    final dir = Directory('lib');
    final exists = await File('lib/_SupabaseHelper.dart').exists();
    setState(() {
      _supabaseHelperExists = exists;
    });
  }

  Future<void> _showExportCodeDialog() async {
    setState(() => _isProcessing = true);
    try {
      // Get all .dart files in lib
      final libDir = Directory(path.join(_basePath, 'lib'));
      final files = await libDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.dart'))
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      String exportContent = '';
      for (final file in files) {
        final filename = path.basename(file.path);
        final code = await File(file.path).readAsString();
        exportContent += '//File: $filename\n$code\n\n';
      }
      // Get dependencies from pubspec.yaml
      final pubspecFile = File(path.join(_basePath, 'pubspec.yaml'));
      List<String> dependencies = [];
      if (await pubspecFile.exists()) {
        final pubspecContent = await pubspecFile.readAsString();
        final depReg = RegExp(r'^\s*([a-zA-Z0-9_\-]+):', multiLine: true);
        final depSection = pubspecContent.split('dependencies:').length > 1
            ? pubspecContent.split('dependencies:')[1]
            : '';
        for (final match in depReg.allMatches(depSection)) {
          final dep = match.group(1);
          if (dep != null &&
              dep != 'flutter' &&
              dep != 'cupertino_icons' &&
              dep != 'sdk') {
            dependencies.add(dep.trim());
          }
        }
      }
      exportContent += '\n//Dependencies: [${dependencies.join(', ')}]';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: Text('Exported Code',
              style: GoogleFonts.roboto(color: Colors.white)),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: SelectableText(exportContent,
                  style: GoogleFonts.robotoMono(
                      color: Colors.white70, fontSize: 12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: exportContent));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exported code copied!')),
                );
              },
              child:
                  Text('Copy', style: GoogleFonts.roboto(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: GoogleFonts.roboto(color: Colors.white70)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting code: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showBuildTargetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text('Select Build Target',
            style: GoogleFonts.roboto(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _buildTarget = 'apk');
                _executeAction(() => _flutterService.buildApp('apk'), 'Build');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 40),
              ),
              child: Text('Android APK',
                  style: GoogleFonts.roboto(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _buildTarget = 'web');
                _executeAction(() => _flutterService.buildApp('web'), 'Build');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 40),
              ),
              child:
                  Text('Web', style: GoogleFonts.roboto(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _buildTarget = 'appbundle');
                _executeAction(
                    () => _flutterService.buildApp('appbundle'), 'Build');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 40),
              ),
              child: Text('Appbundle',
                  style: GoogleFonts.roboto(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
