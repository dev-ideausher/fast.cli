# Fast CLI - Advanced Improvements

This document outlines the advanced-level improvements made to the Fast CLI project.

## Overview

The Fast CLI has been enhanced with enterprise-level features, better architecture, and improved developer experience.

## Key Improvements

### 1. **Critical Bug Fixes**

#### ActionBuilder Fix
- **Issue**: `ActionBuilder` had a `final` list that couldn't be modified
- **Fix**: Changed to private mutable list with proper encapsulation
- **Location**: `lib/actions/action_builder.dart`

#### Plugin Class Improvements
- **Issue**: Nullable fields with unsafe null checks
- **Fix**: Made fields non-nullable with proper defaults and factory constructors
- **Location**: `lib/config_storage.dart`

### 2. **Architecture Enhancements**

#### Service Layer Pattern
- **ConfigService**: Centralized configuration management
  - Environment variable access
  - Configuration caching
  - Path management
  - Log level control
- **Location**: `lib/services/config_service.dart`

#### Dependency Injection
- Services can be injected or use singleton pattern
- Better testability and modularity
- Applied throughout the codebase

#### Result Type Pattern
- Functional error handling with `Result<T>` type
- Type-safe error handling without exceptions
- Better error propagation
- **Location**: `lib/core/result.dart`

### 3. **Error Handling**

#### Enhanced Exception Hierarchy
- `FastException`: Base exception with cause tracking
- `PluginException`: Plugin-specific errors
- `TemplateException`: Template operation errors
- `FileSystemException`: File system errors
- `ValidationException`: Validation errors
- `ConfigurationException`: Configuration errors
- **Location**: `lib/core/exceptions.dart`

#### Better Error Messages
- More descriptive error messages
- Stack trace support in debug mode
- Proper exit codes

### 4. **User Experience**

#### Progress Indicators
- Spinner for long-running operations
- Progress bars for percentage completion
- `withProgress` helper for async operations
- **Location**: `lib/core/progress.dart`

#### Improved Logging
- Better log levels
- Colored output
- Debug mode support
- Verbose mode support

### 5. **Plugin Management**

#### Plugin Validation
- Structure validation before loading
- YAML validation
- Template directory validation
- Scaffold directory validation
- **Location**: `lib/services/plugin_validator.dart`

#### Enhanced Plugin Storage
- Better error handling
- Automatic directory creation
- Pretty JSON formatting
- Plugin existence checks
- Plugin counting
- **Location**: `lib/config_storage.dart`

### 6. **Code Quality**

#### Documentation
- Comprehensive doc comments
- Inline documentation
- Parameter documentation
- Return value documentation

#### Type Safety
- Better null safety
- Proper type annotations
- Factory constructors where appropriate

#### Command Base Improvements
- Utility methods for common operations
- Better validation
- Helper methods for option parsing
- **Location**: `lib/commands/command_base.dart`

### 7. **New Features**

#### Command Registry
- Centralized command registration
- Command grouping
- Command discovery
- **Location**: `lib/core/command_registry.dart`

#### Configuration Management
- Environment variable support
- Config file support
- Caching for performance
- Debug/verbose mode flags

### 8. **Interactive CLI Experience**

#### Prompter Utilities
- Interactive prompts for user input
- Yes/no confirmations
- Selection from lists
- Multi-select options
- Password input support
- Number input with validation
- **Location**: `lib/utils/prompter.dart`

#### Example:
```dart
final name = Prompter.prompt('Enter project name', required: true);
final confirmed = Prompter.confirm('Create project?', defaultValue: true);
final option = Prompter.select('Choose template', templates);
```

### 9. **Performance Optimization**

#### Caching System
- In-memory cache with TTL support
- Automatic expiration
- `getOrCompute` pattern for expensive operations
- **Location**: `lib/core/cache.dart`

#### Example:
```dart
final cache = Cache<String, Template>(defaultTTL: Duration(minutes: 5));
final template = await cache.getOrCompute(
  'template_key',
  () => loadTemplate(),
);
```

### 10. **Async Utilities**

#### Retry Logic
- Exponential backoff retry
- Configurable retry attempts
- Custom retry callbacks
- **Location**: `lib/utils/async_utils.dart`

#### Timeout Support
- Operation timeouts
- Graceful timeout handling

#### Parallel Processing
- Controlled concurrency
- Parallel map operations
- Semaphore-based limiting

#### Performance Measurement
- Execution time tracking
- Performance callbacks

#### Example:
```dart
// Retry with exponential backoff
final result = await retry(
  () => fetchData(),
  maxRetries: 3,
  onRetry: (attempt, error) => logger.d('Retry $attempt'),
);

// Timeout protection
final data = await withTimeout(
  () => longOperation(),
  Duration(seconds: 30),
);

// Parallel processing
final results = await parallelMap(
  items,
  (item) => processItem(item),
  concurrency: 5,
);
```

### 11. **Enhanced Output Formatting**

#### Color Support
- ANSI color codes
- Automatic color detection
- Terminal-aware formatting
- **Location**: `lib/utils/output_formatter.dart`

#### Table Formatting
- Automatic column width calculation
- Header support
- Border customization

#### Definition Lists
- Key-value pair formatting
- Aligned output

#### Formatted Messages
- Success/error/warning/info prefixes
- Code blocks
- Headers and dividers

#### Example:
```dart
print(OutputFormatter.success('Operation completed'));
print(OutputFormatter.error('Something went wrong'));

final table = Table(
  headers: ['Name', 'Status', 'Version'],
  rows: [
    ['Plugin1', 'Active', '1.0.0'],
    ['Plugin2', 'Inactive', '2.0.0'],
  ],
);
table.print();
```

### 12. **Dry-Run Mode**

#### Safe Preview
- Preview operations without executing
- Environment variable support (`FAST_DRY_RUN`)
- Programmatic control
- **Location**: `lib/core/dry_run.dart`

#### Example:
```dart
await DryRunMode.execute(
  'Create file: example.dart',
  () => createFile('example.dart'),
);
```

### 13. **Safe File Operations**

#### Transaction Support
- File operations with rollback
- Atomic operations
- Backup/restore functionality
- **Location**: `lib/utils/file_operations.dart`

#### Supported Operations
- Safe file writing
- Directory creation
- File deletion
- File copying

#### Example:
```dart
final transaction = FileTransaction();
transaction.addOperation(
  SafeFileOperations.writeFile('config.yaml', content),
);
transaction.addOperation(
  SafeFileOperations.createDirectory('lib/src'),
);

final result = await transaction.commit();
if (result.isError) {
  await transaction.rollback();
}
```

### 14. **Command Chaining**

#### Pipeline Support
- Sequential command execution
- Data flow between steps
- Conditional step skipping
- **Location**: `lib/core/command_chain.dart`

#### Example:
```dart
final result = await ChainBuilder
  .start(initialValue)
  .addStep('validate', (input) => validate(input))
  .addStep('process', (input) => process(input))
  .addStep('save', (input) => save(input))
  .execute();
```

## Usage Examples

### Using Progress Indicators

```dart
await withProgress(
  'Loading templates',
  () async {
    // Your async operation
  },
);
```

### Using Result Types

```dart
Result<Plugin> result = await loadPlugin(name);
result
  .onSuccess((plugin) => logger.d('Loaded: $plugin'))
  .onError((error, msg) => logger.e('Error: $msg'));
```

### Using Config Service

```dart
final config = ConfigService();
final homePath = config.getHomePath();
final isVerbose = config.isVerbose();
```

### Enhanced Command Base

```dart
class MyCommand extends CommandBase {
  @override
  Future<void> run() async {
    final name = requireOption('name');
    final verbose = getFlag('verbose');
    // ...
  }
}
```

## Environment Variables

- `FAST_VERBOSE`: Enable verbose logging
- `FAST_DEBUG`: Enable debug mode
- `FAST_LOG_LEVEL`: Set log level (info, debug, warning, error)
- `FAST_DRY_RUN`: Enable dry-run mode (preview operations without executing)
- `NO_COLOR`: Disable colored output (if set)

## Migration Guide

### For Existing Commands

1. Commands using `ActionBuilder`:
   - No changes needed, but you can now safely add actions

2. Commands using `PluginStorage`:
   - Now uses `ConfigService` internally
   - Better error messages
   - Automatic directory creation

3. Error Handling:
   - Consider using `Result<T>` for new code
   - Use specific exception types
   - Better error messages

## Testing

All improvements maintain backward compatibility while adding new features. Existing tests should continue to work.

## Complete Feature List

### Core Features
- ✅ Result type for functional error handling
- ✅ Enhanced exception hierarchy
- ✅ Progress indicators
- ✅ Configuration service
- ✅ Plugin validation
- ✅ Command registry
- ✅ Interactive prompts
- ✅ Caching system
- ✅ Async utilities (retry, timeout, parallel)
- ✅ Output formatting (tables, colors)
- ✅ Dry-run mode
- ✅ Safe file operations with transactions
- ✅ Command chaining/pipelines

### Utilities
- ✅ Prompter for user interaction
- ✅ Cache for performance
- ✅ Async utilities for robust operations
- ✅ Output formatter for beautiful CLI output
- ✅ File transaction manager
- ✅ Command chain builder

## Future Enhancements

Potential areas for further improvement:
- Unit test coverage expansion
- Integration tests
- Performance benchmarking
- Plugin marketplace
- Version management
- Update mechanism
- Telemetry (opt-in)
- Plugin dependency resolution
- Template inheritance
- Custom validation rules

## Contributing

When contributing, please:
1. Follow the new architecture patterns
2. Use the Result type for error handling where appropriate
3. Add comprehensive documentation
4. Include progress indicators for long operations
5. Use the ConfigService for configuration access

