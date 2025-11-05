# Advanced Features - Round 2

This document highlights the additional advanced features added to Fast CLI.

## 🎯 New Capabilities

### 1. Interactive CLI (`lib/utils/prompter.dart`)

Make your commands interactive and user-friendly:

```dart
// Simple prompt
final name = Prompter.prompt('Enter project name', required: true);

// Confirmation
final confirmed = Prompter.confirm('Create project?', defaultValue: true);

// Selection from list
final template = Prompter.select('Choose template', templates);

// Multi-select
final plugins = Prompter.multiSelect('Select plugins', availablePlugins);

// Number input
final port = Prompter.promptNumber('Enter port', min: 1, max: 65535);
```

### 2. Performance Caching (`lib/core/cache.dart`)

Cache expensive operations to improve performance:

```dart
final cache = Cache<String, Template>(
  defaultTTL: Duration(minutes: 5),
);

// Get or compute pattern
final template = await cache.getOrCompute(
  'template_key',
  () => expensiveLoadOperation(),
);

// Manual caching
cache.put('key', value, ttl: Duration(hours: 1));
final cached = cache.get('key');
```

### 3. Async Utilities (`lib/utils/async_utils.dart`)

Robust async operations with retry, timeout, and parallel processing:

```dart
// Retry with exponential backoff
final result = await retry(
  () => networkRequest(),
  maxRetries: 3,
  initialDelay: Duration(seconds: 1),
  onRetry: (attempt, error) => logger.d('Retry $attempt'),
);

// Timeout protection
final data = await withTimeout(
  () => longOperation(),
  Duration(seconds: 30),
);

// Parallel processing with concurrency limit
final results = await parallelMap(
  items,
  (item) => processItem(item),
  concurrency: 5, // Max 5 concurrent operations
);

// Measure execution time
final result = await measureTime(
  () => expensiveOperation(),
  onComplete: (duration) => logger.d('Took ${duration.inSeconds}s'),
);
```

### 4. Beautiful Output (`lib/utils/output_formatter.dart`)

Create professional-looking CLI output:

```dart
// Colored messages
print(OutputFormatter.success('Operation completed'));
print(OutputFormatter.error('Something went wrong'));
print(OutputFormatter.warning('This is a warning'));
print(OutputFormatter.info('Informational message'));

// Tables
final table = Table(
  headers: ['Name', 'Status', 'Version'],
  rows: [
    ['Plugin1', 'Active', '1.0.0'],
    ['Plugin2', 'Inactive', '2.0.0'],
  ],
);
table.print();

// Definition lists
final info = DefinitionList(
  items: {
    'Version': '1.0.0',
    'Author': 'Your Name',
    'License': 'MIT',
  },
);
info.print();
```

### 5. Dry-Run Mode (`lib/core/dry_run.dart`)

Preview operations without executing them:

```dart
// Enable via environment variable
// FAST_DRY_RUN=true fast create myapp

// Or programmatically
DryRunMode.enable();

// Operations automatically detect dry-run mode
await DryRunMode.execute(
  'Create file: example.dart',
  () => File('example.dart').writeAsString('content'),
);

// Check if enabled
if (DryRunMode.isEnabled) {
  logger.d('Running in dry-run mode');
}
```

### 6. Safe File Operations (`lib/utils/file_operations.dart`)

Atomic file operations with rollback support:

```dart
// Create a transaction
final transaction = FileTransaction();

// Add operations
transaction.addOperation(
  SafeFileOperations.writeFile('config.yaml', yamlContent),
);
transaction.addOperation(
  SafeFileOperations.createDirectory('lib/src'),
);
transaction.addOperation(
  SafeFileOperations.copyFile('template.dart', 'lib/main.dart'),
);

// Commit (all or nothing)
final result = await transaction.commit();
if (result.isError) {
  // Automatically rolled back
  logger.e('Transaction failed: ${result.getOrNull()}');
} else {
  logger.d('All operations completed successfully');
}
```

### 7. Command Chaining (`lib/core/command_chain.dart`)

Build pipelines of operations:

```dart
// Simple chain
final result = await ChainBuilder
  .start(inputData)
  .addStep('validate', (data) => validateData(data))
  .addStep('transform', (data) => transformData(data))
  .addStep('save', (data) => saveData(data))
  .execute();

// With conditional skipping
final result = await ChainBuilder
  .start(plugin)
  .addStep(
    'validate',
    (plugin) => validatePlugin(plugin),
    shouldSkip: (plugin) => plugin.isValidated,
  )
  .addStep('load', (plugin) => loadPlugin(plugin))
  .execute();

// Using Result type
if (result.isSuccess) {
  final finalData = result.getOrThrow();
  logger.d('Chain completed: $finalData');
}
```

## 🚀 Quick Start Examples

### Example 1: Interactive Plugin Installation

```dart
class InstallPluginCommand extends CommandBase {
  @override
  Future<void> run() async {
    // Interactive prompt
    final pluginName = Prompter.prompt('Plugin name', required: true);
    
    // Confirmation
    final confirmed = Prompter.confirm('Install plugin?', defaultValue: true);
    if (!confirmed) return;
    
    // Cache plugin data
    final cache = Cache<String, Plugin>(defaultTTL: Duration(hours: 1));
    final plugin = await cache.getOrCompute(
      pluginName,
      () => fetchPlugin(pluginName),
    );
    
    // Safe installation with transaction
    final transaction = FileTransaction();
    transaction.addOperation(
      SafeFileOperations.createDirectory(plugin.path),
    );
    transaction.addOperation(
      SafeFileOperations.writeFile('${plugin.path}/config.yaml', config),
    );
    
    final result = await transaction.commit();
    if (result.isSuccess) {
      print(OutputFormatter.success('Plugin installed successfully'));
    } else {
      print(OutputFormatter.error('Installation failed'));
    }
  }
}
```

### Example 2: Robust Network Operation

```dart
// Retry with timeout
final pluginData = await retry(
  () => withTimeout(
    () => http.get(pluginUrl),
    Duration(seconds: 30),
  ),
  maxRetries: 3,
  onRetry: (attempt, error) {
    logger.w('Retry attempt $attempt after network error');
  },
);
```

### Example 3: Parallel Processing

```dart
// Process multiple plugins in parallel
final plugins = await loadPluginList();
final results = await parallelMap(
  plugins,
  (plugin) async {
    return await measureTime(
      () => validatePlugin(plugin),
      onComplete: (duration) {
        logger.d('Validated ${plugin.name} in ${duration.inMilliseconds}ms');
      },
    );
  },
  concurrency: 5, // Max 5 at a time
);
```

## 📊 Feature Comparison

| Feature | Before | After |
|---------|--------|-------|
| User Input | Command-line args only | Interactive prompts |
| Error Handling | Exceptions only | Result type + exceptions |
| Performance | No caching | TTL-based caching |
| Network | No retry | Exponential backoff retry |
| Output | Plain text | Colored tables, formatted |
| File Ops | Direct | Transactional with rollback |
| Testing | Hard to test | Dry-run mode |
| Operations | Sequential | Chainable pipelines |

## 🎨 Best Practices

1. **Use Prompter for user-friendly commands** - Especially for interactive workflows
2. **Cache expensive operations** - YAML parsing, network requests, file reads
3. **Use retry for network operations** - Handle transient failures gracefully
4. **Use transactions for file operations** - Ensure atomicity
5. **Enable dry-run for testing** - Preview changes safely
6. **Use output formatter** - Consistent, beautiful CLI output
7. **Chain operations** - Build complex workflows easily

## 🔧 Environment Variables

- `FAST_DRY_RUN=true` - Enable dry-run mode
- `NO_COLOR=1` - Disable colored output
- `FAST_VERBOSE=true` - Verbose logging
- `FAST_DEBUG=true` - Debug mode

## 📚 See Also

- [IMPROVEMENTS.md](IMPROVEMENTS.md) - Complete improvements documentation
- Individual feature files in `lib/` for detailed API documentation

