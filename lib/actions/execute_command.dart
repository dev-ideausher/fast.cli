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

import 'package:fast/core/action.dart';
import 'package:fast/core/fast_process.dart';
import 'package:fast/yaml_manager.dart';
import 'package:path/path.dart';

class ExecuteCommandsAction implements Action {
  final String scaffoldFilePath;
  final Directory workingDirectory;
  final String appName;

  ExecuteCommandsAction(
      this.workingDirectory, this.scaffoldFilePath, this.appName);

  @override
  Future<void> execute() async {
    Directory appDirectory =
        Directory(normalize('${workingDirectory.path}/$appName'));
    final yamlCommands =
        YamlManager.readerYamlCommandsFile(normalize(scaffoldFilePath));

    for (var yamlCommand in yamlCommands) {
      for (var envCmd in yamlCommand.command.trim().split(' ** ')) {
        // env splitter
        final splited = envCmd.split(' ');
        final name = splited[0];
        final splited2 =
            envCmd.replaceFirst(name, '').trim().split(' && '); // cmd splitter
        for (var cmd in splited2) {
          final cmdList = cmd.split(' ');
          print('Running $name ${cmdList.join(' ')}');
          await FastProcess().executeProcess(name, cmdList, appDirectory.path);
        }
      }
    }
  }

  @override
  String get succesMessage => 'Run command.';
}

// flutter pub add velocity_x && pub add get
