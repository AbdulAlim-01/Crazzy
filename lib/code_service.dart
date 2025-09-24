import 'package:crazzy_ai_tool/network_images.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
// import 'package:supabase_flutter/supabase_flutter.dart';

class CodeService {
  String? _projectDir;
  final FileSystem _fs = const LocalFileSystem();
  String? _explanation;
  Map<String, dynamic>? _lastCodeJson;
  Map exampleImage = exampleImages;

  String apiKey = '';
  static const String _geminiKeyPrefKey = 'gemini_api_key';

  Future<void> setGeminiApiKey(String key) async {
    final trimmed = key.trim();
    apiKey = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKeyPrefKey, trimmed);
  }

  Future<String?> getGeminiApiKey() async {
    if (apiKey.isNotEmpty) return apiKey;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_geminiKeyPrefKey);
    if (stored != null && stored.trim().isNotEmpty) {
      apiKey = stored.trim();
      return apiKey;
    }
    return null;
  }

  Future<void> _ensureApiKeyLoaded() async {
    if (apiKey.isEmpty) {
      await getGeminiApiKey();
    }
  }

  Future<void> setProjectDir(String projectName) async {
    final baseDir = await getApplicationDocumentsDirectory();
    _projectDir =
        path.join(baseDir.path, 'crazzy_dev', 'projects', projectName);
  }

  Future<Map<String, dynamic>> _getCurrentCodeJson() async {
    if (_projectDir == null) throw Exception('No project selected');

    try {
      final libDir = _fs.directory(path.join(_projectDir!, 'lib'));
      if (!await libDir.exists()) {
        return {
          'Code': [],
          'Dependencies': [],
          'Instruction': 'No project files found'
        };
      }

      final List<Map<String, String>> files = [];
      await for (final entity in libDir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final filename = path.basename(entity.path);
          final code = await entity.readAsString();
          if (code.trim().isNotEmpty) {
            files.add({'filename': filename, 'code': code});
          }
        }
      }

      return {'Code': files, 'Instruction': 'Current project code'};
    } catch (e) {
      print('Error getting current code JSON: $e');
      return {
        'Code': [],
        'Dependencies': [],
        'Instruction': 'Error reading project files: $e'
      };
    }
  }

  Future<String> getCurrentCode() async {
    if (_projectDir == null) throw Exception('No project selected');
    final file = _fs.file(path.join(_projectDir!, 'lib', 'main.dart'));
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      return "";
    }
  }

  String? getExplanation() => _explanation;

  Map<String, dynamic>? getLastCodeJson() => _lastCodeJson;

  Future<Map<String, dynamic>> _mergeCodeWithExisting(
      Map<String, dynamic> newCodeJson) async {
    // First, get all existing files from the project
    final existingCodeJson = await _getCurrentCodeJson();

    // if (_lastCodeJson != null) {
    //   existingCodeJson = Map<String, dynamic>.from(_lastCodeJson!);
    // } else {
    //   // Try to reconstruct from files if _lastCodeJson is null
    //   existingCodeJson = await _reconstructCodeJsonFromFiles();
    // }

    // If no existing code, return the new code as is
    if (existingCodeJson['Code'] == null) {
      return newCodeJson;
    }

    // Create a map of existing files for easy lookup
    final Map<String, Map<String, String>> existingFiles = {};
    final List<dynamic> existingCodeList = existingCodeJson['Code'];

    for (final file in existingCodeList) {
      if (file is Map && file['filename'] != null) {
        existingFiles[file['filename'].toString()] = {
          'filename': file['filename'].toString(),
          'code': file['code']?.toString() ?? '',
        };
      }
    }

    // Process new/updated files
    final List<dynamic> newCodeList = newCodeJson['Code'] ?? [];
    for (final file in newCodeList) {
      if (file is Map && file['filename'] != null) {
        final filename = file['filename'].toString();
        existingFiles[filename] = {
          'filename': filename,
          'code': file['code']?.toString() ?? '',
        };
        print('Updated/Added file: $filename');
      }
    }

    // Convert back to list format
    final List<Map<String, String>> mergedCodeList =
        existingFiles.values.toList();

    // Merge dependencies
    final Set<String> allDependencies = {};

    // Add existing dependencies
    if (existingCodeJson['Dependencies'] is List) {
      for (final dep in existingCodeJson['Dependencies']) {
        allDependencies.add(dep.toString().trim());
      }
    }

    // Add new dependencies
    if (newCodeJson['Dependencies'] is List) {
      for (final dep in newCodeJson['Dependencies']) {
        allDependencies.add(dep.toString().trim());
      }
    }

    return {
      'Code': mergedCodeList,
      'Dependencies': allDependencies.toList(),
      'Instruction': newCodeJson['Instruction'] ?? 'Updated project code',
      'status': 'success'
    };
  }

  Future<Map<String, dynamic>> generateCode(String description) async {
    if (_projectDir == null) throw Exception('No project selected');
    // final projectName = path.basename(_projectDir!);

    try {



      final prompt = '''
Suppose you are an expert Flutter developer specializing in creating games and advanced AI-driven apps, tasked with generating code for: $description. Provide complete, error-free Dart code for a Flutter app in a single response, structured with comments indicating separate files, and list required dependencies at the end in a structured format. Follow this example structure:

// File: main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  *Always include in main.dart
import 'home_page.dart'; 
void main() => runApp(const MyApp());
...

// File: home_page.dart 
home_page.dart code...

// File: _AppConstant.dart *ALways generate with required content
in this file add constant which user can change from here and change will show in full app like
bg color,app name

// File: _Explanation.dart *Always generate this file last with detailed content
// Provide a clear explanation of the code structure, state management, and UI components
// Specify where to add assets (if any), APIs (if required), and permissions in AndroidManifest.xml (e.g., android.permission.INTERNET)
// Explain the purpose of each file and how they interact
// Avoid unnecessary details; keep it concise and relevant

// File: readme.dart // Always generate this file last
in this file add content like "Thank you for using Crazzy" and on how to use the app

*Add a blank line here to separate from dependencies

// Dependencies: [http, provider] // Always include  list packages in one line, exclude flutter_service, flutter_lints

Ensure the following:
- Produce responsive, modern, production-ready code with no bugs or errors.
- Use network images from $exampleImage for dummy data; avoid local assets unless necessary (e.g., product images).
- Include all necessary imports in each file.
- Use dummy data for functionality, avoiding real backend APIs unless required (e.g., Google Maps).
- Set debugShowCheckedModeBanner: false in main.dart.
- Implement device_preview with proper setup in main.dart (enabled: !kReleaseMode).
- Ensure each file contains valid, non-empty Dart code.
- Use flame package for games if needed.


State Management and Architecture:
- Follow clean architecture with separate layers for UI, logic, and data.
- Ensure modular code with reusable widgets and clear separation of concerns.

Asset Handling:
- Use $exampleImage  for network-based dummy data.
- If assets are required, document their usage and placement in _Explanation.dart and readme.dart.

Code Quality:
- Write concise, maintainable code following Dart style guidelines.
- Avoid runtime errors, null pointer exceptions, or unhandled edge cases.
- Include error handling for user inputs and async operations.
- Validate responsiveness across different screen sizes.

The code should reflect modern Flutter development practices, delivering a professional, engaging app with no hangs, crashes, or bugs.
''';
      final result = await _callGeminiApi(prompt, 'gemini-2.5-pro');

      final response = result['response'].toString();

      final codeJson = _parseGeneratedCode(response);
      _lastCodeJson = codeJson;
      await _saveFilesFromJson(codeJson);
      await _updateDependenciesFromJson(codeJson);
      _explanation = codeJson['Instruction'] ?? 'Generated complete app code';
      return codeJson;
    } catch (e) {

      if (e
          .toString()
          .contains('type "Null" is not a subtype of type "String"')) {
        // Handle the null type cast error gracefully
        print('Handling null type cast error gracefully');
        return {
          'Code': [
            {
              'filename': 'main.dart',
              'code': '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(child: Text('Generated Flutter App')),
      ),
    );
  }
}
'''
            }
          ],
          'Dependencies': [],
          'Instruction': 'Generated default app due to parsing error',
          'status': 'success'
        };
      }
      rethrow; // Re-throw other errors
    }
  }

  Future<Map<String, dynamic>> updateCode(String updatePrompt) async {
    if (_projectDir == null) throw Exception('No project selected');
    // final projectName = path.basename(_projectDir!);

    final currentCodeJson = await _getCurrentCodeJson();
    if (currentCodeJson['Code'] == null ||
        (currentCodeJson['Code'] as List).isEmpty) {
      throw Exception('No previous code found. Generate code first.');
    }

    try {
      // Check and deduct credits before making API call

      final codeJsonString = jsonEncode(currentCodeJson);
      final prompt = '''
You are an expert Flutter developer specializing in games and advanced AI-driven apps, tasked with updating the following existing Flutter code: $codeJsonString. Add the functionality described in: $updatePrompt.

IMPORTANT: Only generate new files or modify existing files that require updates to implement the new functionality. Do not regenerate unchanged files unless necessary for the update.

Provide the updated or new Dart code files in a single response, structured with comments indicating separate files, and list only new dependencies at the end in a structured format. Follow this example:

// File: main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Always include in main.dart
import 'home_page.dart';
void main() => runApp(const MyApp());
...

// File: home_page.dart 
home_page.dart code...

// File: _Explanation.dart // Always generate this file with detailed content
// Explain the changes made, including:
// - Purpose of updated or new files and how they integrate with existing code
// - State management updates (if any)
// - UI modifications and their impact
// - Asset usage (if any), specifying placement
// - APIs (if required), including which ones and where to configure
// - Permissions required in AndroidManifest.xml (e.g., android.permission.INTERNET)
// Keep explanations concise, relevant, and free of unnecessary details

// File: _SupabaseHelper.dart (generate if required)
//in this file only generate sql code for supabase tables and row level security (RLS) policies and rules with no bs just code 
//which user can easily copy and paste in supabase dashboard and use in their app


// File: readme.dart // Always generate this file
in this file tell how to use the app 

// Add a blank line to separate from dependencies

// Dependencies: [new_dependency1, new_dependency2] // List only NEW dependencies in one line, always include device_preview if added, exclude flutter_service, flutter_lints

Ensure the following:
- Produce responsive, modern, production-ready code with no bugs or errors.
- Use network images from $exampleImage for dummy data; avoid local assets unless necessary (e.g., product images).
- Include all necessary imports in each file.
- Use dummy data for functionality, avoiding real backend APIs unless required (e.g., Google Maps).
- Set debugShowCheckedModeBanner: false in main.dart.
- Configure device_preview in main.dart (enabled: !kReleaseMode) if added.
- Ensure each file contains valid, non-empty Dart code.
- Use flame package for game-related updates if needed.

UI Consistency:
- Prefer vector icons or programmatic UI over image assets.
- Use cached_network_image and shimmer_effect for any image-related UI.
- Avoid lottie or rive animations.


Asset Handling:
- Use $exampleImage for network-based dummy data.
- If assets are required, document their usage and placement in _Explanation.dart and readme.dart.

Code Quality:
- Write concise, maintainable code following Dart style guidelines.
- Avoid runtime errors, null pointer exceptions, or unhandled edge cases.
- Include error handling for user inputs and async operations.
- Ensure updates are compatible with existing code, preserving functionality.
- Validate responsiveness across different screen sizes.

The updated code should reflect modern Flutter development practices, delivering a professional, engaging app with no hangs, crashes, or bugs, seamlessly integrated with the existing codebase.
''';

      final result = await _callGeminiApi(prompt, 'gemini-2.5-flash');
      final response = result['response'].toString();

      final newCodeJson = _parseGeneratedCode(response);

      // Merge with existing code instead of replacing
      final mergedCodeJson = await _mergeCodeWithExisting(newCodeJson);

      _lastCodeJson = mergedCodeJson;
      await _saveFilesFromJson(mergedCodeJson);
      await _updateDependenciesFromJson(mergedCodeJson);
      _explanation = mergedCodeJson['Instruction'] ?? 'Updated app code';
      return mergedCodeJson;
    } catch (e) {
      if (e
          .toString()
          .contains('type "Null" is not a subtype of type "String"')) {
        return await _mergeCodeWithExisting({
          'Code': [],
          'Dependencies': [],
          'Instruction': 'Updated app code',
          'status': 'success'
        });
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> solveCode(String error) async {
    if (_projectDir == null) throw Exception('No project selected');
    // final projectName = path.basename(_projectDir!);

    final currentCodeJson = await _getCurrentCodeJson();
    if (currentCodeJson['Code'] == null ||
        (currentCodeJson['Code'] as List).isEmpty) {
      throw Exception('No previous code found. Generate code first.');
    }

    try {
      final codeJsonString = jsonEncode(currentCodeJson);
      final prompt = '''
You are an expert Flutter developer specializing in games and advanced AI-driven apps, tasked with resolving the following error in this Flutter code: $error. The existing code is: $codeJsonString.

IMPORTANT: Only provide files that need updates to fix the specified error. Do not regenerate unchanged files unless they are directly related to resolving the error.

Provide the updated Dart code files in a single response, structured with comments indicating separate files, and list only new dependencies (if any) at the end in a structured format. Follow this example:

// File: main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Always include in main.dart
import 'home_page.dart'; 
void main() => runApp(const MyApp());
...

// File: home_page.dart 

// File: _Explanation.dart // Always generate this file with detailed content
// Explain:
// - Why the error occurred (e.g., missing import, null safety issue, logic error)
// - What changes were made to resolve it, including specific code modifications
// - How updated files integrate with existing code
// - Any new assets, APIs, or permissions required in AndroidManifest.xml (e.g., android.permission.INTERNET)
// - Keep explanations concise, technical, and relevant, avoiding unnecessary details


// File: _SupabaseHelper.dart (generate if required)
//in this file only generate sql code for supabase tables and row level security (RLS) policies and rules with no bs just code 
//which user can easily copy and paste in supabase dashboard and use in their app


// File: readme.dart // Always generate this file
in this file tell how to use the app 

// Add a blank line to separate from dependencies

// Dependencies: [new_dependency1, new_dependency2] // List only NEW dependencies in one line, always include device_preview if added, exclude flutter_service, flutter_lints

Ensure the following:
- Produce production-ready code with no bugs or new errors introduced.
- Use network images from $exampleImage for dummy data if needed; avoid local assets unless necessary (e.g., product images).
- Include all necessary imports in each file.
- Avoid real backend APIs unless required (e.g., Google Maps).
- Set debugShowCheckedModeBanner: false in main.dart.
- Configure device_preview in main.dart (enabled: !kReleaseMode) if added.
- Ensure each file contains valid, non-empty Dart code.
- Use flame package for game-related fixes if needed.

Asset Handling:
- Use $exampleImage for network-based dummy data if needed.
- Document any required assets in _Explanation.dart and readme.dart.

Code Quality:
- Write concise, maintainable code following Dart style guidelines.
- Fix the error without introducing new runtime errors, null pointer exceptions, or unhandled edge cases.
- Include error handling for user inputs and async operations if relevant.
- Ensure changes are compatible with existing code, preserving functionality.
- Validate responsiveness across different screen sizes if UI changes are made.

The updated code should resolve the error completely, reflect modern Flutter development practices, and deliver a professional, stable app with no hangs, crashes, or bugs.
''';
      final result = await _callGeminiApi(prompt, 'gemini-2.5-flash');
      final response = result['response'].toString();

      final newCodeJson = _parseGeneratedCode(response);

      // Merge with existing code instead of replacing
      final mergedCodeJson = await _mergeCodeWithExisting(newCodeJson);

      _lastCodeJson = mergedCodeJson;

      await _saveFilesFromJson(mergedCodeJson);
      await _updateDependenciesFromJson(mergedCodeJson);
      _explanation =
          mergedCodeJson['Instruction'] ?? 'Solved error in app code';
      return mergedCodeJson;
    } catch (e) {
      if (e
          .toString()
          .contains('type "Null" is not a subtype of type "String"')) {
        print('Handling null type cast error gracefully in solve');
        return await _mergeCodeWithExisting({
          'Code': [],
          'Dependencies': [],
          'Instruction': 'Solved error in app code',
          'status': 'success'
        });
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addSupabase(
      String anonKey, String anonUrl) async {
    if (_projectDir == null) throw Exception('No project selected');
    // final projectName = path.basename(_projectDir!);

    final currentCodeJson = await _getCurrentCodeJson();
    if (currentCodeJson['Code'] == null ||
        (currentCodeJson['Code'] as List).isEmpty) {
      throw Exception('No previous code found. Generate code first.');
    }

    try {
      final codeJsonString = jsonEncode(currentCodeJson);
      final prompt =
          ''' You are an expert Flutter developer specializing in games and advanced AI-driven apps, tasked with integrating Supabase into the following Flutter code: $codeJsonString. Use the provided Supabase credentials: anonKey: $anonKey, url: $anonUrl. Ensure the integration is full-stack, production-ready, and error-free.

IMPORTANT: Only provide new files required for Supabase integration and modify existing files that need changes to support the integration. Do not regenerate unchanged files unless directly related to Supabase functionality.

Provide the updated or new Dart code files in a single response, structured with comments indicating separate files, and list only new dependencies at the end in a structured format. Follow this example:

// File: main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Always include in main.dart
import 'home_page.dart';
void main() => runApp(const MyApp());
...

// File: _SupabaseHelper.dart // Always generate this file with required content
//in this file only generate sql code for supabase tables and row level security (RLS) policies and rules with no bs just code 
//which user can easily copy and paste in supabase dashboard and use in their app

// File: _Explanation.dart // Always generate this file with detailed content
// Explain:
// - How Supabase is integrated (e.g., initialization, authentication, database operations)
// - Purpose of new or modified files and their interaction with existing code
// - State management updates (if any) for Supabase data
// - UI changes (if any) to support Supabase features
// - Required AndroidManifest.xml permissions (e.g., android.permission.INTERNET)
// - Asset usage (if any), specifying placement
// Keep explanations concise, relevant, and technical


// File: readme.dart // Always generate this file
in this file tell how to use the app 

// Add a blank line to separate from dependencies

// Dependencies: [supabase_flutter, device_preview] // List only NEW dependencies in one line, always include device_preview if added, exclude flutter_service, flutter_lints

Ensure the following:
- Include all necessary imports in each file.
- Initialize Supabase with the provided $anonKey and $anonUrl, ensuring secure configuration.
- Implement at least basic authentication (e.g., email/password) and database operations (e.g., CRUD).
- Set debugShowCheckedModeBanner: false in main.dart.
- Ensure each file contains valid, non-empty Dart code.

Supabase Integration Requirements:
- Initialize Supabase in main.dart or a dedicated service file.
- Implement authentication (e.g., sign-up, sign-in, sign-out) with error handling.
- Provide database operations (e.g., read/write) for at least one table relevant to the app's functionality.
- Use row-level security (RLS) in _SupabaseHelper.dart to ensure data security.
- Handle Supabase errors gracefully with user-friendly feedback (e.g., toast messages).

UI Consistency:
- Maintain the existing UI's style, enhancing only if necessary for Supabase features (e.g., login screen).
- Use modern design elements (e.g., gradients, shadows, animations) for new UI components.
- Use icons from material_icons, cupertino_icons, or font_awesome_flutter.
- Prefer vector icons or programmatic UI over image assets.
- Use cached_network_image and shimmer_effect for any image-related UI.
- Avoid lottie or rive animations.


State Management and Architecture:
- Maintain clean architecture with separate layers for UI, logic, and data.
- Ensure modular, reusable widgets with clear separation of concerns.


Code Quality:
- Write concise, maintainable code following Dart style guidelines.
- Avoid runtime errors, null pointer exceptions, or unhandled edge cases.
- Include error handling for Supabase operations (e.g., authentication failures, network issues).
- Ensure changes are compatible with existing code, preserving functionality.
- Validate responsiveness across different screen sizes if UI changes are made.

The updated code should fully integrate Supabase, reflect modern Flutter development practices, and deliver a professional, stable app with no hangs, crashes, or bugs.
''';
      final result = await _callGeminiApi(prompt, 'gemini-2.5-flash');
      final response = result['response'].toString();

      final newCodeJson = _parseGeneratedCode(response);

      // Merge with existing code instead of replacing
      final mergedCodeJson = await _mergeCodeWithExisting(newCodeJson);

      _lastCodeJson = mergedCodeJson;

      await _saveFilesFromJson(mergedCodeJson);
      await _updateDependenciesFromJson(mergedCodeJson);
      _explanation =
          mergedCodeJson['Instruction'] ?? 'Added Supabase backend to app';
      return mergedCodeJson;
    } catch (e) {
      if (e
          .toString()
          .contains('type "Null" is not a subtype of type "String"')) {
        print('Handling null type cast error gracefully in addSupabase');
        return await _mergeCodeWithExisting({
          'Code': [],
          'Dependencies': [],
          'Instruction': 'Added Supabase backend to app',
          'status': 'success'
        });
      }
      rethrow;
    }
  }

  Map<String, dynamic> _parseGeneratedCode(String response) {
    try {
      response = response.replaceAll(RegExp(r'```dart|```'), '').trim();

      // First try to find dependencies in the standard format
      var depsMatch = RegExp(
        r'(?:^|\n)\s*// Dependencies:\s*\[([\s\S]*?)\]',
        multiLine: true,
      ).firstMatch(response);

      // If not found, try to find it in readme.dart content
      if (depsMatch == null) {
        final readmeMatch = RegExp(
          r'// File: readme\.dart[\s\S]*?//Dependencies:\s*\[([\s\S]*?)\]',
          multiLine: true,
        ).firstMatch(response);

        if (readmeMatch != null) {
          depsMatch = readmeMatch;
        }
      }

      print('Raw dependencies section: ${depsMatch?.group(1)}');

      final dependencies = depsMatch != null
          ? depsMatch
              .group(1)!
              .split(',')
              .map((dep) => dep.trim())
              .where((dep) => dep.isNotEmpty)
              .toList()
          : [];

      print('Parsed dependencies: $dependencies');

      // Remove the dependencies section from the response before processing files
      String codePart = response;
      if (depsMatch != null) {
        codePart = response.substring(0, depsMatch.start) +
            response.substring(depsMatch.end);
      }

      final codeList = <Map<String, String>>[];

      // Split by file sections, handling both formats
      final fileSections = codePart.split(RegExp(r'// File:|//File:'));
      for (var section in fileSections) {
        if (section.trim().isEmpty) continue;

        // Find the first newline or end of string
        final firstNewline = section.indexOf('\n');
        if (firstNewline == -1) continue;

        final filename = section.substring(0, firstNewline).trim();
        String code = section.substring(firstNewline + 1).trim();

        // Special handling for readme.dart
        if (filename.toLowerCase() == 'readme.dart') {
          // Remove any trailing dependencies section from readme content
          final depsIndex = code.lastIndexOf('//Dependencies:');
          if (depsIndex != -1) {
            code = code.substring(0, depsIndex).trim();
          }
        }

        if (code.isNotEmpty) {
          if (filename.contains('/')) {
            print(
                'Warning: Invalid filename $filename with folder path. Using ${path.basename(filename)}');
            codeList.add({'filename': path.basename(filename), 'code': code});
          } else {
            codeList.add({'filename': filename, 'code': code});
          }
        } else {
          print('Warning: Empty code for file $filename, skipping');
        }
      }

      if (codeList.isEmpty ||
          codeList.every((file) => file['code']!.trim().isEmpty)) {
        print('Error: No valid code found, adding default main.dart');
        codeList.clear();
        codeList.add({
          'filename': 'main.dart',
          'code': '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(child: Text('Generated Flutter App')),
      ),
    );
  }
}
'''
        });
      }

      for (var file in codeList) {
        print(
            'Parsed file: ${file['filename']} with ${file['code']?.split('\n').length ?? 0} lines');
      }

      return {
        'Code': codeList,
        'Dependencies': dependencies,
        'Instruction': 'Parsed from single API response',
      };
    } catch (e) {
      print('Error parsing generated code: $e');
      return {
        'Code': [
          {
            'filename': 'main.dart',
            'code': '''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(child: Text('Error: Failed to parse code')),
      ),
    );
  }
}
'''
          }
        ],
        'Dependencies': [],
        'Instruction': 'Error parsing response: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> _reconstructCodeJsonFromFiles() async {
    if (_projectDir == null) return null;
    try {
      final libDir = _fs.directory(path.join(_projectDir!, 'lib'));
      if (!await libDir.exists()) return null;

      final List<Map<String, String>> files = [];
      await for (final entity in libDir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final filename = path.basename(entity.path);
          final code = await entity.readAsString();
          files.add({'filename': filename, 'code': code});
        }
      }

      if (files.isEmpty) return null;

      final pubspecFile = _fs.file(path.join(_projectDir!, 'pubspec.yaml'));
      final List<String> dependencies = [];
      if (await pubspecFile.exists()) {
        final pubspecContent = await pubspecFile.readAsString();
        final dependenciesMatch =
            RegExp(r'dependencies:[\s\S]*?(?=\n\w+:|$)', dotAll: true)
                .firstMatch(pubspecContent);
        if (dependenciesMatch != null) {
          final lines = dependenciesMatch.group(0)!.split('\n');
          for (final line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.isNotEmpty &&
                !trimmedLine.startsWith('dependencies:') &&
                trimmedLine.contains(':')) {
              dependencies.add(trimmedLine);
            }
          }
        }
      }

      return {
        'Code': files,
        'Dependencies': dependencies,
        'Instruction': 'Reconstructed from existing files'
      };
    } catch (e) {
      print('Error reconstructing code JSON: $e');
      return null;
    }
  }

  Future<void> _saveFilesFromJson(Map<String, dynamic> codeJson) async {
    if (_projectDir == null) throw Exception('No project selected');
    final filesList = codeJson['Code'];
    if (filesList == null || filesList is! List) {
      throw Exception('Invalid code JSON format: missing or invalid Code list');
    }
    final libDir = _fs.directory(path.join(_projectDir!, 'lib'));
    if (!await libDir.exists()) {
      await libDir.create(recursive: true);
    }
    for (final fileEntry in filesList) {
      if (fileEntry is Map) {
        String? filename = fileEntry['filename']?.toString();
        String? code = fileEntry['code']?.toString();
        if (filename != null && code != null && code.trim().isNotEmpty) {
          if (!filename.endsWith('.dart')) {
            filename = '$filename.dart';
          }
          filename = path.basename(filename);
          final file = _fs.file(path.join(libDir.path, filename));
          try {
            await file.writeAsString(code);
            print('Saved file: ${file.path} with ${code.length} characters');
          } catch (e) {
            print('Error saving file ${file.path}: $e');
          }
        } else {
          print('Skipping file $filename: empty or invalid code');
        }
      }
    }
  }

  Future<void> _updateDependenciesFromJson(
      Map<String, dynamic> codeJson) async {
    if (_projectDir == null) throw Exception('No project selected');

    final dependenciesList = codeJson['Dependencies'];
    final List<String> dependencies = (dependenciesList is List)
        ? dependenciesList
            .map((dep) => dep.toString().trim())
            .where((dep) => dep.isNotEmpty)
            .toList()
        : [];

    print('Processing dependencies: $dependencies');

    final pubspecFile = _fs.file(path.join(_projectDir!, 'pubspec.yaml'));
    String pubspecContent = await pubspecFile.exists()
        ? await pubspecFile.readAsString()
        : '''
name: flutter_app
description: A new Flutter project.
publish_to: 'none'
version: 1.0.0+1
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true
''';

    final existingDependencies = <String>{};
    final dependenciesMatch =
        RegExp(r'dependencies:[\s\S]*?(?=\n\w+:|$)', dotAll: true)
            .firstMatch(pubspecContent);

    if (dependenciesMatch != null) {
      final lines = dependenciesMatch.group(0)!.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty &&
            !trimmedLine.startsWith('dependencies:') &&
            trimmedLine.contains(':')) {
          existingDependencies.add(trimmedLine.split(':').first.trim());
        }
      }
    }

    bool pubspecUpdated = false;
    final newDependencies = <String>[];

    for (final dep in dependencies) {
      final packageName = dep.trim();
      if (!existingDependencies.contains(packageName)) {
        newDependencies.add('  $packageName:');
        existingDependencies.add(packageName);
        print('Adding new dependency: $packageName');
      }
    }

    if (newDependencies.isNotEmpty) {
      final depsSection =
          RegExp(r'dependencies:[\s\S]*?(?=\n\w+:|$)', dotAll: true)
              .firstMatch(pubspecContent);
      if (depsSection != null) {
        final updatedDeps =
            '${depsSection.group(0)!}\n${newDependencies.join('\n')}';
        pubspecContent =
            pubspecContent.replaceFirst(depsSection.group(0)!, updatedDeps);
      } else {
        pubspecContent +=
            '\ndependencies:\n  flutter:\n    sdk: flutter\n${newDependencies.join('\n')}';
      }
      pubspecUpdated = true;
    }

    if (pubspecUpdated) {
      await pubspecFile.writeAsString(pubspecContent);
      print(
          'Updated pubspec.yaml with new dependencies: ${newDependencies.join(', ')}');
      final shell = Shell(workingDirectory: _projectDir);
      try {
        await shell.run('flutter pub get');
        print('Successfully ran flutter pub get');
      } catch (e) {
        print('Error running flutter pub get: $e');
      }
    } else {
      print('No new dependencies to add');
    }
  }

  Future<Map<String, dynamic>> _callGeminiApi(
      String prompt, String model) async {
    try {
      await _ensureApiKeyLoaded();
      if (apiKey.isEmpty) {
        throw Exception('MISSING_API_KEY');
      }
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {'temperature': 1.0},
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];

        final usage = data['usageMetadata'];
        final inputTokenCount = usage['promptTokenCount'] as int;
        final outputTokenCount = usage['candidatesTokenCount'] as int;
        final totalTokenCount = usage['totalTokenCount'] as int;
        // Clean up the response text
        text = text.replaceAll(
            '\\n', '\n'); // First convert literal \n to actual newlines
        text = text.replaceAll(RegExp(r'\n{2,}'),
            '\n'); // Replace multiple newlines with single newline
        text = text.trim(); // Remove leading/trailing whitespace

        print('Response from Gemini: $text');
        print('Input Token: $inputTokenCount');
        print('Output Token: $outputTokenCount');
        print('Total Token: $totalTokenCount');
        final responseFile =
            _fs.file(path.join(_projectDir!, 'api_response.txt'));
        await responseFile.writeAsString(text);
        return {'response': text};
      }
      throw Exception('API request failed: ${response.body}');
    } catch (e) {
      print('API Error: $e');
      throw Exception('Failed to generate code: $e');
    }
  }

  Future<List<String>> listProjectFiles() async {
    if (_projectDir == null) throw Exception('No project selected');
    final libDir = _fs.directory(path.join(_projectDir!, 'lib'));
    if (!await libDir.exists()) return [];
    final files = <String>[];
    await for (final entity in libDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(path.basename(entity.path));
      }
    }
    return files;
  }

  Future<String> getFileContent(String filename) async {
    if (_projectDir == null) throw Exception('No project selected');
    final file = _fs.file(path.join(_projectDir!, 'lib', filename));
    if (!await file.exists()) throw Exception('File not found: $filename');
    return await file.readAsString();
  }

  /// Exports all project code and dependencies in the required format for export.
  Future<String> exportProjectCodeFormatted() async {
    if (_projectDir == null) throw Exception('No project selected');
    final codeJson = await _getCurrentCodeJson();
    final codeList = codeJson['Code'] as List<dynamic>? ?? [];
    final dependencies = codeJson['Dependencies'] as List<dynamic>? ?? [];

    final buffer = StringBuffer();
    for (final file in codeList) {
      final filename = file['filename'] ?? '';
      final code = file['code'] ?? '';
      buffer.writeln('//File: $filename');
      buffer.writeln(code);
      buffer.writeln();
    }
    // Add dependencies in the required format
    buffer.writeln('//Dependencies: [${dependencies.join(',')}]');
    return buffer.toString();
  }
}
