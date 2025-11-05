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

import 'dart:io';
import 'package:fast/config_storage.dart';
import 'package:fast/core/exceptions.dart';
import 'package:fast/core/result.dart';
import 'package:fast/yaml_manager.dart';

/// Service for validating plugin structure and configuration.
/// 
/// Ensures plugins have the required structure and files before loading.
class PluginValidator {
  /// Validates that a plugin has the required structure.
  /// 
  /// Checks for:
  /// - Plugin directory exists
  /// - Plugin YAML file exists (optional)
  /// - Templates directory structure (if exists)
  /// - Scaffolds directory structure (if exists)
  /// 
  /// Returns a Result with validation errors if any are found.
  static Future<Result<void>> validatePlugin(Plugin plugin) async {
    try {
      // Check if plugin path exists
      final pluginDir = Directory(plugin.path);
      if (!await pluginDir.exists()) {
        return Error(
          exception: PluginException('Plugin directory does not exist'),
          message: 'Plugin directory not found: ${plugin.path}',
        );
      }

      // Check for plugin.yaml (optional but recommended)
      final pluginYaml = File('${plugin.path}/plugin.yaml');
      if (await pluginYaml.exists()) {
        try {
          YamlManager.readerYamlPluginFile(pluginYaml.path);
        } catch (e) {
          return Error(
            exception: PluginException('Invalid plugin.yaml'),
            message: 'Failed to parse plugin.yaml: $e',
          );
        }
      }

      // Validate templates directory if it exists
      final templatesDir = Directory('${plugin.path}/templates');
      if (await templatesDir.exists()) {
        final validation = await _validateTemplatesDirectory(templatesDir);
        if (validation.isError) {
          return validation;
        }
      }

      // Validate scaffolds directory if it exists
      final scaffoldsDir = Directory('${plugin.path}/scaffolds');
      if (await scaffoldsDir.exists()) {
        final validation = await _validateScaffoldsDirectory(scaffoldsDir);
        if (validation.isError) {
          return validation;
        }
      }

      return const Success(null);
    } catch (e) {
      return Error.fromException(
        e,
        'Failed to validate plugin: ${plugin.name}',
      );
    }
  }

  /// Validates the templates directory structure.
  static Future<Result<void>> _validateTemplatesDirectory(
    Directory templatesDir,
  ) async {
    try {
      final entries = templatesDir.listSync();
      
      for (final entry in entries) {
        if (entry is Directory) {
          final templateYaml = File('${entry.path}/template.yaml');
          if (!await templateYaml.exists()) {
            return Error(
              exception: PluginException('Missing template.yaml'),
              message: 'Template directory missing template.yaml: ${entry.path}',
            );
          }

          // Try to load the template to validate it
          try {
            final templateReader = YamlTemplateReader(templateYaml.path);
            templateReader.reader();
          } catch (e) {
            return Error(
              exception: PluginException('Invalid template.yaml'),
              message: 'Failed to parse template.yaml at ${entry.path}: $e',
            );
          }
        }
      }

      return const Success(null);
    } catch (e) {
      return Error.fromException(e, 'Failed to validate templates directory');
    }
  }

  /// Validates the scaffolds directory structure.
  static Future<Result<void>> _validateScaffoldsDirectory(
    Directory scaffoldsDir,
  ) async {
    try {
      final entries = scaffoldsDir.listSync();
      
      for (final entry in entries) {
        if (entry is Directory) {
          final scaffoldYaml = File('${entry.path}/scaffold.yaml');
          if (!await scaffoldYaml.exists()) {
            return Error(
              exception: PluginException('Missing scaffold.yaml'),
              message: 'Scaffold directory missing scaffold.yaml: ${entry.path}',
            );
          }

          // Try to load the scaffold to validate it
          try {
            YamlManager.readerYamlScaffoldFile(scaffoldYaml.path);
          } catch (e) {
            return Error(
              exception: PluginException('Invalid scaffold.yaml'),
              message: 'Failed to parse scaffold.yaml at ${entry.path}: $e',
            );
          }
        }
      }

      return const Success(null);
    } catch (e) {
      return Error.fromException(e, 'Failed to validate scaffolds directory');
    }
  }

  /// Validates plugin name format.
  /// 
  /// Plugin names should be alphanumeric with underscores and hyphens.
  static Result<void> validatePluginName(String name) {
    if (name.isEmpty) {
      return Error(
        exception: ValidationException('Plugin name cannot be empty'),
        message: 'Plugin name cannot be empty',
      );
    }

    final nameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!nameRegex.hasMatch(name)) {
      return Error(
        exception: ValidationException('Invalid plugin name format'),
        message: 'Plugin name can only contain letters, numbers, underscores, and hyphens',
      );
    }

    return const Success(null);
  }

  /// Validates plugin Git URL format.
  static Result<void> validateGitUrl(String url) {
    if (url.isEmpty) {
      return Error(
        exception: ValidationException('Git URL cannot be empty'),
        message: 'Git URL cannot be empty',
      );
    }

    // Basic URL validation
    final gitUrlRegex = RegExp(
      r'^(https?://|git@)[\w\.-]+(:\d+)?(/[\w\.-]+)*\.git$|^[\w\.-]+/[\w\.-]+$',
    );
    if (!gitUrlRegex.hasMatch(url)) {
      return Error(
        exception: ValidationException('Invalid Git URL format'),
        message: 'Git URL format is invalid',
      );
    }

    return const Success(null);
  }
}

