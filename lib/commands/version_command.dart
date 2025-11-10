import 'package:args/command_runner.dart';
import 'package:fast/core/version.dart';

class VersionCommand extends Command<void> {
  @override
  String get description => 'Print the Fast CLI version.';

  @override
  String get name => 'version';

  @override
  Future<void> run() async {
    print(FastVersion.versionString);
  }
}

