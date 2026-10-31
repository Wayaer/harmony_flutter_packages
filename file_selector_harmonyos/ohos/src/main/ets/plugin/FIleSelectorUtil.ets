import picker from '@ohos.file.picker';
import { FileTypes } from './GeneratedFileSelectorApi';
import { Log } from '@ohos/flutter_ohos';

const TAG = "FileSelectorUtil";

function normalizeFileSuffix(extensionType: string): string {
  return extensionType.startsWith('.') ? extensionType : '.' + extensionType;
}

/** 通配符 MIME 对应的扩展名集合 */
const IMAGE_WILDCARD_EXTENSIONS: Array<string> = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
const VIDEO_WILDCARD_EXTENSIONS: Array<string> = ['mp4', '3gp', 'webm', 'mov', 'mkv'];
const AUDIO_WILDCARD_EXTENSIONS: Array<string> = ['mp3', 'wav', 'aac', 'flac'];

/** 文件后缀与 MIME 的双向映射表 */
const MIME_TO_EXTENSIONS: Map<string, Array<string>> = new Map<string, Array<string>>([
  ['image/*', IMAGE_WILDCARD_EXTENSIONS],
  ['video/*', VIDEO_WILDCARD_EXTENSIONS],
  ['audio/*', AUDIO_WILDCARD_EXTENSIONS],
  ['image/jpeg', ['jpg', 'jpeg']],
  ['image/png', ['png']],
  ['image/gif', ['gif']],
  ['image/webp', ['webp']],
  ['image/bmp', ['bmp']],
  ['image/svg+xml', ['svg']],
  ['video/mp4', ['mp4']],
  ['video/3gpp', ['3gp']],
  ['video/webm', ['webm']],
  ['video/quicktime', ['mov']],
  ['video/x-matroska', ['mkv']],
  ['audio/mpeg', ['mp3']],
  ['audio/x-wav', ['wav']],
  ['audio/aac', ['aac']],
  ['audio/flac', ['flac']],
  ['application/pdf', ['pdf']],
  ['application/msword', ['doc']],
  ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', ['docx']],
  ['application/vnd.ms-excel', ['xls']],
  ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', ['xlsx']],
  ['application/vnd.ms-powerpoint', ['ppt']],
  ['application/vnd.openxmlformats-officedocument.presentationml.presentation', ['pptx']],
  ['text/plain', ['txt', 'log']],
  ['text/csv', ['csv']],
  ['text/html', ['html', 'htm']],
  ['text/xml', ['xml']],
  ['application/json', ['json']],
  ['application/xml', ['xml']],
  ['application/zip', ['zip']],
  ['application/gzip', ['gz']],
  ['application/x-tar', ['tar']],
  ['application/x-7z-compressed', ['7z']],
  ['application/x-rar-compressed', ['rar']],
]);

const EXTENSION_TO_MIME: Map<string, string> = buildExtensionToMimeMap();

function buildExtensionToMimeMap(): Map<string, string> {
  const map: Map<string, string> = new Map<string, string>();
  MIME_TO_EXTENSIONS.forEach((exts: Array<string>, mime: string): void => {
    if (mime.endsWith('/*')) {
      return;
    }
    for (let ext of exts) {
      map.set(ext.toLowerCase(), mime);
    }
  });
  MIME_TO_EXTENSIONS.forEach((exts: Array<string>, mime: string): void => {
    if (!mime.endsWith('/*')) {
      return;
    }
    for (let ext of exts) {
      const key: string = ext.toLowerCase();
      if (!map.has(key)) {
        map.set(key, mime);
      }
    }
  });
  return map;
}

function extractFileExtension(pathOrName: string): string {
  const baseName: string = pathOrName.substring(pathOrName.lastIndexOf('/') + 1);
  const queryIndex: number = baseName.indexOf('?');
  const name: string = queryIndex >= 0 ? baseName.substring(0, queryIndex) : baseName;
  const dotIndex: number = name.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex === name.length - 1) {
    return '';
  }
  return name.substring(dotIndex + 1).toLowerCase();
}

export function getMimeTypeFromPath(path: string, fileName?: string): string {
  const source: string = (fileName != null && fileName.length > 0) ? fileName : path;
  const extension: string = extractFileExtension(source);
  if (extension.length === 0) {
    return 'application/octet-stream';
  }
  const mime: string | undefined = EXTENSION_TO_MIME.get(extension);
  if (mime != null) {
    return mime;
  }
  Log.w(TAG, 'Unknown extension for MIME lookup: ' + extension);
  return 'application/octet-stream';
}

export function tryConvertMimetypesToExtensions(mimeTypes: Array<string> | null): Array<string> {
  let result: Array<string> = [];
  if (mimeTypes == null || mimeTypes.length === 0) {
    return result;
  }
  let extSet: Set<string> = new Set<string>();
  for (let mime of mimeTypes) {
    let exts: Array<string> | undefined = MIME_TO_EXTENSIONS.get(mime);
    if (exts != null) {
      for (let ext of exts) {
        extSet.add(ext);
      }
    } else {
      Log.w(TAG, '[mimeTypes] MIME type "' + mime + '" is NOT in the built-in mapping on OpenHarmony. ');
    }
  }
  extSet.forEach((value: string): void => {
    result.push(value);
  });
  return result;
}

export function resolveFileSuffixes(allowedTypes: FileTypes): Array<string> {
  const fileSuffixSet: Set<string> = new Set<string>();
  if (allowedTypes.extensions != null) {
    for (let extensionType of allowedTypes.extensions) {
      fileSuffixSet.add(normalizeFileSuffix(extensionType));
    }
  }
  if (allowedTypes.mimeTypes != null && allowedTypes.mimeTypes.length > 0) {
    const derived: Array<string> = tryConvertMimetypesToExtensions(allowedTypes.mimeTypes);
    for (let extensionType of derived) {
      fileSuffixSet.add(normalizeFileSuffix(extensionType));
    }
  }
  return Array.from(fileSuffixSet);
}

export async function filePicker(initialDirectory: string, allowedTypes: FileTypes, selectorNumber?: number): Promise<ESObject> {
  let documentSelectOptions = new picker.DocumentSelectOptions();
  if (initialDirectory != null && initialDirectory.length > 0) {
    documentSelectOptions.defaultFilePathUri = initialDirectory;
  }
  if (selectorNumber != undefined) {
    documentSelectOptions.maxSelectNumber = selectorNumber;
  }
  // 无过滤条件时不设置 fileSuffixFilters，表示允许所有类型。
  const suffixes: Array<string> = resolveFileSuffixes(allowedTypes);
  if (suffixes.length > 0) {
    documentSelectOptions.fileSuffixFilters = suffixes;
  }
  try {
    const documentViewPicker = new picker.DocumentViewPicker();
    let documentSelectResult = await documentViewPicker.select(documentSelectOptions);
    Log.i(TAG, "documentViewPicker select file succeed.");
    return new Promise<ESObject>((resolve) => {
      resolve(documentSelectResult)
    });
  } catch (err) {
    Log.e(TAG, "documentViewPicker select file failed: " + JSON.stringify(err));
    return new Promise<ESObject>((resolve, reject) => {
      reject(err)
    });
  }
}

/** 目录选择。multiple 为 true 时允许多选，否则只允许选择一个目录。 */
export async function directoryPicker(initialDirectory: string, multiple: boolean): Promise<ESObject> {
  const options = new picker.DocumentSelectOptions();
  options.selectMode = picker.DocumentSelectMode.FOLDER;
  if (initialDirectory != null && initialDirectory.length > 0) {
    options.defaultFilePathUri = initialDirectory;
  }
  if (multiple) {
    options.maxSelectNumber = 100;
  }
  try {
    const documentViewPicker = new picker.DocumentViewPicker();
    const result = await documentViewPicker.select(options);
    Log.i(TAG, "documentViewPicker select directory succeed.");
    return new Promise<ESObject>((resolve) => {
      resolve(result);
    });
  } catch (err) {
    Log.e(TAG, "documentViewPicker select directory failed: " + JSON.stringify(err));
    return new Promise<ESObject>((resolve, reject) => {
      reject(err);
    });
  }
}

/** 另存为。返回用户选择的文件 URI 列表（picker 会预创建空文件）。 */
export async function fileSaver(initialDirectory: string, suggestedName: string,
  allowedTypes: FileTypes): Promise<ESObject> {
  const options = new picker.DocumentSaveOptions();
  if (initialDirectory != null && initialDirectory.length > 0) {
    options.defaultFilePathUri = initialDirectory;
  }
  if (suggestedName != null && suggestedName.length > 0) {
    options.newFileNames = [suggestedName];
  }
  const suffixes: Array<string> = resolveFileSuffixes(allowedTypes);
  if (suffixes.length > 0) {
    options.fileSuffixChoices = suffixes;
  }
  try {
    const documentViewPicker = new picker.DocumentViewPicker();
    const result = await documentViewPicker.save(options);
    Log.i(TAG, "documentViewPicker save succeed.");
    return new Promise<ESObject>((resolve) => {
      resolve(result);
    });
  } catch (err) {
    Log.e(TAG, "documentViewPicker save failed: " + JSON.stringify(err));
    return new Promise<ESObject>((resolve, reject) => {
      reject(err);
    });
  }
}
