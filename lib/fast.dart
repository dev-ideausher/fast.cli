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

library fast;

import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:fast/config_storage.dart';
import 'package:fast/core/exceptions.dart';
import 'package:fast/core/progress.dart';
import 'package:fast/logger.dart';
import 'package:fast/services/config_service.dart';
import 'package:fast/yaml_manager.dart';
import 'commands/flutter/create_command.dart';
import 'commands/flutter/create_template.dart';
import 'commands/flutter/run_command.dart';
import 'commands/flutter/setup_command.dart';
import 'commands/flutter/snippets_command.dart';

/// Main CLI orchestrator for Fast CLI.
/// 
/// Manages command registration, plugin loading, and command execution.
/// This is the central entry point for all CLI operations.
class FastCLI {
  final PluginStorage pluginStorage;
  final CommandRunner commandRunner;
  final ConfigService configService;

  /// Creates a new FastCLI instance.
  /// 
  /// [commandRunner] - The command runner for managing commands.
  /// [pluginStorage] - Storage service for plugin management.
  /// [configService] - Optional configuration service. Defaults to singleton.
  FastCLI(
    this.commandRunner,
    this.pluginStorage, [
    ConfigService? configService,
  ]) : configService = configService ?? ConfigService();

  /// Sets up the command runner with commands from a plugin.
  /// 
  /// Loads templates, scaffolds, and other commands from the specified plugin.
  /// 
  /// [pluginName] - The name of the plugin to load.
  /// 
  /// Throws [PluginException] if the plugin cannot be found or loaded.
  Future<void> setupCommandRunner(String pluginName) async {
    try {
      final plugin = await pluginStorage.readByName(pluginName);
      final pluginPath = plugin.path;

      // Validate plugin path exists
      final pluginDir = Directory(pluginPath);
      if (!await pluginDir.exists()) {
        throw PluginException(
          'Plugin directory does not exist: $pluginPath',
        );
      }

      // Load templates
      await withProgress(
        'Loading templates from plugin: $pluginName',
        () async {
          final pathTemplates = '$pluginPath/templates';
          final templatesPathExists = await Directory(pathTemplates).exists();

          if (templatesPathExists) {
            final templates = YamlManager.loadTemplates(pathTemplates);

            for (final template in templates) {
              addCommand(CreateTemplateCommand(template: template));
            }
          }
        },
      );

      // Load scaffold commands
      await withProgress(
        'Loading scaffold commands from plugin: $pluginName',
        () async {
          final scaffoldsPath = '${plugin.path}/scaffolds';

          addCommand(SnippetsCommand('${plugin.path}/templates', plugin));
          addCommand(RunCommand('${plugin.path}'));
          addCommand(CreateCommand(scaffoldsPath));
          addCommand(SetupCommand(scaffoldsPath));
        },
      );

      logger.d('Plugin "$pluginName" loaded successfully.');
    } on PluginException {
      rethrow;
    } catch (error) {
      if (error is UsageException || error is FastException) {
        logger.e(error.toString());
        exit(64);
      }
      
      throw PluginException(
        'Failed to load plugin: $pluginName',
        error,
      );
    }
  }

  /// Runs the CLI with the given arguments.
  /// 
  /// [arguments] - Command line arguments.
  /// [loadPlugin] - Whether to load a plugin before executing commands.
  /// 
  /// Returns the exit code (0 for success, non-zero for errors).
  Future<int> run(List<String> arguments, bool loadPlugin) async {
    List<String> finalArguments;
    if (loadPlugin) {
      if (arguments.length < 2) {
        logger.e('Plugin name required when using load_plugin');
        return 64;
      }
      final lastIndex = arguments.length;
      finalArguments = arguments.getRange(2, lastIndex).toList();
    } else {
      finalArguments = arguments;
    }

    try {
      await commandRunner.run(finalArguments);
      return 0;
    } on UsageException catch (error) {
      logger.e(error.toString());
      return 64;
    } on FastException catch (error) {
      logger.e(error.toString());
      return 1;
    } catch (error) {
      logger.e('''An unknown error occurred. 
Please report by creating an issue at https://github.com/dev-ideausher/fast.cli.
Error: $error''');
      
      if (configService.isDebug()) {
        logger.e(error.toString());
      }
      
      return 1;
    }
  }

  /// Adds multiple commands to the command runner.
  /// 
  /// [commands] - List of commands to add.
  void addCommands(List<Command> commands) {
    for (final command in commands) {
      commandRunner.addCommand(command);
    }
  }

  /// Adds a single command to the command runner.
  /// 
  /// [command] - Command to add.
  void addCommand(Command command) {
    commandRunner.addCommand(command);
  }
}
