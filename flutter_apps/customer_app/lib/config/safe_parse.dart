/// Safe number parsing utilities for JSON data.
/// Server may return numbers as String, int, double, or null.
/// These helpers handle all cases without crashing.

double safeDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  final s = value.toString().trim();
  if (s.isEmpty) return fallback;
  return double.tryParse(s) ?? fallback;
}

int safeInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  final s = value.toString().trim();
  if (s.isEmpty) return fallback;
  return int.tryParse(s) ?? double.tryParse(s)?.toInt() ?? fallback;
}

String safeStr(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}
