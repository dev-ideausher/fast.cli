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
import 'package:fast/core/action.dart';
import 'package:fast/logger.dart';

/// A builder pattern implementation for executing a series of actions sequentially.
/// 
/// This class allows chaining multiple actions together and executing them
/// in order. Each action is executed and its success message is logged.
class ActionBuilder implements Action {
  final List<Action> _actions;

  /// Creates an ActionBuilder with an optional initial list of actions.
  ActionBuilder([List<Action>? actions]) : _actions = actions ?? [];

  /// Adds a single action to the execution queue.
  void add(Action action) {
    _actions.add(action);
  }

  /// Adds multiple actions to the execution queue.
  void addAll(List<Action> actions) {
    _actions.addAll(actions);
  }

  /// Executes all actions in sequence, logging each action's success message.
  /// 
  /// If any action throws an exception, the execution is stopped and
  /// the exception is propagated.
  @override
  Future<void> execute() async {
    for (final action in _actions) {
      await action.execute();
      logger.d(action.succesMessage);
    }
  }

  @override
  String get succesMessage => 'All actions executed successfully.';
  
  /// Returns the number of actions queued for execution.
  int get actionCount => _actions.length;
  
  /// Returns whether the builder has any actions to execute.
  bool get isEmpty => _actions.isEmpty;
  
  /// Returns whether the builder has actions to execute.
  bool get isNotEmpty => _actions.isNotEmpty;
}
