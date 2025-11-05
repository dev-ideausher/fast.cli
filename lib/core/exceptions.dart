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

/// Base exception class for Fast CLI operations.
class FastException implements Exception {
  final String msg;
  final Object? cause;
  
  FastException(this.msg, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return '$runtimeType: $msg\nCaused by: $cause';
    }
    return '$runtimeType: $msg';
  }
}

/// Exception thrown when the platform is not supported.
class UnsupportedPlatformException extends FastException {
  UnsupportedPlatformException() 
      : super('Platform not compatible with Fast CLI. Use Windows, Linux or MacOS.');
}

/// Exception thrown when a required configuration is missing.
class ConfigurationException extends FastException {
  ConfigurationException(String msg) : super('Configuration error: $msg');
}

/// Exception thrown when a plugin operation fails.
class PluginException extends FastException {
  PluginException(String msg, [Object? cause]) : super('Plugin error: $msg', cause);
}

/// Exception thrown when a template operation fails.
class TemplateException extends FastException {
  TemplateException(String msg, [Object? cause]) : super('Template error: $msg', cause);
}

/// Exception thrown when a file system operation fails.
class FileSystemException extends FastException {
  FileSystemException(String msg, [Object? cause]) : super('File system error: $msg', cause);
}

/// Exception thrown when a validation fails.
class ValidationException extends FastException {
  ValidationException(String msg) : super('Validation error: $msg');
}
