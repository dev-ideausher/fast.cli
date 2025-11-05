# Fast CLI

An incredible command line interface for Flutter development. Fast CLI provides a powerful, extensible system for generating templates, managing project scaffolds, and automating Flutter development workflows.

## ✨ Features

### Core Capabilities
- 🚀 **Template Generation** - Create code templates from YAML configurations
- 📦 **Plugin System** - Extensible plugin architecture for custom templates and scaffolds
- 🏗️ **Project Scaffolding** - Generate complete project structures with a single command
- 📝 **Snippet Management** - Generate and manage code snippets
- 🔧 **Package Management** - Add and manage Flutter packages

### Advanced Features
- 💬 **Interactive Prompts** - User-friendly CLI interactions
- ⚡ **Performance Caching** - TTL-based caching for expensive operations
- 🔄 **Retry Logic** - Exponential backoff retry for network operations
- 🎨 **Beautiful Output** - Colored tables, formatted messages, and progress indicators
- 🧪 **Dry-Run Mode** - Preview operations without executing them
- 🔒 **Safe File Operations** - Transactional file operations with rollback support
- 🔗 **Command Chaining** - Build pipelines of sequential operations
- ✅ **Result Types** - Type-safe error handling
- 📊 **Progress Tracking** - Visual feedback for long-running operations

## 📦 Installation

### Install from Git

```bash
dart pub global activate -sgit https://github.com/dev-ideausher/fast.cli
```

### Set Up Environment Path

**macOS / Linux:**
```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

Add this to your `~/.zshrc` or `~/.bashrc` for persistence.

**Windows:**
Add `%USERPROFILE%\.pub-cache\bin` to your PATH environment variable.

### Verify Installation

```bash
fast --version
```

## 🚀 Quick Start

### Basic Usage

```bash
# Create a new Flutter project with a scaffold
fast create --name myapp --scaffold sample

# Install a plugin
fast plugin add --name my_plugin --git https://github.com/user/plugin.git

# List available plugins
fast plugin list

# Load a plugin and use its commands
fast load_plugin my_plugin create_template
```

### Using Plugins

Fast CLI uses plugins to extend functionality. To use a plugin:

1. **Add a plugin:**
   ```bash
   fast plugin add --name iu_plugin --git https://github.com/dev-ideausher/iu_plugin.git
   ```

2. **Load the plugin:**
   ```bash
   fast load_plugin iu_plugin
   ```

3. **Use plugin commands:**
   ```bash
   fast create --name myapp --scaffold mobx
   ```

## 📚 Documentation

- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Complete feature documentation and improvements
- **[ADVANCED_FEATURES.md](ADVANCED_FEATURES.md)** - Advanced features quick reference
- **[PUBLISH_CHECKLIST.md](PUBLISH_CHECKLIST.md)** - Development checklist

## 🎯 Advanced Usage

### Interactive Commands

Fast CLI supports interactive prompts for better user experience:

```dart
// In your command implementation
final name = Prompter.prompt('Enter project name', required: true);
final confirmed = Prompter.confirm('Create project?', defaultValue: true);
final template = Prompter.select('Choose template', availableTemplates);
```

### Using Caching

Cache expensive operations for better performance:

```dart
final cache = Cache<String, Template>(defaultTTL: Duration(minutes: 5));
final template = await cache.getOrCompute(
  'template_key',
  () => loadTemplate(),
);
```

### Safe File Operations

Use transactions for atomic file operations:

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

### Command Chaining

Build pipelines of operations:

```dart
final result = await ChainBuilder
  .start(initialValue)
  .addStep('validate', (input) => validate(input))
  .addStep('process', (input) => process(input))
  .addStep('save', (input) => save(input))
  .execute();
```

## 🔧 Environment Variables

Configure Fast CLI behavior with environment variables:

- `FAST_VERBOSE=true` - Enable verbose logging
- `FAST_DEBUG=true` - Enable debug mode with stack traces
- `FAST_LOG_LEVEL=<level>` - Set log level (info, debug, warning, error)
- `FAST_DRY_RUN=true` - Enable dry-run mode (preview without executing)
- `NO_COLOR=1` - Disable colored output

## 📋 Available Commands

### Core Commands

- `fast create` - Create a new Flutter project with scaffold
- `fast plugin` - Manage plugins (add, remove, list, update)
- `fast clear` - Clear generated files

### Plugin Commands

Commands vary by plugin. Common plugin commands include:

- `fast create_template` - Generate code templates
- `fast setup` - Set up project structure
- `fast snippets` - Manage code snippets
- `fast run` - Execute plugin commands

## 🛠️ Development

### Project Structure

```
fast.cli/
├── bin/              # CLI entry point
├── lib/              # Main library code
│   ├── actions/      # Action implementations
│   ├── commands/     # Command definitions
│   ├── core/         # Core utilities (cache, progress, etc.)
│   ├── services/     # Service layer (config, validation)
│   └── utils/        # Utility functions
├── resources/        # Default templates and scaffolds
└── test/             # Test files
```

### Contributing

When contributing:

1. Follow the architecture patterns established in the codebase
2. Use `Result<T>` type for error handling where appropriate
3. Add comprehensive documentation
4. Include progress indicators for long operations
5. Use `ConfigService` for configuration access
6. Write tests for new features

See [IMPROVEMENTS.md](IMPROVEMENTS.md) for detailed architecture information.

## 🐛 Troubleshooting

### Common Issues

**Command not found:**
- Ensure PATH is set correctly
- Run `dart pub global activate` again

**Plugin not loading:**
- Verify plugin path is correct
- Check plugin structure matches requirements
- Use `fast plugin list` to verify installation

**Permission errors:**
- Ensure write permissions for config directory
- Check file system permissions

## 📝 Examples

### Creating a Project

```bash
fast create \
  --name my_flutter_app \
  --scaffold mobx \
  --description "My awesome Flutter app" \
  --androidx \
  --kotlin \
  --swift
```

### Adding a Plugin

```bash
fast plugin add \
  --name my_plugin \
  --git https://github.com/user/my_plugin.git
```

### Using Dry-Run Mode

```bash
FAST_DRY_RUN=true fast create --name test_app --scaffold sample
```

## 🔗 Related Projects

- [IU Plugin](https://github.com/dev-ideausher/iu_plugin.git) - Example plugin for Fast CLI
- [Flunt Dart](https://github.com/dev-ideausher/flunt-dart.git) - Validation library

## 📄 License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Fast CLI is built with ❤️ for the Flutter community.

---

**Need help?** Open an issue on [GitHub](https://github.com/dev-ideausher/fast.cli) or check the [documentation](IMPROVEMENTS.md).
