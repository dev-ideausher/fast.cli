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
import 'package:args/command_runner.dart';
import 'package:fast/commands/flutter/install_package.dart';
import 'package:fast/commands/flutter/clear_command.dart';
import 'package:fast/commands/version_command.dart';
import 'package:fast/commands/plugin.dart';
import 'package:fast/config_storage.dart';
import 'package:fast/fast.dart';
import 'package:fast/logger.dart';

void main(List<String> arguments) async {
  // Support global --version/-v flag
  if (arguments.contains('--version') || arguments.contains('-v')) {
    stdout.writeln(FastVersion.versionString);
    exit(0);
  }
  final commandRunner = CommandRunner(
    'fast',
    'An incredible command line interface for Flutter.',
  );
  final pluginStorage = PluginStorage();
  final fastCLI = FastCLI(commandRunner, pluginStorage);
  
  final loadPlugin = arguments.isNotEmpty && arguments.first == 'load_plugin';

  try {
    if (loadPlugin) {
      if (arguments.length < 2) {
        logger.e('Error: Plugin name required when using load_plugin');
        exit(64);
      }
      final pluginName = arguments[1];
      await fastCLI.setupCommandRunner(pluginName);
    } else {
      fastCLI.addCommands([
        VersionCommand(),
        ClearCommand(),
        InstallPackageCommand(),
        PluginCommand(pluginStorage),
      ]);
    }

    final exitCode = await fastCLI.run(arguments, loadPlugin);
    exit(exitCode);
  } catch (e) {
    logger.e('Fatal error: $e');
    exit(1);
  }
}
