import 'dart:convert';

/// Extracts the payload from a JWT without verifying the signature.
/// Used client-side only to read the `sub` (user ID) claim.
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw const FormatException('Invalid JWT');
  final payload = parts[1];
  final normalized = base64Url.normalize(payload);
  final decoded = utf8.decode(base64Url.decode(normalized));
  return json.decode(decoded) as Map<String, dynamic>;
}
