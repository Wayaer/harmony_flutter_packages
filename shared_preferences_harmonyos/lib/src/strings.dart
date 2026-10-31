// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String listPrefix = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu';

/// Dart 侧 JSON 列表前缀。
///
/// 选用 `!` 是因为 base64 编码（[listPrefix]）不会产生该字符。
const String jsonListPrefix = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!';

const String doublePrefix = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu';

const String bigIntPrefix = 'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy';
