import { CommonConstants } from './CommonConstants';

class DateFormatUtil {
  secondToTime(seconds: number): string {
    let hourUnit = CommonConstants.TIME_UNIT * CommonConstants.TIME_UNIT;
    let hour = Math.floor(seconds / hourUnit);
    let minute = Math.floor((seconds - hour * hourUnit) / CommonConstants.TIME_UNIT);
    let second = seconds - hour * hourUnit - minute * CommonConstants.TIME_UNIT;
    if (hour > 0) {
      return `${this.padding(hour.toString())}${':'}
        ${this.padding(minute.toString())}${':'}${this.padding(second.toString())}`;
    }
    if (minute > 0) {
      return `${this.padding(minute.toString())}${':'}${this.padding(second.toString())}`;
    } else {
      return `${CommonConstants.INITIAL_TIME_UNIT}${':'}${this.padding(second.toString())}`;
    }
  }

  padding(num: string): string {
    let length = CommonConstants.PADDING_LENGTH;
    for (let len = (num.toString()).length; len < length; len = num.length) {
      num = `${CommonConstants.PADDING_STR}${num}`;
    }
    return num;
  }
}

export default new DateFormatUtil();

