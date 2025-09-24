import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'project_service.dart';
import 'code_service.dart';
import 'flutter_service.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectService _projectService = ProjectService();
  final CodeService _codeService = CodeService();
  final FlutterService _flutterService = FlutterService();
  List<String> _projects = [];
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  bool _checkingFlutter = false;
  String? _geminiKey;

  @override
  void initState() {
    super.initState();

    _checkingFlutter = true;
    _checkFlutterInstallation();
    _checkGeminiKey();
  }

  Future<void> _checkFlutterInstallation() async {
    final isInstalled = await _flutterService.isFlutterInstalled();
    if (!isInstalled && mounted) {
      setState(() => _checkingFlutter = false);
      _showFlutterInstallationDialog();
    } else {
      setState(() => _checkingFlutter = false);
      _loadProjects();
    }
  }

  Future<void> _checkGeminiKey() async {
    final key = await _codeService.getGeminiApiKey();
    setState(() => _geminiKey = key);
    if ((key == null || key.isEmpty) && mounted) {
      _showApiKeyDialog();
    }
  }

  void _showFlutterInstallationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text('Flutter Not Installed',
            style: GoogleFonts.roboto(color: Colors.white)),
        content: Text(
          'Flutter is required to use this application. Please install Flutter to continue.',
          style: GoogleFonts.roboto(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _launchURL(
                'https://docs.flutter.dev/get-started/install/windows'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C)),
            child: Text('Download Flutter',
                style: GoogleFonts.roboto(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _geminiKey ?? '');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text('Set Gemini API Key',
            style: GoogleFonts.roboto(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your Gemini API key:",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'AIza... or your key',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0E639C))),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('API key cannot be empty'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              await _codeService.setGeminiApiKey(value);
              if (mounted) {
                setState(() => _geminiKey = value);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Gemini API key saved'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C)),
            child: Text('Save',
                style: GoogleFonts.roboto(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    await launchUrl(Uri.parse(url));
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final projects = await _projectService.getExistingProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading projects: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _hasCodeBeenGenerated(String projectName) async {
    await _codeService.setProjectDir(projectName);
    try {
      final code = await _codeService.getCurrentCode();
      return code.isNotEmpty &&
          !code.contains('void main() { runApp(const MyApp()); }');
    } catch (e) {
      return false;
    }
  }

  void _showCreateProjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text('Create New Project',
            style: GoogleFonts.roboto(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Project Name: ",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.start,
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'smallcase(use_only)',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0E639C))),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFFA000))),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    final name = controller.text.trim();
                    if (name.isEmpty ||
                        !RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(name)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please enter a valid project name (letters, numbers, underscores, hyphens only)'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    try {
                      await _projectService.createProject(name);
                     // await _incrementAnalytics('open projects');
                      await _loadProjects();
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .pushNamed('/code-gen', arguments: name);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E639C)),
            child: Text('Create',
                style: GoogleFonts.roboto(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // Future<void> _incrementAnalytics(String name) async {
  //   try {
  //     final analytics = Supabase.instance.client.from('analytics');
  //     final response =
  //         await analytics.select('value').eq('name', name).maybeSingle();
  //     if (response == null) {
  //       // Insert new row if not exists
  //       await analytics.insert({'name': name, 'value': 1});
  //     } else {
  //       final value = response['value'];
  //       final currentValue =
  //           value is int ? value : int.tryParse(value.toString()) ?? 0;
  //       final updateValue = currentValue + 1;
  //       await analytics.update({'value': updateValue}).eq('name', name);
  //     }
  //   } catch (e) {
  //     print('Error incrementing analytics for $name: $e');
  //   }
  // }

  void _showProfileDropdown() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _userProfile?['full_name'] ?? 'User',
              style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            Future.delayed(
                const Duration(milliseconds: 150), _showApiKeyDialog);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.vpn_key, color: Colors.white70),
                const SizedBox(width: 8),
                Text('Set Gemini API Key',
                    style: GoogleFonts.roboto(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ),
        // PopupMenuItem(
        //   onTap: () async {
        //     await Supabase.instance.client.auth.signOut();
        //     if (mounted) {
        //       Navigator.pushReplacement(context,
        //           MaterialPageRoute(builder: (context) => const LoginScreen()));
          //   }
          // },
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 8.0),
        //     child: Row(
        //       children: [
        //         const Icon(Icons.logout, color: Colors.white70),
        //         const SizedBox(width: 8),
        //         Text('Logout',
        //             style: GoogleFonts.roboto(
        //                 color: Colors.white70, fontSize: 14)),
        //       ],
        //     ),
        //   ),
        // ),
      ],
      color: const Color(0xFF2C3E50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color.fromARGB(255, 12, 12, 12),
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 12, 12, 12),
            elevation: 0,
            title: Column(
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
                          style:
                              TextStyle(color: Colors.deepOrange, fontSize: 12),
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
                    Image.asset(
                      'assets/logo.png',
                      width: 32,
                    ),
                    const SizedBox(width: 16),
                    Text('Crazzy (Community-Edition)',
                        style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 22)),
                    Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          launchUrl(Uri.parse('https://crazzy.dev'));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Star on GitHub',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: _showProfileDropdown,
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF0E639C),
                    child: Text(
                      _userProfile?['full_name']
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text('Recent projects',
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0E639C))))
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                (MediaQuery.of(context).size.width / 300)
                                    .floor(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _projects.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) return _buildCreateProjectCard();
                            final projectName = _projects[index - 1];
                            return _buildProjectCard(projectName);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('All Crazzy projects',
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500)),
                ),
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
        ),
        if (_checkingFlutter)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E639C)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCreateProjectCard() {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF0E639C), width: 1)),
      child: InkWell(
        onTap: _showCreateProjectDialog,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0E639C), Color.fromARGB(255, 8, 22, 91)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.code, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Create a Crazzy',
                style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16)),
            Text('project',
                style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(String projectName) {
    final colorValue = projectName.hashCode & 0xFFFFFF;
    const cardColor = Color(0xFF2A2A2A);
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () async {
          final hasCode = await _hasCodeBeenGenerated(projectName);
          Navigator.of(context).pushNamed(hasCode ? '/update' : '/code-gen',
              arguments: projectName);
        },
        onLongPress: () => _showDeleteProjectDialog(projectName),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(projectName,
                        style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(projectName.toLowerCase().replaceAll(' ', '-'),
                        style: GoogleFonts.roboto(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    FutureBuilder<DateTime>(
                      future: _getProjectLastModified(projectName),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                              'Last modified: ${_formatDate(snapshot.data!)}',
                              style: GoogleFonts.roboto(
                                  color: Colors.white54, fontSize: 11));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white70, size: 20),
                      onPressed: () => _showDeleteProjectDialog(projectName),
                      tooltip: 'Delete Project',
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.code,
                          color: Colors.white70, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime> _getProjectLastModified(String projectName) async {
    try {
      final projectsDir = await _projectService.getProjectsDir();
      final projectDir = Directory('$projectsDir/$projectName');
      final stat = await projectDir.stat();
      return stat.changed;
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return difference.inHours == 0
          ? '${difference.inMinutes}m ago'
          : '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteProjectDialog(String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text('Delete Project',
            style: GoogleFonts.roboto(color: Colors.white)),
        content: Text(
            'Are you sure you want to delete "$projectName"? This action cannot be undone.',
            style: GoogleFonts.roboto(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.roboto(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              try {
                await _projectService.deleteProject(projectName);
                await _loadProjects();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Project "$projectName" deleted successfully'),
                      backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error deleting project: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete',
                style: GoogleFonts.roboto(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
