import 'dart:convert';

/// Pretty-prints [value] as indented JSON, falling back to `toString()`
/// for non-serializable types (DateTime, Enum, custom classes). Used by
/// the [ResultBox] widget (and anywhere else the example app needs a
/// readable dump of a form value or error map).
String prettyJson(Object? value) =>
    const JsonEncoder.withIndent('  ', _toEncodable).convert(value);

Object? _toEncodable(Object? nonEncodable) => nonEncodable?.toString();
