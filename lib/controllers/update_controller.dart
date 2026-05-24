import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

class UpdateController extends GetxController {
  final _client = http.Client();

  var isChecking = false.obs;
  var isUpdateAvailable = false.obs;
  var latestVersion = ''.obs;
  var latestReleaseNotes = ''.obs;
  var downloadUrl = ''.obs;

  var isDownloading = false.obs;
  var downloadProgress = 0.0.obs;
  var downloadedFilePath = ''.obs;

  Future<void> checkForUpdates({bool showSnackbarIfUpToDate = true}) async {
    isChecking.value = true;
    try {
      final response = await _client.get(
        Uri.parse(
          'https://api.github.com/repos/iad1tya/WhyyCloud/releases/latest',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tag = data['tag_name'] as String;
        final latestTag = tag.startsWith('v') ? tag.substring(1) : tag;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isNewer(latestTag, currentVersion)) {
          isUpdateAvailable.value = true;
          latestVersion.value = tag;
          latestReleaseNotes.value = data['body'] ?? 'No release notes.';

          final assets = data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (a) => a['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );

          if (apkAsset != null) {
            downloadUrl.value = apkAsset['browser_download_url'];
          }
        } else {
          isUpdateAvailable.value = false;
          if (showSnackbarIfUpToDate) {}
        }
      } else {
        if (showSnackbarIfUpToDate) {}
      }
    } catch (e) {
      if (showSnackbarIfUpToDate) {}
    } finally {
      isChecking.value = false;
    }
  }

  bool _isNewer(String latest, String current) {
    // Basic semver comparison
    final lParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final cParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final l = i < lParts.length ? lParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  Future<void> downloadUpdate() async {
    if (downloadUrl.value.isEmpty) return;

    isDownloading.value = true;
    downloadProgress.value = 0.0;

    try {
      final request = http.Request('GET', Uri.parse(downloadUrl.value));
      final response = await _client.send(request);
      final total = response.contentLength ?? 0;

      int received = 0;
      final bytes = <int>[];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) {
          downloadProgress.value = received / total;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, 'update.apk'));
      await file.writeAsBytes(bytes);

      downloadedFilePath.value = file.path;
    } catch (e) {
    } finally {
      isDownloading.value = false;
    }
  }

  Future<void> installUpdate() async {
    if (downloadedFilePath.value.isEmpty) return;

    final result = await OpenFilex.open(downloadedFilePath.value);
    if (result.type != ResultType.done) {}
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
