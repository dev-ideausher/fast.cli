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
import 'package:fast/core/dry_run.dart';
import 'package:fast/core/exceptions.dart';
import 'package:fast/core/result.dart';

/// Represents a file operation that can be rolled back.
class FileOperation {
  final String description;
  final Future<void> Function() execute;
  final Future<void> Function()? rollback;

  FileOperation({
    required this.description,
    required this.execute,
    this.rollback,
  });
}

/// Transaction manager for file operations with rollback support.
class FileTransaction {
  final List<FileOperation> _operations = [];
  bool _committed = false;
  bool _rolledBack = false;

  /// Adds a file operation to the transaction.
  void addOperation(FileOperation operation) {
    if (_committed || _rolledBack) {
      throw FileSystemException(
        'Cannot add operations to a committed or rolled back transaction',
      );
    }
    _operations.add(operation);
  }

  /// Commits all operations in order.
  Future<Result<void>> commit() async {
    if (_committed) {
      return Error(
        exception: FileSystemException('Transaction already committed'),
        message: 'Transaction has already been committed',
      );
    }

    if (_rolledBack) {
      return Error(
        exception: FileSystemException('Transaction was rolled back'),
        message: 'Cannot commit a rolled back transaction',
      );
    }

    try {
      for (final operation in _operations) {
        await DryRunMode.executeVoid(
          operation.description,
          operation.execute,
        );
      }
      _committed = true;
      return const Success(null);
    } catch (e) {
      // Rollback on error
      await rollback();
      return Error.fromException(e, 'Failed to commit transaction');
    }
  }

  /// Rolls back all operations in reverse order.
  Future<void> rollback() async {
    if (_rolledBack) return;
    _rolledBack = true;

    // Rollback in reverse order
    for (var i = _operations.length - 1; i >= 0; i--) {
      final operation = _operations[i];
      if (operation.rollback != null) {
        try {
          await operation.rollback!();
        } catch (e) {
          // Log but continue rolling back
          print('Warning: Failed to rollback operation: ${operation.description}');
        }
      }
    }
  }
}

/// Safe file operations with rollback support.
class SafeFileOperations {
  /// Safely writes content to a file with rollback support.
  /// 
  /// Returns a FileOperation that can be added to a transaction.
  static FileOperation writeFile(
    String filePath,
    String content,
  ) {
    String? backupPath;
    String? originalContent;

    return FileOperation(
      description: 'Write file: $filePath',
      execute: () async {
        final file = File(filePath);
        
        // Backup existing file if it exists
        if (await file.exists()) {
          backupPath = '$filePath.backup';
          originalContent = await file.readAsString();
          await DryRunMode.executeVoid(
            'Backup file: $filePath',
            () async {
              await file.copy(backupPath!);
            },
          );
        }

        // Ensure directory exists
        final dir = file.parent;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // Write new content
        await DryRunMode.executeVoid(
          'Write content to: $filePath',
          () async {
            await file.writeAsString(content);
          },
        );
      },
      rollback: () async {
        if (backupPath != null && await File(backupPath!).exists()) {
          await DryRunMode.executeVoid(
            'Restore backup: $filePath',
            () async {
              await File(backupPath!).copy(filePath);
              await File(backupPath!).delete();
            },
          );
        } else if (originalContent != null) {
          await DryRunMode.executeVoid(
            'Restore original content: $filePath',
            () async {
              await File(filePath).writeAsString(originalContent!);
            },
          );
        } else {
          // File didn't exist before, delete it
          final file = File(filePath);
          if (await file.exists()) {
            await DryRunMode.executeVoid(
              'Delete file: $filePath',
              () async {
                await file.delete();
              },
            );
          }
        }
      },
    );
  }

  /// Safely creates a directory with rollback support.
  static FileOperation createDirectory(String dirPath) {
    bool created = false;

    return FileOperation(
      description: 'Create directory: $dirPath',
      execute: () async {
        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          await DryRunMode.executeVoid(
            'Create directory: $dirPath',
            () async {
              await dir.create(recursive: true);
              created = true;
            },
          );
        }
      },
      rollback: () async {
        if (created) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            await DryRunMode.executeVoid(
              'Remove directory: $dirPath',
              () async {
                await dir.delete(recursive: true);
              },
            );
          }
        }
      },
    );
  }

  /// Safely deletes a file with rollback support.
  static FileOperation deleteFile(String filePath) {
    String? backupPath;
    bool deleted = false;

    return FileOperation(
      description: 'Delete file: $filePath',
      execute: () async {
        final file = File(filePath);
        if (await file.exists()) {
          // Backup before deletion
          backupPath = '$filePath.backup';
          await DryRunMode.executeVoid(
            'Backup file before deletion: $filePath',
            () async {
              await file.copy(backupPath!);
            },
          );

          await DryRunMode.executeVoid(
            'Delete file: $filePath',
            () async {
              await file.delete();
              deleted = true;
            },
          );
        }
      },
      rollback: () async {
        if (deleted && backupPath != null) {
          final backup = File(backupPath!);
          if (await backup.exists()) {
            await DryRunMode.executeVoid(
              'Restore deleted file: $filePath',
              () async {
                await backup.copy(filePath);
                await backup.delete();
              },
            );
          }
        }
      },
    );
  }

  /// Safely copies a file with rollback support.
  static FileOperation copyFile(String sourcePath, String destPath) {
    String? backupPath;
    bool copied = false;

    return FileOperation(
      description: 'Copy file: $sourcePath -> $destPath',
      execute: () async {
        final source = File(sourcePath);
        if (!await source.exists()) {
          throw FileSystemException('Source file does not exist: $sourcePath');
        }

        final dest = File(destPath);
        
        // Backup destination if it exists
        if (await dest.exists()) {
          backupPath = '$destPath.backup';
          await DryRunMode.executeVoid(
            'Backup destination: $destPath',
            () async {
              await dest.copy(backupPath!);
            },
          );
        }

        // Ensure destination directory exists
        final destDir = dest.parent;
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        await DryRunMode.executeVoid(
          'Copy file: $sourcePath -> $destPath',
          () async {
            await source.copy(destPath);
            copied = true;
          },
        );
      },
      rollback: () async {
        if (copied) {
          final dest = File(destPath);
          if (await dest.exists()) {
            if (backupPath != null && await File(backupPath!).exists()) {
              // Restore backup
              await DryRunMode.executeVoid(
                'Restore destination backup: $destPath',
                () async {
                  await File(backupPath!).copy(destPath);
                  await File(backupPath!).delete();
                },
              );
            } else {
              // Just delete the copied file
              await DryRunMode.executeVoid(
                'Remove copied file: $destPath',
                () async {
                  await dest.delete();
                },
              );
            }
          }
        }
      },
    );
  }
}

