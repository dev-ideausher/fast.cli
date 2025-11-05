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
import 'package:fast/services/config_service.dart';
import 'package:fast/utils/output_formatter.dart';

/// Global dry-run mode flag.
/// 
/// When enabled, operations that modify files or execute commands
/// will be simulated instead of actually executed.
class DryRunMode {
  static bool _enabled = false;
  static final ConfigService _config = ConfigService();

  /// Checks if dry-run mode is enabled.
  /// 
  /// Can be enabled via:
  /// - `FAST_DRY_RUN` environment variable
  /// - Config setting
  /// - Programmatically via [enable]
  static bool get isEnabled {
    return _enabled || _config.getEnvAsBool('FAST_DRY_RUN');
  }

  /// Enables dry-run mode programmatically.
  static void enable() {
    _enabled = true;
  }

  /// Disables dry-run mode.
  static void disable() {
    _enabled = false;
  }

  /// Executes an operation conditionally based on dry-run mode.
  /// 
  /// [description] - Description of what would be executed.
  /// [operation] - The actual operation to execute (if not dry-run).
  /// 
  /// Returns the result of the operation, or a simulated result in dry-run mode.
  static Future<T> execute<T>(
    String description,
    Future<T> Function() operation,
  ) async {
    if (isEnabled) {
      stdout.writeln(OutputFormatter.info('[DRY RUN] $description'));
      // Return a default value for common types
      return _defaultValue<T>();
    }
    return await operation();
  }

  /// Executes a void operation conditionally.
  static Future<void> executeVoid(
    String description,
    Future<void> Function() operation,
  ) async {
    if (isEnabled) {
      stdout.writeln(OutputFormatter.info('[DRY RUN] $description'));
      return;
    }
    await operation();
  }

  /// Executes a synchronous operation conditionally.
  static T executeSync<T>(
    String description,
    T Function() operation,
  ) {
    if (isEnabled) {
      stdout.writeln(OutputFormatter.info('[DRY RUN] $description'));
      return _defaultValue<T>();
    }
    return operation();
  }

  /// Executes a synchronous void operation conditionally.
  static void executeVoidSync(
    String description,
    void Function() operation,
  ) {
    if (isEnabled) {
      stdout.writeln(OutputFormatter.info('[DRY RUN] $description'));
      return;
    }
    operation();
  }

  /// Gets a default value for a type (for dry-run simulation).
  static T _defaultValue<T>() {
    // This is a simplified version. In practice, you might want
    // more sophisticated simulation based on the operation type.
    if (T == bool) return false as T;
    if (T == int) return 0 as T;
    if (T == String) return '' as T;
    if (T == List) return [] as T;
    if (T == Map) return {} as T;
    // For other types, this will throw, which is acceptable
    // since dry-run shouldn't be used with complex return types
    throw UnsupportedError('Cannot simulate return value for type $T');
  }
}

