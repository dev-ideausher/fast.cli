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

/// A Result type for functional error handling.
/// 
/// This provides a type-safe way to handle success and error cases
/// without throwing exceptions.
sealed class Result<T> {
  const Result();
  
  /// Returns true if this is a success result.
  bool get isSuccess => this is Success<T>;
  
  /// Returns true if this is an error result.
  bool get isError => this is Error<T>;
  
  /// Unwraps the value if successful, or throws if an error.
  T getOrThrow() {
    return switch (this) {
      Success(value: final value) => value,
      Error() => throw Exception('Attempted to unwrap error result'),
    };
  }
  
  /// Returns the value if successful, or null if an error.
  T? getOrNull() {
    return switch (this) {
      Success(value: final value) => value,
      Error() => null,
    };
  }
  
  /// Maps the success value to a new type.
  Result<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Success(value: final value) => Success(mapper(value)),
      Error(exception: final exception, message: final message) => 
        Error(exception: exception, message: message),
    };
  }
  
  /// Maps the success value to a new Result type.
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return switch (this) {
      Success(value: final value) => mapper(value),
      Error(exception: final exception, message: final message) => 
        Error(exception: exception, message: message),
    };
  }
  
  /// Executes a function if this is a success result.
  Result<T> onSuccess(void Function(T value) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).value);
    }
    return this;
  }
  
  /// Executes a function if this is an error result.
  Result<T> onError(void Function(Object exception, String message) callback) {
    if (this is Error<T>) {
      final error = this as Error<T>;
      callback(error.exception, error.message);
    }
    return this;
  }
}

/// Represents a successful operation result.
final class Success<T> extends Result<T> {
  final T value;
  
  const Success(this.value);
  
  @override
  String toString() => 'Success($value)';
}

/// Represents a failed operation result.
final class Error<T> extends Result<T> {
  final Object exception;
  final String message;
  
  const Error({required this.exception, required this.message});
  
  @override
  String toString() => 'Error(exception: $exception, message: $message)';
  
  /// Creates an Error from an exception.
  factory Error.fromException(Object exception, [String? message]) {
    return Error(
      exception: exception,
      message: message ?? exception.toString(),
    );
  }
}

