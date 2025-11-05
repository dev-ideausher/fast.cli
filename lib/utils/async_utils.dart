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

import 'dart:async';
import 'package:fast/core/exceptions.dart';
import 'package:fast/logger.dart';

/// Retries an async operation with exponential backoff.
/// 
/// [operation] - The async operation to retry.
/// [maxRetries] - Maximum number of retry attempts.
/// [initialDelay] - Initial delay before first retry.
/// [maxDelay] - Maximum delay between retries.
/// [onRetry] - Optional callback called before each retry.
/// 
/// Returns the result of the operation.
Future<T> retry<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 30),
  void Function(int attempt, Object error)? onRetry,
}) async {
  int attempt = 0;
  
  while (true) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      
      if (attempt > maxRetries) {
        throw FastException(
          'Operation failed after $maxRetries retries',
          e,
        );
      }

      if (onRetry != null) {
        onRetry(attempt, e);
      }

      final delay = _calculateDelay(attempt, initialDelay, maxDelay);
      logger.d('Retry attempt $attempt/$maxRetries after ${delay.inSeconds}s...');
      
      await Future.delayed(delay);
    }
  }
}

/// Calculates exponential backoff delay.
Duration _calculateDelay(
  int attempt,
  Duration initialDelay,
  Duration maxDelay,
) {
  final delay = Duration(
    milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
  );
  return delay > maxDelay ? maxDelay : delay;
}

/// Executes an operation with a timeout.
/// 
/// [operation] - The async operation to execute.
/// [timeout] - Maximum time to wait.
/// 
/// Throws [TimeoutException] if the operation exceeds the timeout.
Future<T> withTimeout<T>(
  Future<T> Function() operation,
  Duration timeout,
) async {
  return await operation().timeout(
    timeout,
    onTimeout: () {
      throw FastException('Operation timed out after ${timeout.inSeconds}s');
    },
  );
}

/// Executes multiple operations in parallel with concurrency limit.
/// 
/// [items] - List of items to process.
/// [operation] - Async operation to apply to each item.
/// [concurrency] - Maximum number of concurrent operations.
/// 
/// Returns results in the same order as input items.
Future<List<T>> parallelMap<R, T>(
  List<R> items,
  Future<T> Function(R item) operation, {
  int concurrency = 5,
}) async {
  final results = List<T?>.filled(items.length, null);
  final semaphore = Semaphore(concurrency);
  final futures = <Future<void>>[];

  for (int i = 0; i < items.length; i++) {
    final index = i;
    final item = items[i];

    futures.add(
      semaphore.acquire().then((_) async {
        try {
          results[index] = await operation(item);
        } finally {
          semaphore.release();
        }
      }),
    );
  }

  await Future.wait(futures);
  return results.cast<T>();
}

/// A simple semaphore for limiting concurrency.
class Semaphore {
  final int _maxCount;
  int _currentCount;
  final QueueCompleter<void> _waitQueue = QueueCompleter<void>();

  Semaphore(this._maxCount) : _currentCount = _maxCount;

  /// Gets the maximum concurrency allowed.
  int get maxCount => _maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
      // Ensure we don't exceed max count
      if (_currentCount > _maxCount) {
        _currentCount = _maxCount;
      }
    }
  }
}

/// A queue of completers.
class QueueCompleter<T> {
  final List<Completer<T>> _queue = [];

  void add(Completer<T> completer) {
    _queue.add(completer);
  }

  Completer<T> removeFirst() {
    return _queue.removeAt(0);
  }

  bool get isNotEmpty => _queue.isNotEmpty;
}

/// Executes an operation and measures its execution time.
/// 
/// [operation] - The operation to execute.
/// [onComplete] - Optional callback with execution time.
/// 
/// Returns the result of the operation.
Future<T> measureTime<T>(
  Future<T> Function() operation, {
  void Function(Duration duration)? onComplete,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    return await operation();
  } finally {
    stopwatch.stop();
    onComplete?.call(stopwatch.elapsed);
  }
}

