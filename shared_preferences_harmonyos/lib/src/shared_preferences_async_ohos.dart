// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'package:shared_preferences_harmonyos/src/messages_async.g.dart';
import 'package:shared_preferences_harmonyos/src/strings.dart';

base class SharedPreferencesAsyncOhos extends SharedPreferencesAsyncPlatform {
  SharedPreferencesAsyncOhos({
    @visibleForTesting SharedPreferencesAsyncApi? dataStoreApi,
    @visibleForTesting SharedPreferencesAsyncApi? sharedPreferencesApi,
  }) : _dataStoreApi = dataStoreApi ?? SharedPreferencesAsyncApi(messageChannelSuffix: 'data_store'),
       _sharedPreferencesApi =
           sharedPreferencesApi ?? SharedPreferencesAsyncApi(messageChannelSuffix: 'shared_preferences');

  final SharedPreferencesAsyncApi _dataStoreApi;
  final SharedPreferencesAsyncApi _sharedPreferencesApi;

  static void registerWith() {
    SharedPreferencesAsyncPlatform.instance = SharedPreferencesAsyncOhos();
  }

  @visibleForTesting
  SharedPreferencesPigeonOptions convertOptionsToPigeonOptions(SharedPreferencesOptions options) {
    if (options is SharedPreferencesAsyncOhosOptions) {
      return SharedPreferencesPigeonOptions(
        fileName: options.originalSharedPreferencesOptions?.fileName,
        useDataStore: options.backend == SharedPreferencesOhosBackendLibrary.DataStore,
      );
    }
    return SharedPreferencesPigeonOptions();
  }

  @visibleForTesting
  SharedPreferencesAsyncApi getApiForBackend(SharedPreferencesPigeonOptions options) {
    return options.useDataStore ? _dataStoreApi : _sharedPreferencesApi;
  }

  @override
  Future<Set<String>> getKeys(GetPreferencesParameters parameters, SharedPreferencesOptions options) async {
    final PreferencesFilters filter = parameters.filter;
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return (await api.getKeys(filter.allowList?.toList(), pigeonOptions)).toSet();
  }

  @override
  Future<void> setString(String key, String value, SharedPreferencesOptions options) async {
    if (value.startsWith(listPrefix)) {
      throw ArgumentError('StorageError: This string cannot be stored as it clashes with special identifier prefixes');
    }
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);

    return api.setString(key, value, pigeonOptions);
  }

  @override
  Future<void> setInt(String key, int value, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return api.setInt(key, value, pigeonOptions);
  }

  @override
  Future<void> setDouble(String key, double value, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return api.setDouble(key, value, pigeonOptions);
  }

  @override
  Future<void> setBool(String key, bool value, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return api.setBool(key, value, pigeonOptions);
  }

  @override
  Future<void> setStringList(String key, List<String> value, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    final String stringValue = '$jsonListPrefix${jsonEncode(value)}';
    return api.setString(key, stringValue, pigeonOptions);
  }

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return _convertKnownExceptions<String>(() async => api.getString(key, pigeonOptions));
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return _convertKnownExceptions<bool>(() async => api.getBool(key, pigeonOptions));
  }

  @override
  Future<double?> getDouble(String key, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return _convertKnownExceptions<double>(() async => api.getDouble(key, pigeonOptions));
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return _convertKnownExceptions<int>(() async => api.getInt(key, pigeonOptions));
  }

  @override
  Future<List<String>?> getStringList(String key, SharedPreferencesOptions options) async {
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    // 请求以 JSON 编码的字符串列表。
    final StringListResult? result = await _convertKnownExceptions<StringListResult?>(
      () async => api.getStringList(key, pigeonOptions),
    );
    if (result == null) {
      return null;
    }
    switch (result.type) {
      case StringListLookupResultType.jsonEncoded:
        // 该类型下值必定存在，强制解包是安全的。
        final String jsonEncodedStringList = result.jsonEncodedValue!;
        final String jsonEncodedString = jsonEncodedStringList.substring(jsonListPrefix.length);
        try {
          final List<String> decodedList = (jsonDecode(jsonEncodedString) as List<dynamic>).cast<String>();
          return decodedList;
        } catch (e) {
          throw TypeError();
        }
      case StringListLookupResultType.platformEncoded:
        final List<String>? stringList = await _convertKnownExceptions<List<String>?>(
          () async => api.getPlatformEncodedStringList(key, pigeonOptions),
        );
        return stringList?.cast<String>().toList();
      case StringListLookupResultType.unexpectedString:
        throw TypeError();
    }
  }

  Future<T?> _convertKnownExceptions<T>(Future<T?> Function() method) async {
    try {
      final T? value = await method();
      return value;
    } on PlatformException catch (e) {
      if (e.code == 'ClassCastException') {
        throw TypeError();
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> clear(ClearPreferencesParameters parameters, SharedPreferencesOptions options) async {
    final PreferencesFilters filter = parameters.filter;
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    return api.clear(filter.allowList?.toList(), pigeonOptions);
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final PreferencesFilters filter = parameters.filter;
    final SharedPreferencesPigeonOptions pigeonOptions = convertOptionsToPigeonOptions(options);
    final SharedPreferencesAsyncApi api = getApiForBackend(pigeonOptions);
    final Map<String?, Object?> data = await api.getAll(filter.allowList?.toList(), pigeonOptions);
    final Map<String, Object> result = <String, Object>{};
    data.forEach((String? key, Object? value) {
      if (key == null || value == null) {
        return;
      }
      result[key] = value is String && value.startsWith(jsonListPrefix)
          ? (jsonDecode(value.substring(jsonListPrefix.length)) as List<dynamic>).cast<String>()
          : value;
    });
    return result;
  }
}

enum SharedPreferencesOhosBackendLibrary { DataStore, SharedPreferences }

class SharedPreferencesAsyncOhosOptions extends SharedPreferencesOptions {
  const SharedPreferencesAsyncOhosOptions({
    this.backend = SharedPreferencesOhosBackendLibrary.DataStore,
    this.originalSharedPreferencesOptions,
  });

  final SharedPreferencesOhosBackendLibrary backend;

  final OhosSharedPreferencesStoreOptions? originalSharedPreferencesOptions;
}

class OhosSharedPreferencesStoreOptions {
  const OhosSharedPreferencesStoreOptions({this.fileName});

  final String? fileName;
}
