import fs from '@ohos.file.fs';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import {
  Result,
  FileTypes,
  FileResponse,
  FileSelectorApiCodec,
  FileSelectorNativeException,
  FileSelectorExceptionCode,
  FILE_SELECTOR_EXCEPTION_PLACEHOLDER_PATH,
  wrapError
} from './GeneratedFileSelectorApi'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import common from '@ohos.app.ability.common';
import { directoryPicker, filePicker, fileSaver, getMimeTypeFromPath } from './FileSelectorUtil'

const TAG = "FileSelectorApiImpl";

class PathTraversalException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'PathTraversalException';
  }
}

class FileContent {
  mimeType: string;
  size: number;
  byteArray: Uint8Array;

  constructor(mimeType: string, size: number, byteArray: Uint8Array) {
    this.mimeType = mimeType;
    this.size = size;
    this.byteArray = byteArray;
  }
}

function sanitizeFileName(displayName: string): string {
  const badCharacters: Array<string> = ['..', '/'];
  const segments: Array<string> = displayName.split('/');
  let fileName: string = segments[segments.length - 1];
  // 与 Android FileUtils.sanitizeFilename 保持一致，使用字符串替换而非正则。
  for (const suspString of badCharacters) {
    fileName = fileName.split(suspString).join('_');
  }
  return fileName;
}

function verifyPathWithinDirectory(filePath: string, expectedDir: string): void {
  if (filePath.indexOf('..') >= 0) {
    throw new PathTraversalException(
      'Trying to open path outside of the expected directory. File: ' + filePath +
      ' was expected to be within directory: ' + expectedDir + '.'
    );
  }
  if (!filePath.startsWith(expectedDir)) {
    throw new PathTraversalException(
      'Trying to open path outside of the expected directory. File: ' + filePath +
      ' was expected to be within directory: ' + expectedDir + '.'
    );
  }
}

export class FileSelectorApiImpl {
  binding: AbilityPluginBinding;

  constructor(binding: AbilityPluginBinding) {
    this.binding = binding;
  }

  openFileWithExtensions(initialDirectory: string, allowedTypes: FileTypes, result: Result<FileResponse>): void {
    Log.d(TAG, 'openFile types:' + allowedTypes.extensions + ' dir:' + initialDirectory)
    filePicker(initialDirectory, allowedTypes, 1).then(async (filePickerResult: ESObject) => {
      if (filePickerResult == undefined) {
        Log.i(TAG, 'filePicker cancelled or no file selected');
        result.success(null);
        return;
      }
      const uris = filePickerResult as string[];
      if (uris.length === 0) {
        Log.i(TAG, 'filePicker cancelled with empty selection');
        result.success(null);
        return;
      }
      try {
        const file: FileResponse | null =
          await FileSelectorApiImpl.buildFileResponseFromSelectedUri(uris[0], () => this.getUrisForPaths([uris[0]]));
        if (file == null) {
          result.error(new Error('Failed to read file: ' + uris[0]));
          return;
        }
        result.success(file);
      } catch (err) {
        Log.e(TAG, 'Failed to prepare selected file: ' + JSON.stringify(err));
        result.error(err instanceof Error ? err : new Error('Failed to prepare selected file.'));
      }
    }).catch((err: ESObject) => {
      Log.e(TAG, 'filePicker failed with err: ' + JSON.stringify(err));
      result.error(new Error('Failed to open file picker.'));
    });
  }

  openFilesWithExtensions(initialDirectory: string, allowedTypes: FileTypes, result: Result<Array<FileResponse>>): void {
    Log.d(TAG, 'openFiles mimeTypes:' + allowedTypes.mimeTypes
      + ' extensions:' + allowedTypes.extensions + ' dir:' + initialDirectory);

    filePicker(initialDirectory, allowedTypes, 100).then(async (filePickerResult: ESObject) => {
      if (filePickerResult == undefined) {
        Log.i(TAG, 'filePicker cancelled or no files selected');
        result.success([]);
        return;
      }
      const uris = filePickerResult as string[];
      if (uris.length === 0) {
        Log.i(TAG, 'filePicker cancelled with empty selection');
        result.success([]);
        return;
      }
      try {
        const files: Array<FileResponse> = [];
        for (let i = 0; i < uris.length; i++) {
          const uri: string = uris[i];
          const file: FileResponse | null =
            await FileSelectorApiImpl.buildFileResponseFromSelectedUri(uri, () => this.getUrisForPaths([uri]));
          if (file == null) {
            result.error(new Error('Failed to read file: ' + uri));
            return;
          }
          files.push(file);
        }
        Log.i(TAG, 'filePicker select files successfully, count: ' + files.length);
        result.success(files);
      } catch (err) {
        Log.e(TAG, 'filePicker select files failed with err: ' + JSON.stringify(err));
        result.error(err instanceof Error ? err : new Error('Failed to read selected files.'));
      }
    }).catch((err: ESObject) => {
      Log.e(TAG, 'filePicker failed with err: ' + JSON.stringify(err));
      result.error(new Error('Failed to open file picker.'));
    });
  }

  getContext(): common.UIAbilityContext {
    return this.binding.getAbility().context;
  }

  getDirectoryPath(initialDirectory: string, result: Result<string>): void {
    Log.d(TAG, 'getDirectoryPath dir:' + initialDirectory);
    directoryPicker(initialDirectory, false).then((pickerResult: ESObject) => {
      const uris = pickerResult as string[];
      if (uris == undefined || uris.length === 0) {
        result.success(null);
        return;
      }
      result.success(uris[0]);
    }).catch((err: ESObject) => {
      Log.e(TAG, 'getDirectoryPath failed with err: ' + JSON.stringify(err));
      result.error(new Error('Failed to open directory picker.'));
    });
  }

  getDirectoryPaths(initialDirectory: string, result: Result<Array<string>>): void {
    Log.d(TAG, 'getDirectoryPaths dir:' + initialDirectory);
    directoryPicker(initialDirectory, true).then((pickerResult: ESObject) => {
      const uris = pickerResult as string[];
      result.success(uris == undefined ? [] : uris);
    }).catch((err: ESObject) => {
      Log.e(TAG, 'getDirectoryPaths failed with err: ' + JSON.stringify(err));
      result.error(new Error('Failed to open directory picker.'));
    });
  }

  getSavePath(initialDirectory: string, suggestedName: string, allowedTypes: FileTypes,
    result: Result<string>): void {
    Log.d(TAG, 'getSavePath dir:' + initialDirectory + ' name:' + suggestedName);
    fileSaver(initialDirectory, suggestedName, allowedTypes).then((pickerResult: ESObject) => {
      const uris = pickerResult as string[];
      if (uris == undefined || uris.length === 0) {
        result.success(null);
        return;
      }
      result.success(FileSelectorApiImpl.resolveSavedPath(uris[0]));
    }).catch((err: ESObject) => {
      Log.e(TAG, 'getSavePath failed with err: ' + JSON.stringify(err));
      result.error(new Error('Failed to open save picker.'));
    });
  }

  /**
   * picker 返回的通常是 file://docs/... 形式的 URI。优先使用 fs 解析出的真实路径，
   * 无法解析时退回 URI，保证 Dart 侧总能拿到一个可用于后续操作的位置。
   */
  static resolveSavedPath(uri: string): string {
    try {
      const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_WRITE);
      try {
        const path: string = file.path;
        if (path != null && path.length > 0) {
          return path;
        }
      } finally {
        fs.closeSync(file);
      }
    } catch (err) {
      Log.w(TAG, 'resolveSavedPath failed, fallback to uri: ' + JSON.stringify(err));
    }
    return uri;
  }

  async getUrisForPaths(paths: string[]): Promise<Array<string>> {
    Log.i(TAG, 'getUrisForPaths, count: ' + paths.length);
    const uris: Array<string> = [];
    if (paths.length === 0) {
      return uris;
    }
    const folder: string = this.getContext().cacheDir;
    if (!fs.accessSync(folder)) {
      fs.mkdirSync(folder);
    }
    try {
      for (let i = 0; i < paths.length; i++) {
        const path: string = paths[i];
        const oldFile: fs.File = fs.openSync(path);
        try {
          const sanitizedName: string = sanitizeFileName(oldFile.name);
          // 与 Android 的 {cacheDir}/{uuid}/{fileName} 结构保持一致，使用系统接口创建唯一目录。
          const targetDir: string = fs.mkdtempSync(folder + '/file_selector-XXXXXX');
          const newFile: string = targetDir + '/' + sanitizedName;
          verifyPathWithinDirectory(newFile, targetDir);
          fs.copyFileSync(oldFile.fd, newFile);
          uris.push(newFile);
        } finally {
          fs.closeSync(oldFile);
        }
      }
      return uris;
    } catch (err) {
      for (let i = 0; i < uris.length; i++) {
        const copiedUri: string = uris[i];
        try {
          fs.unlinkSync(copiedUri);
        } catch (cleanupErr) {
          Log.w(TAG, 'Failed to cleanup copied file: ' + copiedUri + ', err: ' + JSON.stringify(cleanupErr));
        }
      }
      if (err instanceof PathTraversalException) {
        throw err;
      }
      Log.e(TAG, 'Failed to getUrisForPaths: ' + JSON.stringify(err));
      throw new Error('Failed to copy selected files to cache directory.');
    }
  }

  static getCodec(): MessageCodec<ESObject> {
    return FileSelectorApiCodec.INSTANCE;
  }

  setup(binaryMessenger: BinaryMessenger, abilityPluginBinding: AbilityPluginBinding): void {
    let api = this;
    {
      this.binding = abilityPluginBinding;
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.openFile", FileSelectorApiImpl.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const initialDirectoryArg = args[0] as string;
          const allowedTypesArg = args[1] as FileTypes;
          const resultCallback: Result<FileResponse> = new ResultBuilder((result: FileResponse | null): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          }, (error: Error): void => {
            const wrappedError: Array<ESObject> = wrapError(error);
            reply.reply(wrappedError);
          })
          api.openFileWithExtensions(initialDirectoryArg, allowedTypesArg, resultCallback);
        }
      });
    }
    {
      this.binding = abilityPluginBinding;
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.openFiles", FileSelectorApiImpl.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const initialDirectoryArg = args[0] as string;
          const allowedTypesArg = args[1] as FileTypes;
          const resultCallback: Result<Array<FileResponse>> =
            new ResultsBuilder((result: Array<FileResponse> | null): void => {
              wrapped.push(result);
              reply.reply(wrapped);
            }, (error: Error): void => {
              const wrappedError: Array<ESObject> = wrapError(error);
              reply.reply(wrappedError);
            })
          api.openFilesWithExtensions(initialDirectoryArg, allowedTypesArg, resultCallback);
        }
      });
    }
    {
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.getDirectoryPath", FileSelectorApiImpl.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const initialDirectoryArg = args[0] as string;
          const resultCallback: Result<string> = new StringResultBuilder((result: string | null): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          }, (error: Error): void => {
            const wrappedError: Array<ESObject> = wrapError(error);
            reply.reply(wrappedError);
          })
          api.getDirectoryPath(initialDirectoryArg, resultCallback);
        }
      });
    }
    {
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.getDirectoryPaths", FileSelectorApiImpl.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const initialDirectoryArg = args[0] as string;
          const resultCallback: Result<Array<string>> =
            new StringArrayResultBuilder((result: Array<string> | null): void => {
              wrapped.push(result);
              reply.reply(wrapped);
            }, (error: Error): void => {
              const wrappedError: Array<ESObject> = wrapError(error);
              reply.reply(wrappedError);
            })
          api.getDirectoryPaths(initialDirectoryArg, resultCallback);
        }
      });
    }
    {
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.getSavePath", FileSelectorApiImpl.getCodec());
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const initialDirectoryArg = args[0] as string;
          const suggestedNameArg = args[1] as string;
          const allowedTypesArg = args[2] as FileTypes;
          const resultCallback: Result<string> = new StringResultBuilder((result: string | null): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          }, (error: Error): void => {
            const wrappedError: Array<ESObject> = wrapError(error);
            reply.reply(wrappedError);
          })
          api.getSavePath(initialDirectoryArg, suggestedNameArg, allowedTypesArg, resultCallback);
        }
      });
    }
  }

  static readFileContent(uri: string, name: string): FileContent | null {
    try {
      const mimeType: string = getMimeTypeFromPath(uri, name);
      const file: fs.File = fs.openSync(uri);
      try {
        const stat: fs.Stat = fs.statSync(file.fd);
        const size: number = stat.size;
        if (size < 0) {
          Log.w(TAG, 'File size is unknown or invalid: ' + size);
          return null;
        }
        const buffer: ArrayBuffer = new ArrayBuffer(size);
        fs.readSync(file.fd, buffer, { offset: 0, length: size });
        const byteArray: Uint8Array = new Uint8Array(buffer);
        return new FileContent(mimeType, size, byteArray);
      } finally {
        fs.closeSync(file);
      }
    } catch (err) {
      Log.e(TAG, 'Failed to read file: ' + JSON.stringify(err));
      return null;
    }
  }

  static async buildFileResponseFromSelectedUri(
    selectedUri: string,
    copyToCache: () => Promise<Array<string>>
  ): Promise<FileResponse | null> {
    const fileName: string = selectedUri.substring(selectedUri.lastIndexOf('/') + 1);
    const content: FileContent | null = FileSelectorApiImpl.readFileContent(selectedUri, fileName);
    if (content == null) {
      return null;
    }

    // 与 Android 保持一致：只有复制到缓存成功后才设置 path。
    let responsePath: string = '';
    let nativeException: FileSelectorNativeException | null = null;
    try {
      const cachedUris: Array<string> = await copyToCache();
      if (cachedUris.length > 0) {
        responsePath = cachedUris[0];
      }
    } catch (err) {
      if (err instanceof PathTraversalException) {
        responsePath = FILE_SELECTOR_EXCEPTION_PLACEHOLDER_PATH;
        nativeException = new FileSelectorNativeException(
          FileSelectorExceptionCode.ILLEGAL_ARGUMENT_EXCEPTION,
          err.message
        );
      } else {
        Log.w(TAG, 'Failed to copy selected file to cache: ' + JSON.stringify(err));
        responsePath = '';
      }
    }

    return new FileResponse(
      responsePath,
      content.mimeType,
      fileName,
      content.size,
      content.byteArray,
      nativeException
    );
  }
}

class ResultBuilder {
  success: (result: FileResponse | null) => void
  error: (error: Error) => void

  constructor(success: ESObject, error: ESObject) {
    this.success = success
    this.error = error
  }
}

class ResultsBuilder {
  success: (result: Array<FileResponse> | null) => void
  error: (error: Error) => void

  constructor(success: ESObject, error: ESObject) {
    this.success = success
    this.error = error
  }
}

class StringResultBuilder {
  success: (result: string | null) => void
  error: (error: Error) => void

  constructor(success: ESObject, error: ESObject) {
    this.success = success
    this.error = error
  }
}

class StringArrayResultBuilder {
  success: (result: Array<string> | null) => void
  error: (error: Error) => void

  constructor(success: ESObject, error: ESObject) {
    this.success = success
    this.error = error
  }
}
