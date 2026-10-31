class NativeIllegalArgumentException implements Exception {
  NativeIllegalArgumentException(this.message);

  final String message;

  @override
  String toString() {
    return 'NativeIllegalArgumentException($message)';
  }
}
