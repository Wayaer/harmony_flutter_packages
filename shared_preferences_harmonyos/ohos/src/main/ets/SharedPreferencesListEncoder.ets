/**
 * An interface used to provide conversion logic between Array<string> and string for
 * SharedPreferencesPlugin.
 */
export interface SharedPreferencesListEncoder {
  /** Converts list to String for storing in shared preferences. */
  encode(list: Array<string>): string;

  /** Converts stored String representing List<String> to List. */
  decode(listString: string): ESObject;
}