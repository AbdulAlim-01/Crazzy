import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';

class ProjectService {
  Future<String> getProjectsDir() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}\\crazzy_dev\\projects';
  }

  Future<List<String>> getExistingProjects() async {
    final projectsDir = await getProjectsDir();
    try {
      final dir = Directory(projectsDir);
      await dir.create(recursive: true);

      // Get all directories and their creation times
      final List<MapEntry<String, DateTime>> projectsWithDates = [];
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final stat = await entity.stat();
          projectsWithDates.add(MapEntry(
              entity.path.split(Platform.pathSeparator).last, stat.changed));
        }
      }

      // Sort by creation date (newest first)
      projectsWithDates.sort((a, b) => b.value.compareTo(a.value));

      // Extract just the project names in sorted order
      return projectsWithDates.map((entry) => entry.key).toList();
    } catch (e) {
      print('Error fetching projects: $e');
      return [];
    }
  }

  Future<void> createProject(String projectName) async {
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(projectName)) {
      throw Exception(
          'Invalid project name (use letters, numbers, underscores only)');
    }
    final projectsDir = await getProjectsDir();
    final projectDir = '$projectsDir/$projectName';
    if (await Directory(projectDir).exists()) {
      throw Exception('Project already exists');
    }
    try {
      final shell = Shell(workingDirectory: projectsDir);
      await shell.run(
        'flutter create $projectName',
      );
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  Future<void> deleteProject(String projectName) async {
    final projectsDir = await getProjectsDir();
    final projectDir = '$projectsDir/$projectName';
    if (!await Directory(projectDir).exists()) {
      throw Exception('Project does not exist');
    }
    try {
      await Directory(projectDir).delete(recursive: true);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }
}
