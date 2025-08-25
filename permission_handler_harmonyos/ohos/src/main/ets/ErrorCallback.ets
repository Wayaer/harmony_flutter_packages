export interface ErrorCallback {
  onError(errorCode: string, errorDescription: string): void;
}