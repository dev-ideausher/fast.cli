//Copyright 2020 Pedro Bissonho
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

import 'dart:convert';
import 'dart:io';
import 'package:fast/core/exceptions.dart';
import 'package:fast/core/result.dart';
import 'package:fast/services/config_service.dart';

/// Repository for managing plugin data serialization/deserialization.
class PluginRepository {
  /// Parses plugins from JSON data.
  List<Plugin> getAll(Map<String, dynamic> json) {
    final plugins = <Plugin>[];
    if (json['plugins'] != null) {
      json['plugins'].forEach((v) {
        plugins.add(Plugin.fromJson(v));
      });
    }
    return plugins;
  }

  /// Converts plugins to JSON storage format.
  Map<String, dynamic> toStorage(List<Plugin> models) {
    final data = <String, dynamic>{};
    data['plugins'] = models.map((v) => v.toJson()).toList();
    return data;
  }
}

/// Represents a plugin configuration.
/// 
/// A plugin can be loaded from a local path or a Git repository.
class Plugin {
  final String name;
  final String path;
  final String git;

  Plugin({
    required this.name,
    required this.path,
    this.git = '',
  });

  /// Returns true if this plugin is loaded from a Git repository.
  bool get isGit => git.isNotEmpty;

  /// Creates a Plugin from JSON data.
  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      git: json['git'] ?? '',
    );
  }

  /// Converts the plugin to JSON format.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'git': git,
    };
  }

  /// Creates a copy of this plugin with updated fields.
  Plugin copyWith({
    String? name,
    String? path,
    String? git,
  }) {
    return Plugin(
      name: name ?? this.name,
      path: path ?? this.path,
      git: git ?? this.git,
    );
  }

  @override
  String toString() => 'Plugin(name: $name, path: $path, git: ${git.isNotEmpty ? git : 'local'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plugin &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Manages plugin storage and persistence.
/// 
/// Provides methods for adding, removing, and querying plugins.
/// Uses ConfigService for path management.
class PluginStorage {
  final ConfigService _configService;
  late final String _filePath;

  /// Creates a new PluginStorage instance.
  /// 
  /// [filePath] - Optional custom file path. Defaults to config directory.
  /// [configService] - Optional config service. Defaults to singleton.
  PluginStorage([String? filePath, ConfigService? configService])
      : _configService = configService ?? ConfigService() {
    _filePath = filePath ?? _configService.getPluginsConfigPath();
  }

  /// Reads a plugin by name.
  /// 
  /// Throws [PluginException] if the plugin is not found.
  Future<Plugin> readByName(String name) async {
    final plugins = await read();
    try {
      return plugins.firstWhere((element) => element.name == name);
    } catch (e) {
      throw PluginException('Plugin not found: $name');
    }
  }

  /// Reads all plugins from storage.
  /// 
  /// Returns an empty list if the storage file doesn't exist or is empty.
  Future<List<Plugin>> read() async {
    final file = File(_filePath);
    if (!await file.exists()) {
      return <Plugin>[];
    }

    try {
      final fileContents = await file.readAsString();
      if (fileContents.trim().isEmpty) {
        return <Plugin>[];
      }

      final data = json.decode(fileContents) as Map<String, dynamic>;
      return PluginRepository().getAll(data);
    } catch (e) {
      throw PluginException(
        'Failed to read plugins from storage: $e',
      );
    }
  }

  /// Writes plugins to storage.
  /// 
  /// Creates the directory structure if it doesn't exist.
  Future<void> write(List<Plugin> plugins) async {
    try {
      // Ensure config directory exists
      final configResult = await _configService.ensureConfigDir();
      if (configResult.isError) {
        final error = configResult as Error<void>;
        throw PluginException(
          'Failed to create config directory: ${error.message}',
          error.exception,
        );
      }

      final file = File(_filePath);
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final data = PluginRepository().toStorage(plugins);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    } catch (e) {
      if (e is PluginException) rethrow;
      throw PluginException('Failed to write plugins to storage: $e');
    }
  }

  /// Adds or updates a plugin in storage.
  /// 
  /// If a plugin with the same name exists, it will be replaced.
  Future<void> add(Plugin plugin) async {
    final plugins = await read();
    plugins.removeWhere((element) => element.name == plugin.name);
    plugins.add(plugin);
    await write(plugins);
  }

  /// Removes a plugin from storage by name.
  /// 
  /// Returns true if the plugin was removed, false if it didn't exist.
  Future<bool> remove(String name) async {
    final plugins = await read();
    final initialCount = plugins.length;
    plugins.removeWhere((element) => element.name == name);
    
    if (plugins.length < initialCount) {
      await write(plugins);
      return true;
    }
    return false;
  }

  /// Checks if a plugin exists.
  Future<bool> exists(String name) async {
    final plugins = await read();
    return plugins.any((plugin) => plugin.name == name);
  }

  /// Gets the count of stored plugins.
  Future<int> count() async {
    final plugins = await read();
    return plugins.length;
  }
}
