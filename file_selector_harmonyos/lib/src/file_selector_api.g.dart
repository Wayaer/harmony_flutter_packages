import 'dart:async';

import 'package:flutter/services.dart';

enum FileSelectorExceptionCode { securityException, ioException, illegalArgumentException, illegalStateException }

class FileSelectorNativeException {
  FileSelectorNativeException({required this.fileSelectorExceptionCode, required this.message});

  FileSelectorExceptionCode fileSelectorExceptionCode;

  String message;

  Object encode() {
    return <Object?>[fileSelectorExceptionCode.index, message];
  }

  static FileSelectorNativeException decode(Object result) {
    result as List<Object?>;
    return FileSelectorNativeException(
      fileSelectorExceptionCode: FileSelectorExceptionCode.values[result[0]! as int],
      message: result[1]! as String,
    );
  }
}

class FileResponse {
  FileResponse({
    required this.path,
    this.mimeType,
    this.name,
    required this.size,
    required this.bytes,
    this.fileSelectorNativeException,
  });

  String path;

  String? mimeType;

  String? name;

  int size;

  Uint8List bytes;

  FileSelectorNativeException? fileSelectorNativeException;

  Object encode() {
    return <Object?>[path, mimeType, name, size, bytes, fileSelectorNativeException];
  }

  static FileResponse decode(Object result) {
    result as List<Object?>;
    return FileResponse(
      path: result[0]! as String,
      mimeType: result[1] as String?,
      name: result[2] as String?,
      size: result[3]! as int,
      bytes: result[4]! as Uint8List,
      fileSelectorNativeException: result.length > 5 ? result[5] as FileSelectorNativeException? : null,
    );
  }
}

class FileTypes {
  FileTypes({required this.mimeTypes, required this.extensions});

  List<String?> mimeTypes;

  List<String?> extensions;

  Object encode() {
    return <Object?>[mimeTypes, extensions];
  }

  static FileTypes decode(Object result) {
    result as List<Object?>;
    return FileTypes(
      mimeTypes: (result[0] as List<Object?>?)!.cast<String?>(),
      extensions: (result[1] as List<Object?>?)!.cast<String?>(),
    );
  }
}

class _FileSelectorApiCodec extends StandardMessageCodec {
  const _FileSelectorApiCodec();

  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is FileResponse) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is FileTypes) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is FileSelectorNativeException) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return FileResponse.decode(readValue(buffer)!);
      case 129:
        return FileTypes.decode(readValue(buffer)!);
      case 130:
        return FileSelectorNativeException.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class FileSelectorApi {
  FileSelectorApi({BinaryMessenger? binaryMessenger}) : _binaryMessenger = binaryMessenger;

  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _FileSelectorApiCodec();

  Future<FileResponse?> openFile(String? initialDirectory, FileTypes allowedTypes) async {
    final channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.FileSelectorApi.openFile',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final replyList = await channel.send(<Object?>[initialDirectory, allowedTypes]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else {
      return replyList[0] as FileResponse?;
    }
  }

  Future<List<FileResponse?>> openFiles(String? initialDirectory, FileTypes allowedTypes) async {
    final channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.FileSelectorApi.openFiles',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final replyList = await channel.send(<Object?>[initialDirectory, allowedTypes]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as List<Object?>?)!.cast<FileResponse?>();
    }
  }

  Future<String?> getDirectoryPath(String? initialDirectory) async {
    final channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.FileSelectorApi.getDirectoryPath',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final replyList = await channel.send(<Object?>[initialDirectory]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else {
      return replyList[0] as String?;
    }
  }

  Future<List<String>> getDirectoryPaths(String? initialDirectory) async {
    final channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.FileSelectorApi.getDirectoryPaths',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final replyList = await channel.send(<Object?>[initialDirectory]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as List<Object?>?)!.cast<String>();
    }
  }

  Future<String?> getSavePath(String? initialDirectory, String? suggestedName, FileTypes allowedTypes) async {
    final channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.FileSelectorApi.getSavePath',
      codec,
      binaryMessenger: _binaryMessenger,
    );
    final replyList = await channel.send(<Object?>[initialDirectory, suggestedName, allowedTypes]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(code: 'channel-error', message: 'Unable to establish connection on channel.');
    } else if (replyList.length > 1) {
      throw PlatformException(code: replyList[0]! as String, message: replyList[1] as String?, details: replyList[2]);
    } else {
      return replyList[0] as String?;
    }
  }
}
