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

import 'package:fast/core/result.dart';
import 'package:fast/logger.dart';

/// Represents a step in a command chain.
class ChainStep<TInput, TOutput> {
  final String name;
  final Future<TOutput> Function(TInput input) execute;
  final bool Function(TInput input)? shouldSkip;
  final String? description;

  ChainStep({
    required this.name,
    required this.execute,
    this.shouldSkip,
    this.description,
  });
}

/// A command chain that executes steps sequentially.
/// 
/// Each step receives the output of the previous step as input.
/// Steps can be conditionally skipped.
class CommandChain<TInitial, TFinal> {
  final List<ChainStep> _steps = [];
  TInitial? _initialValue;

  /// Sets the initial value for the chain.
  CommandChain<TInitial, TFinal> withInitial(TInitial value) {
    _initialValue = value;
    return this;
  }

  /// Adds a step to the chain.
  CommandChain<TInitial, TFinal> addStep<TOutput>(
    String name,
    Future<TOutput> Function(dynamic input) execute, {
    bool Function(dynamic input)? shouldSkip,
    String? description,
  }) {
    _steps.add(ChainStep(
      name: name,
      execute: execute,
      shouldSkip: shouldSkip,
      description: description,
    ));
    return this;
  }

  /// Executes the chain and returns the final result.
  Future<Result<TFinal>> execute() async {
    if (_initialValue == null) {
      return Error(
        exception: Exception('No initial value set for chain'),
        message: 'Call withInitial() before executing the chain',
      );
    }

    dynamic currentValue = _initialValue;

    try {
      for (final step in _steps) {
        // Check if step should be skipped
        if (step.shouldSkip != null && step.shouldSkip!(currentValue)) {
          logger.d('Skipping step: ${step.name}');
          continue;
        }

        logger.d('Executing step: ${step.name}${step.description != null ? ' - ${step.description}' : ''}');
        currentValue = await step.execute(currentValue);
      }

      return Success(currentValue as TFinal);
    } catch (e) {
      return Error.fromException(e, 'Chain execution failed');
    }
  }

  /// Executes the chain and returns the result directly (throws on error).
  Future<TFinal> executeOrThrow() async {
    final result = await execute();
    if (result.isError) {
      final error = result as Error<TFinal>;
      throw Exception('Chain execution failed: ${error.message}');
    }
    return result.getOrThrow();
  }
}

/// Builder for creating command chains.
class ChainBuilder {
  /// Creates a new chain with an initial value.
  static CommandChain<T, T> start<T>(T initialValue) {
    return CommandChain<T, T>().withInitial(initialValue);
  }

  /// Creates an empty chain (requires initial value to be set).
  static CommandChain<T, T> empty<T>() {
    return CommandChain<T, T>();
  }
}

