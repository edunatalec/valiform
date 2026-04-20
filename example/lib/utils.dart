import 'dart:convert';

/// Shared indented JSON encoder used across the example app.
const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');

/// Pretty-prints [value] using [jsonEncoder], falling back to `toString()`
/// for non-serializable types (DateTime, Enum, custom classes).
String prettyJson(Object? value) =>
    const JsonEncoder.withIndent('  ', _toEncodable).convert(value);

Object? _toEncodable(Object? nonEncodable) => nonEncodable?.toString();
