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
import 'package:fast/core/exceptions.dart';
import 'package:fast/logger.dart';

/// Interactive prompt utilities for CLI commands.
/// 
/// Provides methods for asking user input, confirmations, and selections.
class Prompter {
  /// Prompts the user for input with a message.
  /// 
  /// [message] - The prompt message to display.
  /// [defaultValue] - Optional default value if user just presses Enter.
  /// [required] - Whether the input is required (non-empty).
  /// 
  /// Returns the user's input or the default value.
  static String prompt(
    String message, {
    String? defaultValue,
    bool required = false,
  }) {
    stdout.write('$message${defaultValue != null ? ' [$defaultValue]' : ''}: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    
    if (input.isEmpty) {
      if (defaultValue != null) {
        return defaultValue;
      }
      if (required) {
        logger.e('This field is required. Please try again.');
        return prompt(message, defaultValue: defaultValue, required: required);
      }
    }
    
    return input;
  }

  /// Prompts for a yes/no confirmation.
  /// 
  /// [message] - The confirmation message.
  /// [defaultValue] - Default value if user just presses Enter.
  /// 
  /// Returns true for yes, false for no.
  static bool confirm(String message, {bool defaultValue = false}) {
    final defaultText = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$message [$defaultText]: ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    
    if (input.isEmpty) {
      return defaultValue;
    }
    
    return input == 'y' || input == 'yes';
  }

  /// Prompts for a selection from a list of options.
  /// 
  /// [message] - The prompt message.
  /// [options] - List of options to choose from.
  /// [displayOption] - Function to display each option (defaults to toString).
  /// 
  /// Returns the selected option or null if cancelled.
  static T? select<T>(
    String message,
    List<T> options, {
    String Function(T)? displayOption,
  }) {
    if (options.isEmpty) {
      throw ValidationException('No options provided for selection');
    }

    logger.d('\n$message');
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      final display = displayOption != null 
          ? displayOption(option) 
          : option.toString();
      logger.d('  ${i + 1}. $display');
    }

    while (true) {
      stdout.write('\nSelect an option (1-${options.length}): ');
      final input = stdin.readLineSync()?.trim() ?? '';
      
      if (input.isEmpty) {
        return null;
      }

      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= options.length) {
        return options[index - 1];
      }

      logger.e('Invalid selection. Please enter a number between 1 and ${options.length}.');
    }
  }

  /// Prompts for a password (with hidden input).
  /// 
  /// [message] - The prompt message.
  /// [required] - Whether the password is required.
  /// 
  /// Returns the password string.
  static String password(String message, {bool required = true}) {
    stdout.write('$message: ');
    
    // Note: This is a simplified version. For production, consider
    // using a package that properly handles password input.
    final input = stdin.readLineSync()?.trim() ?? '';
    
    if (required && input.isEmpty) {
      logger.e('Password is required. Please try again.');
      return password(message, required: required);
    }
    
    return input;
  }

  /// Prompts for a number within a range.
  /// 
  /// [message] - The prompt message.
  /// [min] - Minimum allowed value.
  /// [max] - Maximum allowed value.
  /// [defaultValue] - Default value if user just presses Enter.
  /// 
  /// Returns the selected number.
  static int promptNumber(
    String message, {
    int? min,
    int? max,
    int? defaultValue,
  }) {
    while (true) {
      stdout.write('$message${defaultValue != null ? ' [$defaultValue]' : ''}: ');
      final input = stdin.readLineSync()?.trim() ?? '';
      
      if (input.isEmpty && defaultValue != null) {
        return defaultValue;
      }

      final number = int.tryParse(input);
      if (number == null) {
        logger.e('Please enter a valid number.');
        continue;
      }

      if (min != null && number < min) {
        logger.e('Number must be at least $min.');
        continue;
      }

      if (max != null && number > max) {
        logger.e('Number must be at most $max.');
        continue;
      }

      return number;
    }
  }

  /// Prompts for multiple selections.
  /// 
  /// [message] - The prompt message.
  /// [options] - List of options to choose from.
  /// [displayOption] - Function to display each option.
  /// 
  /// Returns the list of selected options.
  static List<T> multiSelect<T>(
    String message,
    List<T> options, {
    String Function(T)? displayOption,
  }) {
    if (options.isEmpty) {
      throw ValidationException('No options provided for selection');
    }

    logger.d('\n$message (select multiple, comma-separated)');
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      final display = displayOption != null 
          ? displayOption(option) 
          : option.toString();
      logger.d('  ${i + 1}. $display');
    }

    final selected = <T>[];
    
    while (true) {
      stdout.write('\nSelect options (comma-separated, e.g., 1,3,5): ');
      final input = stdin.readLineSync()?.trim() ?? '';
      
      if (input.isEmpty) {
        return selected;
      }

      final indices = input
          .split(',')
          .map((s) => s.trim())
          .map(int.tryParse)
          .where((i) => i != null)
          .cast<int>()
          .toList();

      if (indices.isEmpty) {
        logger.e('Invalid input. Please enter comma-separated numbers.');
        continue;
      }

      final invalid = indices.where((i) => i < 1 || i > options.length);
      if (invalid.isNotEmpty) {
        logger.e('Invalid selection(s): ${invalid.join(", ")}. Please try again.');
        continue;
      }

      selected.addAll(indices.map((i) => options[i - 1]));
      return selected;
    }
  }
}

