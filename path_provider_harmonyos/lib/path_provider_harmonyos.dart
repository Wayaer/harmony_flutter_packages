import 'package:flutter/foundation.dart';
import 'package:path_provider_harmonyos/src/messages.g.dart' as messages;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

export 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class PathProviderOhos extends PathProviderPlatform {
  PathProviderOhos({@visibleForTesting messages.PathProviderApi? api}) : _api = api ?? messages.PathProviderApi();

  final messages.PathProviderApi _api;

  static void registerWith() {
    PathProviderPlatform.instance = PathProviderOhos();
  }

  @override
  Future<String?> getTemporaryPath() {
    return _api.getTemporaryPath();
  }

  @override
  Future<String?> getApplicationSupportPath() {
    return _api.getApplicationSupportPath();
  }

  @override
  Future<String?> getLibraryPath() {
    throw UnsupportedError('getLibraryPath is not supported on HarmonyOS');
  }

  @override
  Future<String?> getApplicationDocumentsPath() {
    return _api.getApplicationDocumentsPath();
  }

  @override
  Future<String?> getApplicationCachePath() {
    return _api.getApplicationCachePath();
  }

  @override
  Future<String?> getExternalStoragePath() {
    return _api.getExternalStoragePath();
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return (await _api.getExternalCachePaths()).cast<String>();
  }

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    return _getExternalStoragePaths(type: type);
  }

  @override
  Future<String?> getDownloadsPath() async {
    final paths = await _getExternalStoragePaths(type: StorageDirectory.downloads);
    return paths.isEmpty ? null : paths.first;
  }

  Future<List<String>> _getExternalStoragePaths({StorageDirectory? type}) async {
    return (await _api.getExternalStoragePaths(_convertStorageDirectory(type))).cast<String>();
  }

  messages.StorageDirectory _convertStorageDirectory(StorageDirectory? directory) {
    switch (directory) {
      case null:
        return messages.StorageDirectory.root;
      case StorageDirectory.music:
        return messages.StorageDirectory.music;
      case StorageDirectory.podcasts:
        return messages.StorageDirectory.podcasts;
      case StorageDirectory.ringtones:
        return messages.StorageDirectory.ringtones;
      case StorageDirectory.alarms:
        return messages.StorageDirectory.alarms;
      case StorageDirectory.notifications:
        return messages.StorageDirectory.notifications;
      case StorageDirectory.pictures:
        return messages.StorageDirectory.pictures;
      case StorageDirectory.movies:
        return messages.StorageDirectory.movies;
      case StorageDirectory.downloads:
        return messages.StorageDirectory.downloads;
      case StorageDirectory.dcim:
        return messages.StorageDirectory.dcim;
      case StorageDirectory.documents:
        return messages.StorageDirectory.documents;
    }
  }
}
