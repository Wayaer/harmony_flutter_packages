// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

class VideoPlayerOhosChannel {
  static final MethodChannel _channel = MethodChannel('plugins.flutter.io/video_player_ohos');

  static Future<int> getFileFdByPath(String path) async {
    final int? fileFd = await _channel.invokeMethod<int>('getFileFdByPath', <String, String>{'filePath': path});
    if (fileFd == null || fileFd < 0) {
      throw StateError('Failed to open a file descriptor for "$path".');
    }
    return fileFd;
  }
}
