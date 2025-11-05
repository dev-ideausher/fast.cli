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

/// ANSI color codes for terminal output.
class Color {
  static const String reset = '\x1B[0m';
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';
  
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String underline = '\x1B[4m';

  /// Checks if colors are supported (not redirected output).
  static bool get supportsColor {
    return stdout.hasTerminal && 
           Platform.environment['NO_COLOR'] == null;
  }

  /// Applies color to text if supported.
  static String apply(String text, String colorCode) {
    if (!supportsColor) return text;
    return '$colorCode$text$reset';
  }
}

/// Formats output as a table.
class Table {
  final List<String> headers;
  final List<List<String>> rows;
  final bool showHeaders;
  final String? borderStyle;

  Table({
    required this.headers,
    required this.rows,
    this.showHeaders = true,
    this.borderStyle,
  });

  /// Renders the table as a string.
  String render() {
    if (headers.isEmpty && rows.isEmpty) return '';

    final columnWidths = _calculateColumnWidths();
    final buffer = StringBuffer();

    if (showHeaders && headers.isNotEmpty) {
      buffer.writeln(_renderRow(headers, columnWidths));
      buffer.writeln(_renderSeparator(columnWidths));
    }

    for (final row in rows) {
      buffer.writeln(_renderRow(row, columnWidths));
    }

    return buffer.toString();
  }

  List<int> _calculateColumnWidths() {
    final widths = <int>[];
    final allRows = showHeaders ? [headers, ...rows] : rows;

    if (allRows.isEmpty) return widths;

    final columnCount = allRows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < columnCount; i++) {
      int maxWidth = 0;
      for (final row in allRows) {
        if (i < row.length) {
          final width = row[i].length;
          if (width > maxWidth) maxWidth = width;
        }
      }
      widths.add(maxWidth);
    }

    return widths;
  }

  String _renderRow(List<String> cells, List<int> widths) {
    final padded = <String>[];
    for (int i = 0; i < widths.length; i++) {
      final cell = i < cells.length ? cells[i] : '';
      final width = widths[i];
      padded.add(cell.padRight(width));
    }
    return padded.join('  ');
  }

  String _renderSeparator(List<int> widths) {
    return widths.map((w) => '-' * w).join('--');
  }

  /// Prints the table to stdout.
  void print() {
    stdout.writeln(render());
  }
}

/// Formats key-value pairs as a definition list.
class DefinitionList {
  final Map<String, String> items;
  final String separator;
  final int keyWidth;

  DefinitionList({
    required this.items,
    this.separator = ': ',
    this.keyWidth = 20,
  });

  /// Renders the definition list as a string.
  String render() {
    final buffer = StringBuffer();
    for (final entry in items.entries) {
      final key = entry.key.padRight(keyWidth);
      buffer.writeln('$key$separator${entry.value}');
    }
    return buffer.toString();
  }

  /// Prints the definition list to stdout.
  void print() {
    stdout.writeln(render());
  }
}

/// Utility for creating formatted output.
class OutputFormatter {
  /// Creates a success message.
  static String success(String message) {
    return Color.apply('✓ $message', Color.green);
  }

  /// Creates an error message.
  static String error(String message) {
    return Color.apply('✗ $message', Color.red);
  }

  /// Creates a warning message.
  static String warning(String message) {
    return Color.apply('⚠ $message', Color.yellow);
  }

  /// Creates an info message.
  static String info(String message) {
    return Color.apply('ℹ $message', Color.blue);
  }

  /// Creates a bold header.
  static String header(String text) {
    return Color.apply(text, Color.bold);
  }

  /// Creates a code block.
  static String code(String text) {
    return Color.apply(text, Color.brightCyan);
  }

  /// Creates a section divider.
  static String divider({String char = '─', int length = 60}) {
    return char * length;
  }
}

