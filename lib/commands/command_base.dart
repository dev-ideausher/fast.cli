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
import 'package:fast/core/exceptions.dart';
import 'package:fast/core/validation.dart';
import '../logger.dart';

/// Base class for all Fast CLI commands.
/// 
/// Provides common functionality for command validation and error handling.
/// All commands should extend this class to get consistent validation behavior.
abstract class CommandBase<T> extends Command<T> {
  /// Validates a contract and exits with proper error code if invalid.
  /// 
  /// [contract] - The validation contract to check.
  /// 
  /// Exits with code 64 (usage error) if validation fails.
  void validate(Contract contract) {
    if (contract.invalid) {
      logger.e('Invalid arguments:');
      for (final notification in contract.notifications) {
        logger.e('  ${notification.property}: ${notification.message}');
      }
      logger.d('\n$usage');
      throw ValidationException(
        'Command validation failed. See errors above.',
      );
    }
  }

  /// Gets a required option value or throws an exception.
  /// 
  /// [name] - The option name.
  /// 
  /// Throws [ValidationException] if the option is not provided.
  String requireOption(String name) {
    final value = argResults?[name] as String?;
    if (value == null || value.isEmpty) {
      throw ValidationException('Required option "--$name" is missing');
    }
    return value;
  }

  /// Gets an optional option value with a default.
  /// 
  /// [name] - The option name.
  /// [defaultValue] - The default value if not provided.
  String getOptionOrDefault(String name, String defaultValue) {
    return argResults?[name] as String? ?? defaultValue;
  }

  /// Gets a boolean flag value.
  /// 
  /// [name] - The flag name.
  /// [defaultValue] - The default value if not provided.
  bool getFlag(String name, {bool defaultValue = false}) {
    return argResults?.wasParsed(name) ?? false || defaultValue;
  }

  /// Validates that at least one of the given options is provided.
  /// 
  /// [optionNames] - List of option names to check.
  /// 
  /// Throws [ValidationException] if none of the options are provided.
  void requireAtLeastOne(List<String> optionNames) {
    final hasAny = optionNames.any((name) => 
      argResults?.wasParsed(name) ?? false
    );
    
    if (!hasAny) {
      throw ValidationException(
        'At least one of the following options must be provided: '
        '${optionNames.map((n) => '--$n').join(', ')}',
      );
    }
  }
}
