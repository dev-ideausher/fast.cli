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

import 'package:args/command_runner.dart';

/// Registry for managing command registration and discovery.
/// 
/// Provides a centralized way to register and query available commands.
class CommandRegistry {
  final Map<String, Command> _commands = {};
  final Map<String, List<Command>> _commandGroups = {};

  /// Registers a command with the registry.
  /// 
  /// [command] - The command to register.
  /// 
  /// Throws [ArgumentError] if a command with the same name already exists.
  void register(Command command) {
    if (_commands.containsKey(command.name)) {
      throw ArgumentError(
        'Command with name "${command.name}" is already registered',
      );
    }
    _commands[command.name] = command;
  }

  /// Registers multiple commands.
  void registerAll(List<Command> commands) {
    for (final command in commands) {
      register(command);
    }
  }

  /// Registers a command under a group.
  /// 
  /// Commands in groups can be organized and listed together.
  void registerInGroup(String groupName, Command command) {
    register(command);
    _commandGroups.putIfAbsent(groupName, () => []).add(command);
  }

  /// Gets a command by name.
  /// 
  /// Returns null if the command is not found.
  Command? get(String name) {
    return _commands[name];
  }

  /// Gets all registered commands.
  List<Command> getAll() {
    return _commands.values.toList();
  }

  /// Gets all commands in a group.
  List<Command> getGroup(String groupName) {
    return _commandGroups[groupName] ?? [];
  }

  /// Gets all group names.
  List<String> getGroups() {
    return _commandGroups.keys.toList();
  }

  /// Checks if a command is registered.
  bool has(String name) {
    return _commands.containsKey(name);
  }

  /// Unregisters a command.
  /// 
  /// Returns true if the command was removed, false if it didn't exist.
  bool unregister(String name) {
    final command = _commands.remove(name);
    if (command != null) {
      // Remove from groups
      for (final group in _commandGroups.values) {
        group.removeWhere((cmd) => cmd.name == name);
      }
      return true;
    }
    return false;
  }

  /// Clears all registered commands.
  void clear() {
    _commands.clear();
    _commandGroups.clear();
  }

  /// Gets the number of registered commands.
  int get count => _commands.length;
}

