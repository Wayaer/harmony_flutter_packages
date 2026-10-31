// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on SharedPreferencesListEncoder.java originally written by
// Copyright 2013 The Flutter Authors.

export interface SharedPreferencesListEncoder {
  encode(list: Array<string>): string;
  decode(listString: string): ESObject;
}