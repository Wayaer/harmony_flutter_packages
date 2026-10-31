// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

const NINE: number = 9;

export default class DateTimeUtil {
  getTime(): string {
    const DATETIME = new Date();
    return this.concatTime(
      DATETIME.getHours(),
      DATETIME.getMinutes(),
      DATETIME.getSeconds()
    );
  }

  getDate(): string {
    const DATETIME = new Date();
    return this.concatDate(
      DATETIME.getFullYear(),
      DATETIME.getMonth() + 1,
      DATETIME.getDate()
    );
  }

  fill(value: number): string {
    return (value > NINE ? '' : '0') + value;
  }

  concatDate(year: number, month: number, date: number): string {
    return `${year}${this.fill(month)}${this.fill(date)}`;
  }

  concatTime(hours: number, minutes: number, seconds: number): string {
    return `${this.fill(hours)}${this.fill(minutes)}${this.fill(seconds)}`;
  }
}
