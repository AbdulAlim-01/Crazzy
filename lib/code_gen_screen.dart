import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'code_service.dart';
import 'flutter_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class CodeGenScreen extends StatefulWidget {
  const CodeGenScreen({super.key});

  @override
  _CodeGenScreenState createState() => _CodeGenScreenState();
}

class _CodeGenScreenState extends State<CodeGenScreen> {
  final CodeService _codeService = CodeService();
  final FlutterService _flutterService = FlutterService();
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool _isPromptWindowExpanded = false;
  bool _isProcessing = false;
  String _status = '';
  String _buildTarget = 'apk';
  final String _currentFile = '';
  String _code = '';
  Map<String, dynamic>? _userProfile;
  late String _projectName;
  bool _isInputFocused = false;
  int _currentCredits = 0;
  List<Map<String, dynamic>> _templates = [];
  bool _isLoadingTemplates = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _projectName = ModalRoute.of(context)!.settings.arguments as String;
    _codeService.setProjectDir(_projectName);
    _flutterService.setProjectDir(_projectName);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _executeAction(
      Future<String> Function() action, String buttonText) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Processing...';
    });
    try {
      final result = await action();
      setState(() {
        if (buttonText == 'Generate') {
          _code = result;
        }
        _status = result;
      });
      if (buttonText == 'Generate') {
        Navigator.of(context)
            .pushReplacementNamed('/update', arguments: _projectName);
      }
    } catch (e) {
      setState(() {
        if (e.toString() ==
            "type 'Null' is not a subtype of type 'String' in type cast") {
          _status = 'Success';
          Navigator.of(context)
              .pushReplacementNamed('/update', arguments: _projectName);
        } else {
          _status = 'Error: ${e.toString()}';
        }
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(
              'Crazzy (Community-Edition)',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              ' • AI App Generator',
              style: GoogleFonts.montserrat(
                color: Colors.grey,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3E50),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Credits: $_currentCredits',
                    style: GoogleFonts.roboto(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.person, color: Colors.white70),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Hey ${_userProfile?['full_name'] ?? 'there'}, ',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 32,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'How would you like your app to look?',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),

                        // Custom Input Section
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          constraints: const BoxConstraints(maxWidth: 800),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isInputFocused
                                  ? Colors.blue
                                  : Colors.grey.shade800,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Focus(
                                  onFocusChange: (hasFocus) {
                                    setState(() {
                                      _isInputFocused = hasFocus;
                                    });
                                  },
                                  child: TextField(
                                    controller: _promptController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Describe your app (e.g., A todo list app with a blue theme)',
                                      hintStyle: GoogleFonts.montserrat(
                                          color: Colors.grey),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 12),
                                    ),
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white, fontSize: 16),
                                    maxLines: 3,
                                    minLines: 1,
                                  ),
                                ),
                              ),
                              Divider(color: Colors.grey.shade800, height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    DropdownButton<String>(
                                      value: _buildTarget,
                                      dropdownColor: const Color(0xFF2C2C2C),
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white),
                                      icon: const Icon(Icons.arrow_drop_down,
                                          color: Colors.grey),
                                      underline: Container(),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'apk',
                                            child: Text('Android APK')),
                                        DropdownMenuItem(
                                            value: 'web', child: Text('Web')),
                                        DropdownMenuItem(
                                            value: 'windows',
                                            child: Text('Windows')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _buildTarget = value;
                                          });
                                        }
                                      },
                                    ),
                                    const Spacer(),
                                    _isProcessing
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.blue),
                                            ),
                                          )
                                        : _buildToolbarButton(
                                            Icons.send,
                                            'Generate',
                                            onPressed: () => _executeAction(
                                              () async {
                                                final result =
                                                    await _codeService
                                                        .generateCode(
                                                            _promptController
                                                                .text);
                                                return result['code'] as String;
                                              },
                                              'Generate',
                                            ),
                                            primary: true,
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              if (_status.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade900,
                  child: Text(
                    _status,
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),

          // Rive Loading Animation Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rive Animation Container
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: LoadingAnimationWidget.beat(
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Processing your request...',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few moments',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label,
      {VoidCallback? onPressed, bool primary = false}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : Colors.grey,
              size: 20,
            ),
            if (label.isNotEmpty) const SizedBox(width: 8),
            if (label.isNotEmpty)
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: primary ? Colors.white : Colors.grey,
                  fontWeight: primary ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildActionButton(
          'Latest News',
          Icons.article,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('News feature coming soon!')),
            );
          },
        ),
        _buildActionButton(
          'Run App',
          Icons.play_arrow,
          onTap: () => _executeAction(() => _flutterService.runApp(), 'Run'),
        ),
        _buildActionButton(
          'Build App',
          Icons.build,
          onTap: () => _executeAction(
              () => _flutterService.buildApp(_buildTarget), 'Build'),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
