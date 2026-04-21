import 'dart:convert';

import 'package:flutter/foundation.dart';

const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

/// Pretty-prints [value] using an indented encoder, falling back to
/// `toString()` for non-serializable types (DateTime, Enum, custom
/// classes).
String prettyJson(Object? value) =>
    const JsonEncoder.withIndent('  ', _toEncodable).convert(value);

Object? _toEncodable(Object? nonEncodable) => nonEncodable?.toString();

/// Debug-prints [value] as indented JSON. No-op when [value] is null.
/// Assumes the value is already JSON-serializable (e.g. a `Map` with
/// primitive values) — use [prettyJson] if you need the `toString`
/// fallback.
void printJson(Object? value) {
  if (value == null) return;
  debugPrint(_jsonEncoder.convert(value));
}
