/// Formats a byte count into a human-readable string.
///
/// Returns a value in KB when [sizeBytes] is below 1,048,576 (1 MiB),
/// otherwise in MB. The numeric value is rounded to one decimal place.
///
/// Examples:
///   formatFileSize(0)       -> "0.0 KB"
///   formatFileSize(2048)    -> "2.0 KB"
///   formatFileSize(1048576) -> "1.0 MB"
String formatFileSize(int sizeBytes) {
  const int bytesPerMb = 1048576; // 1024 * 1024
  const int bytesPerKb = 1024;

  if (sizeBytes < bytesPerMb) {
    final value = (sizeBytes / bytesPerKb).toStringAsFixed(1);
    return '$value KB';
  }
  final value = (sizeBytes / bytesPerMb).toStringAsFixed(1);
  return '$value MB';
}
