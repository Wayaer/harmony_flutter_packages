// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

S withWeakReferenceTo<T extends Object, S extends Object>(
  T reference,
  S Function(WeakReference<T> weakReference) onCreate,
) {
  final weakReference = WeakReference<T>(reference);
  return onCreate(weakReference);
}
