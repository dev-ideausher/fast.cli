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

import 'package:fast/core/exceptions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PackagesService {
  static const pubUrl = 'https://pub.dev/api/packages';

  Future<Package> fetchPackage(
    String packageName,
  ) async {
    final url = '$pubUrl/$packageName';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final map = jsonDecode(response.body);
        //  final map = data as Map;
        return Package.fromJson(map);
      }
      throw FastException('Not found package.');
    } catch (e) {
      throw FastException('''An error occurs when picking up the package $packageName 
Check that the package name is valid.
''');
    }
  }
}

class Package {
  late String name;
  Version? latest;

  Package({required this.name, this.latest, versions});

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      name: json['name'] as String,
      latest: json['latest'] != null ? Version.fromJson(json['latest'] as Map<String, dynamic>) : null,
    );
  }
}


class Version {
  late String version;
  late String archiveUrl;
  late String published;

  Version({required this.version, required this.archiveUrl, required this.published});

  factory Version.fromJson(Map<String, dynamic> json) {
    return Version(
      version: json['version'] as String,
      archiveUrl: json['archive_url'] as String,
      published: json['published'] as String,
    );
  }
}

