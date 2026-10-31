import 'package:file_selector_harmonyos/src/file_selector_api.g.dart';
import 'package:file_selector_harmonyos/src/types/native_illegal_argument_exception.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/foundation.dart';

class FileSelectorOhos extends FileSelectorPlatform {
  FileSelectorOhos({@visibleForTesting FileSelectorApi? api}) : _api = api ?? FileSelectorApi();

  final FileSelectorApi _api;

  static void registerWith() {
    FileSelectorPlatform.instance = FileSelectorOhos();
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final file = await _api.openFile(initialDirectory, _fileTypesFromTypeGroups(acceptedTypeGroups));
    return file == null ? null : _xFileFromFileResponse(file);
  }

  @override
  Future<List<XFile>> openFiles({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final files = await _api.openFiles(initialDirectory, _fileTypesFromTypeGroups(acceptedTypeGroups));
    return files.whereType<FileResponse>().map<XFile>(_xFileFromFileResponse).toList();
  }

  @override
  Future<String?> getDirectoryPath({String? initialDirectory, String? confirmButtonText}) {
    return _api.getDirectoryPath(initialDirectory);
  }

  @override
  Future<List<String>> getDirectoryPaths({String? initialDirectory, String? confirmButtonText}) {
    return _api.getDirectoryPaths(initialDirectory);
  }

  @override
  Future<String?> getSavePath({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? suggestedName,
    String? confirmButtonText,
  }) {
    return _api.getSavePath(initialDirectory, suggestedName, _fileTypesFromTypeGroups(acceptedTypeGroups));
  }

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    final String? path = await getSavePath(
      acceptedTypeGroups: acceptedTypeGroups,
      initialDirectory: options.initialDirectory,
      suggestedName: options.suggestedName,
      confirmButtonText: options.confirmButtonText,
    );
    return path == null ? null : FileSaveLocation(path);
  }

  XFile _xFileFromFileResponse(FileResponse file) {
    final exception = file.fileSelectorNativeException;
    if (exception != null) {
      _resolveErrorCodeAndMaybeThrow(exception);
    }
    return XFile.fromData(
      file.bytes,
      // XFile 不使用 name 参数，XFile.name 由 path 解析得到。
      name: file.name,
      length: file.size,
      mimeType: file.mimeType,
      path: file.path,
    );
  }

  FileTypes _fileTypesFromTypeGroups(List<XTypeGroup>? typeGroups) {
    if (typeGroups == null) {
      return FileTypes(extensions: <String>[], mimeTypes: <String>[]);
    }

    final mimeTypes = <String>{};
    final extensions = <String>{};

    for (final group in typeGroups) {
      if (!group.allowsAny && group.mimeTypes == null && group.extensions == null) {
        throw ArgumentError(
          'Provided type group $group does not allow all files, but does not '
          'set any supported filter categories. At least one of '
          '"extensions" or "mimeTypes" must be non-empty.',
        );
      }

      mimeTypes.addAll(group.mimeTypes ?? <String>{});
      extensions.addAll(group.extensions ?? <String>{});
    }

    return FileTypes(mimeTypes: mimeTypes.toList(), extensions: extensions.toList());
  }

  void _resolveErrorCodeAndMaybeThrow(FileSelectorNativeException exception) {
    switch (exception.fileSelectorExceptionCode) {
      case FileSelectorExceptionCode.illegalArgumentException:
        throw NativeIllegalArgumentException(exception.message);
      case FileSelectorExceptionCode.illegalStateException:
      case FileSelectorExceptionCode.ioException:
      case FileSelectorExceptionCode.securityException:
        break;
    }
  }
}
