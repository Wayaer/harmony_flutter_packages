// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'package:shared_preferences_harmonyos/src/messages.g.dart';
import 'package:shared_preferences_harmonyos/src/shared_preferences_async_ohos.dart';
import 'package:shared_preferences_harmonyos/src/strings.dart';

class SharedPreferencesOhos extends SharedPreferencesStorePlatform {
  SharedPreferencesOhos({@visibleForTesting SharedPreferencesApi? api}) : api = api ?? SharedPreferencesApi();

  @visibleForTesting
  final SharedPreferencesApi api;

  static void registerWith() {
    SharedPreferencesStorePlatform.instance = SharedPreferencesOhos();
    // 同一包内包含两个插件时的临时处理方式。
    SharedPreferencesAsyncOhos.registerWith();
  }

  static const String _defaultPrefix = 'flutter.';

  @override
  Future<bool> remove(String key) async {
    return api.remove(key);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    switch (valueType) {
      case 'String':
        return api.setString(key, value as String);
      case 'Bool':
        return api.setBool(key, value as bool);
      case 'Int':
        return api.setInt(key, value as int);
      case 'Double':
        return api.setDouble(key, value as double);
      case 'StringList':
        return api.setEncodedStringList(key, '$jsonListPrefix${jsonEncode(value)}');
    }
    // TODO(tarrinneal): 与各平台统一改为抛出 ArgumentError。
    throw PlatformException(code: 'InvalidOperation', message: '"$valueType" is not a supported type.');
  }

  @override
  Future<bool> clear() async {
    return clearWithParameters(ClearParameters(filter: PreferencesFilter(prefix: _defaultPrefix)));
  }

  @override
  Future<bool> clearWithPrefix(String prefix) async {
    return clearWithParameters(ClearParameters(filter: PreferencesFilter(prefix: prefix)));
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    final PreferencesFilter filter = parameters.filter;
    return api.clear(filter.prefix, filter.allowList?.toList());
  }

  @override
  Future<Map<String, Object>> getAll() async {
    return getAllWithParameters(GetAllParameters(filter: PreferencesFilter(prefix: _defaultPrefix)));
  }

  @override
  Future<Map<String, Object>> getAllWithPrefix(String prefix) async {
    return getAllWithParameters(GetAllParameters(filter: PreferencesFilter(prefix: prefix)));
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) async {
    final PreferencesFilter filter = parameters.filter;
    final Map<String?, Object?> data = await api.getAll(filter.prefix, filter.allowList?.toList());
    final Map<String, Object> result = <String, Object>{};
    data.forEach((String? key, Object? value) {
      if (key == null || value == null) {
        return;
      }
      result[key] = value is String && value.startsWith(jsonListPrefix)
          ? (jsonDecode(value.substring(jsonListPrefix.length)) as List<dynamic>).cast<String>().toList()
          : value;
    });
    return result;
  }
}
