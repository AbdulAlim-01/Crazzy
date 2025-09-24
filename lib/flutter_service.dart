// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';

class FlutterService {
  String? _projectDir;

  /// Sets the project directory based on the provided project name.
  Future<void> setProjectDir(String projectName) async {
    if (projectName.isEmpty) {
      throw Exception('Project name cannot be empty');
    }
    final baseDir = await getApplicationDocumentsDirectory();
    _projectDir =
        '${baseDir.path}${Platform.pathSeparator}crazzy_dev${Platform.pathSeparator}projects${Platform.pathSeparator}$projectName';
  }

  /// Validates that a project directory is set and exists.
  Future<void> _ensureFlutterProject() async {
    if (_projectDir == null) {
      throw Exception('No project selected');
    }
    final projectDir = Directory(_projectDir!);
    if (!await projectDir.exists()) {
      throw Exception('Project directory does not exist: $_projectDir');
    }
    final pubspecFile =
        File('$_projectDir${Platform.pathSeparator}pubspec.yaml');
    if (!await pubspecFile.exists()) {
      throw Exception('Not a valid Flutter project: pubspec.yaml not found');
    }
  }

  /// Retrieves a list of available devices for running the Flutter app.
  Future<List<String>> getAvailableDevices() async {
    final shell = Shell();
    try {
      final result = await shell.run('flutter devices');
      final lines = result.outText.split('\n');
      return lines
          .where((line) => line.contains('•'))
          .map((line) => line.split('•')[1].trim().split(' ')[0])
          .toList();
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to list devices');
    }
  }

  /// Runs the Flutter app on an available device or web.
  Future<String> runApp() async {
    await _ensureFlutterProject();
    final devices = await getAvailableDevices();
    final shell = Shell(workingDirectory: _projectDir);
    try {
      if (devices.isNotEmpty) {
        final results = await shell.run('flutter run -d ${devices[0]}');
        final output = _formatShellOutput(results);
        return '$output\nApp running on ${devices[0]}';
      } else {
        final results = await shell.run('flutter run -d chrome');
        final output = _formatShellOutput(results);
        return '$output\nApp running on web';
      }
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to run app');
    }
  }

  /// Runs the Flutter app on a specific device.
  Future<String> runAppOnDevice(String deviceId) async {
    await _ensureFlutterProject();
    final shell = Shell(workingDirectory: _projectDir);
    try {
      final results = await shell.run('flutter run -d $deviceId');
      final output = _formatShellOutput(results);
      return '$output\nApp running on $deviceId';
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to run app on device');
    }
  }

  /// Runs the Flutter app on web.
  Future<String> runAppOnWeb() async {
    await _ensureFlutterProject();
    final shell = Shell(workingDirectory: _projectDir);
    try {
      final results = await shell.run('flutter run -d chrome');
      final output = _formatShellOutput(results);
      return '$output\nApp running on web';
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to run app on web');
    }
  }

  /// Reloads the running Flutter app.
  Future<String> reloadApp() async {
    await _ensureFlutterProject();
    final shell = Shell(workingDirectory: _projectDir);
    try {
      final results = await shell.run('r');
      final output = _formatShellOutput(results);
      return '$output\nApp reloaded';
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to reload app');
    }
  }

  /// Builds the Flutter app for the specified target (apk, web, or appbundle).
  Future<String> buildApp(String target) async {
    await _ensureFlutterProject();
    String command;
    String buildPath;
    switch (target.toLowerCase()) {
      case 'apk':
        command = 'flutter build apk --release';
        buildPath =
            'build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}apk${Platform.pathSeparator}release${Platform.pathSeparator}app-release.apk';
        break;
      case 'web':
        command = 'flutter build web --release';
        buildPath = 'build${Platform.pathSeparator}web';
        break;
      case 'appbundle':
        command = 'flutter build appbundle --release';
        buildPath =
            'build${Platform.pathSeparator}app${Platform.pathSeparator}outputs${Platform.pathSeparator}bundle${Platform.pathSeparator}release${Platform.pathSeparator}app-release.aab';
        break;
      default:
        throw Exception('Invalid build target: $target');
    }
    final shell = Shell(workingDirectory: _projectDir);
    try {
      final results = await shell.run(command);
      final output = _formatShellOutput(results);
      return '$output\nApp built successfully for $target at $_projectDir${Platform.pathSeparator}$buildPath';
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Build failed');
    }
  }



  

  /// Checks if Flutter is installed on the system.
  Future<bool> isFlutterInstalled() async {
    final shell = Shell();
    try {
      final results = await shell.run('flutter --version');
      return results.isNotEmpty && results[0].exitCode == 0;
    } on ShellException {
      return false;
    }
  }

  /// Runs the Flutter app on Windows.
  Future<String> runAppOnWindows() async {
    await _ensureFlutterProject();
    final shell = Shell(workingDirectory: _projectDir);
    try {
      final results = await shell.run('flutter run -d windows');
      final output = _formatShellOutput(results);
      return '$output\nApp running on Windows';
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to run app on Windows');
    }
  }

  /// Runs the Flutter app on Microsoft Edge.
  Future<String> runAppOnEdge() async {
    await _ensureFlutterProject();
    final shell = Shell(workingDirectory: _projectDir);
    try {
      final results = await shell.run('flutter run -d edge');
      final output = _formatShellOutput(results);
      return '$output\nApp running on Edge';
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to run app on Edge');
    }
  }

  /// Runs the Flutter app on Google Chrome.
  Future<String> runAppOnChrome() async {
    await _ensureFlutterProject();
    final shell = Shell(workingDirectory: _projectDir);
    try {
      final results = await shell.run('flutter run -d chrome');
      final output = _formatShellOutput(results);
      return '$output\nApp running on Chrome';
    } on ShellException catch (e) {
      throw _formatShellException(e, 'Failed to run app on Chrome');
    }
  }

  /// Helper method to format shell command output.
  String _formatShellOutput(List<ProcessResult> results) {
    String output = '';
    for (var result in results) {
      output += 'Command: ${result.toString()}\n';
      if (result.stdout.isNotEmpty) {
        output += 'Stdout:\n${result.stdout}\n';
      }
      if (result.stderr.isNotEmpty) {
        output += 'Stderr:\n${result.stderr}\n';
      }
    }
    return output.trim();
  }

  /// Helper method to format shell exceptions with detailed error information.
  Exception _formatShellException(ShellException e, [String? prefix]) {
    final result = e.result;
    if (result != null) {
      return Exception('''
${prefix ?? 'Command failed'}:
Command: ${result.toString()}
Exit code: ${result.exitCode}
Stderr: ${result.stderr}
''');
    }
    return Exception('$prefix: ${e.message}');
  }
}
