/// Sound feedback result returned from the barcode callback.
enum ScanSoundResult {
  /// Play the "success" beep (formerly "0")
  success,

  /// Play the "read" beep (formerly "1")
  read,

  /// Play the "fail" buzzer (formerly "-1")
  fail,

  /// Do not play any sound (formerly null)
  none,
}
