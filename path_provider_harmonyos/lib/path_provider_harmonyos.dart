import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'src/messages.g.dart' as messages;

export 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// The OHOS implementation of [PathProviderPlatform].
class PathProviderHarmonyOS extends PathProviderPlatform {
  final messages.PathProviderApi _api = messages.PathProviderApi();

  /// Registers this class as the default instance of [PathProviderPlatform].
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderHarmonyOS();
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
    throw UnsupportedError('getLibraryPath is not supported on OHOS');
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
  Future<List<String>?> getExternalStoragePaths(
      {StorageDirectory? type}) async {
    return _getExternalStoragePaths(type: type);
  }

  @override
  Future<String?> getDownloadsPath() async {
    final List<String> paths =
    await _getExternalStoragePaths(type: StorageDirectory.downloads);
    return paths.isEmpty ? null : paths.first;
  }

  Future<List<String>> _getExternalStoragePaths(
      {StorageDirectory? type}) async {
    return (await _api.getExternalStoragePaths(type)).cast<String>();
  }
}
