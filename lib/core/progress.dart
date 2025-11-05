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
import 'package:fast/logger.dart';

/// A simple progress indicator for CLI operations.
/// 
/// Provides visual feedback for long-running operations.
class ProgressIndicator {
  final String _message;
  final bool _showSpinner;
  final List<String> _spinnerChars = ['|', '/', '-', '\\'];
  int _spinnerIndex = 0;
  bool _isActive = false;

  ProgressIndicator(this._message, {bool showSpinner = true}) 
      : _showSpinner = showSpinner;

  /// Starts the progress indicator.
  void start() {
    if (_isActive) return;
    _isActive = true;
    
    if (_showSpinner) {
      _animateSpinner();
    } else {
      logger.d(_message);
    }
  }

  /// Stops the progress indicator.
  void stop({String? completionMessage}) {
    if (!_isActive) return;
    _isActive = false;
    
    if (_showSpinner) {
      stdout.write('\r${' ' * 80}\r'); // Clear line
    }
    
    if (completionMessage != null) {
      logger.d(completionMessage);
    }
  }

  void _animateSpinner() {
    if (!_isActive) return;
    
    stdout.write('\r${_spinnerChars[_spinnerIndex]} $_message');
    _spinnerIndex = (_spinnerIndex + 1) % _spinnerChars.length;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isActive) {
        _animateSpinner();
      }
    });
  }
}

/// A progress bar for showing percentage completion.
class ProgressBar {
  final String _label;
  final int _total;
  int _current = 0;
  final int _barWidth = 40;

  ProgressBar(this._label, this._total);

  /// Updates the progress.
  void update(int value) {
    _current = value.clamp(0, _total);
    _render();
  }

  /// Increments the progress by one.
  void increment() {
    update(_current + 1);
  }

  /// Completes the progress bar.
  void complete() {
    _current = _total;
    _render();
    stdout.writeln();
  }

  void _render() {
    final percentage = (_current / _total * 100).clamp(0, 100);
    final filled = ((_current / _total) * _barWidth).round();
    final bar = '█' * filled + '░' * (_barWidth - filled);
    
    stdout.write('\r$_label: [$bar] ${percentage.toStringAsFixed(1)}%');
  }
}

/// Executes an operation with progress indication.
Future<T> withProgress<T>(
  String message,
  Future<T> Function() operation, {
  bool showSpinner = true,
}) async {
  final progress = ProgressIndicator(message, showSpinner: showSpinner);
  try {
    progress.start();
    final result = await operation();
    progress.stop(completionMessage: '$message ✓');
    return result;
  } catch (e) {
    progress.stop(completionMessage: '$message ✗');
    rethrow;
  }
}

