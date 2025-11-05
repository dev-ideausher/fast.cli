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
import 'package:fast/core/home_path.dart';
import 'package:fast/core/result.dart';
import 'package:fast/core/exceptions.dart';

/// Service for managing CLI configuration and environment settings.
/// 
/// Provides access to configuration values from environment variables,
/// config files, and default values.
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  /// Cache for environment variables
  final Map<String, String?> _envCache = {};
  
  /// Cache for config values
  final Map<String, dynamic> _configCache = {};

  /// Gets the home directory path for storing CLI data.
  String getHomePath() {
    try {
      return homePath();
    } catch (e) {
      throw FastException('Failed to determine home directory: $e');
    }
  }

  /// Gets the Fast CLI configuration directory.
  String getConfigDir() {
    return '${getHomePath()}/.fastcli';
  }

  /// Gets the plugins configuration file path.
  String getPluginsConfigPath() {
    return '${getConfigDir()}/plugins.json';
  }

  /// Gets an environment variable value.
  /// 
  /// Returns null if the variable is not set.
  String? getEnv(String key) {
    if (_envCache.containsKey(key)) {
      return _envCache[key];
    }
    
    final value = Platform.environment[key];
    _envCache[key] = value;
    return value;
  }

  /// Gets an environment variable value with a default fallback.
  String getEnvOrDefault(String key, String defaultValue) {
    return getEnv(key) ?? defaultValue;
  }

  /// Gets an environment variable as a boolean.
  /// 
  /// Returns true if the value is 'true', '1', 'yes', 'on' (case-insensitive).
  bool getEnvAsBool(String key, {bool defaultValue = false}) {
    final value = getEnv(key);
    if (value == null) return defaultValue;
    
    final lowerValue = value.toLowerCase();
    return lowerValue == 'true' || 
           lowerValue == '1' || 
           lowerValue == 'yes' || 
           lowerValue == 'on';
  }

  /// Gets an integer from environment variable.
  int? getEnvAsInt(String key) {
    final value = getEnv(key);
    if (value == null) return null;
    
    return int.tryParse(value);
  }

  /// Sets a configuration value in the cache.
  void setConfig(String key, dynamic value) {
    _configCache[key] = value;
  }

  /// Gets a configuration value from the cache.
  T? getConfig<T>(String key) {
    return _configCache[key] as T?;
  }

  /// Gets a configuration value with a default fallback.
  T getConfigOrDefault<T>(String key, T defaultValue) {
    return _configCache[key] as T? ?? defaultValue;
  }

  /// Clears the configuration cache.
  void clearCache() {
    _envCache.clear();
    _configCache.clear();
  }

  /// Checks if verbose logging is enabled.
  bool isVerbose() {
    return getEnvAsBool('FAST_VERBOSE', defaultValue: false) ||
           getConfigOrDefault('verbose', false);
  }

  /// Checks if debug mode is enabled.
  bool isDebug() {
    return getEnvAsBool('FAST_DEBUG', defaultValue: false) ||
           getConfigOrDefault('debug', false);
  }

  /// Gets the log level from environment or config.
  String getLogLevel() {
    return getEnv('FAST_LOG_LEVEL') ?? 
           getConfigOrDefault('logLevel', 'info');
  }

  /// Ensures the configuration directory exists.
  Future<Result<void>> ensureConfigDir() async {
    try {
      final dir = Directory(getConfigDir());
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return const Success(null);
    } catch (e) {
      return Error.fromException(
        e,
        'Failed to create config directory: ${getConfigDir()}',
      );
    }
  }
}

