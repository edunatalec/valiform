import 'package:flutter/widgets.dart';
import 'package:valiform/src/field.dart';
import 'package:valiform/src/valiform.dart';
import 'package:validart/validart.dart';

/// A form manager that integrates validation, state management, and input handling.
///
/// `VForm<T>` is generic over the value type:
/// - `VForm<Map<String, dynamic>>` when created from a `VMap`
/// - `VForm<YourClass>` when created from a `VObject<YourClass>`
class VForm<T> {
  final GlobalKey<FormState> _formKey;
  final Map<String, VField> _fields = {};
  final bool Function(Map<String, dynamic>) _silentValidator;
  final T Function(Map<String, dynamic>) _valueBuilder;
  final List<void Function(T value)> _valueChangedListeners = [];

  VForm._({
    required Map<String, VType> schema,
    required bool Function(Map<String, dynamic>) silentValidator,
    required T Function(Map<String, dynamic>) valueBuilder,
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? initialValues,
    List<VFieldValidator> crossValidators = const [],
    List<({String field, Object? equals, Map<String, VType> then})> whenRules =
        const [],
    void Function(T value)? onValueChanged,
  })  : _formKey = formKey ?? GlobalKey<FormState>(),
        _silentValidator = silentValidator,
        _valueBuilder = valueBuilder {
    for (final entry in schema.entries) {
      final key = entry.key;
      final type = entry.value;

      final validators = crossValidators
          .where((v) => v.path == key)
          .map((v) => () {
                if (!v.check(rawValue)) return v.message ?? V.t(VCode.custom);
                return null;
              })
          .toList();

      for (final rule in whenRules) {
        final conditionalType = rule.then[key];
        if (conditionalType != null) {
          validators.add(() {
            if (rawValue[rule.field] != rule.equals) return null;
            final fieldValue = _fields[key]?.value;
            final processed = fieldValue is String &&
                    fieldValue.isEmpty &&
                    conditionalType.validate(null)
                ? null
                : fieldValue;
            return conditionalType.errors(processed)?.firstOrNull?.message;
          });
        }
      }

      _fields[key] = _createField(
        type: type,
        initialValue: initialValues?[key],
        validators: validators,
      );
    }

    if (onValueChanged != null) {
      _valueChangedListeners.add(onValueChanged);
    }

    listenable.addListener(_notifyValueChanged);
  }

  /// Creates a `VForm` from a `VMap` schema.
  ///
  /// The resulting form's [value] returns `Map<String, dynamic>`.
  factory VForm.map(
    VMap map, {
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? initialValues,
    void Function(T value)? onValueChanged,
  }) {
    final crossValidators = formFieldValidators[map] ?? [];

    return VForm._(
      schema: map.schema,
      silentValidator: (raw) => map.validate(raw),
      valueBuilder: (raw) => raw as T,
      formKey: formKey,
      initialValues: initialValues,
      crossValidators: crossValidators,
      whenRules: map.whenRules,
      onValueChanged: onValueChanged,
    );
  }

  /// Creates a `VForm` from a `VObject<T>` schema.
  ///
  /// Requires a [builder] function to construct `T` from the field values.
  /// Accepts an optional [initialValue] of type `T` to set initial field values.
  /// The resulting form's [value] returns an instance of `T`.
  factory VForm.object(
    VObject<T> object, {
    required T Function(Map<String, dynamic> data) builder,
    GlobalKey<FormState>? formKey,
    T? initialValue,
    void Function(T value)? onValueChanged,
  }) {
    final initialValues =
        initialValue != null ? object.extract(initialValue) : null;

    return VForm._(
      schema: object.schema,
      silentValidator: (raw) => object.validate(builder(raw)),
      valueBuilder: builder,
      formKey: formKey,
      initialValues: initialValues,
      onValueChanged: onValueChanged,
    );
  }

  void _notifyValueChanged() {
    final current = value;
    for (final listener in _valueChangedListeners) {
      listener(current);
    }
  }

  /// The global form key used for managing form state.
  GlobalKey<FormState> get key => _formKey;

  /// A combined `Listenable` for detecting changes across all fields.
  Listenable get listenable {
    return Listenable.merge(
      _fields.values.map((field) => field.listenable),
    );
  }

  /// The raw field values as a `Map<String, dynamic>` (without transforms).
  Map<String, dynamic> get rawValue {
    return _fields.map((key, field) => MapEntry(key, field.value));
  }

  /// The form value with transforms applied (trim, toLowerCase, etc.).
  ///
  /// - For `VMap` forms: returns `Map<String, dynamic>`
  /// - For `VObject` forms: returns an instance of `T` built by the builder
  T get value => _valueBuilder(
        _fields.map((key, field) => MapEntry(key, field.parsedValue)),
      );

  /// Retrieves a specific form field by its key.
  ///
  /// Throws [ArgumentError] if the field does not exist or the type does not match.
  VField<F> field<F>(String key) {
    final field = _fields[key];

    if (field == null) {
      throw ArgumentError('The field "$key" does not exist.');
    }

    if (field is! VField<F>) {
      throw ArgumentError(
        'The field "$key" is of type ${field.runtimeType}, not VField<$F>.',
      );
    }

    return field;
  }

  /// Adds a listener that is called whenever any field value changes.
  ///
  /// The listener receives the current form value of type `T`.
  void addValueChangedListener(void Function(T value) listener) {
    _valueChangedListeners.add(listener);
  }

  /// Removes a previously added value changed listener.
  void removeValueChangedListener(void Function(T value) listener) {
    _valueChangedListeners.remove(listener);
  }

  /// Calls `onSaved` on all fields.
  void save() => _formKey.currentState?.save();

  /// Resets all form fields to their initial values.
  void reset() {
    _formKey.currentState?.reset();
    for (final field in _fields.values) {
      field.reset();
    }
  }

  /// Sets an imperative error on [field].
  ///
  /// Delegates to [VField.setError]. See that method for semantics.
  void setError(
    String field,
    String message, {
    bool persist = false,
    bool force = false,
  }) {
    _requireField(field).setError(message, persist: persist, force: force);
  }

  /// Sets imperative errors on multiple fields at once. Throws [ArgumentError]
  /// listing any keys not present in the schema.
  void setErrors(
    Map<String, String> errors, {
    bool persist = false,
    bool force = false,
  }) {
    assert(
      errors.isNotEmpty,
      'setErrors called with an empty map — probably a mistake.',
    );

    final List<String> unknown =
        errors.keys.where((k) => !_fields.containsKey(k)).toList();
    if (unknown.isNotEmpty) {
      throw ArgumentError(
        'Unknown field${unknown.length == 1 ? '' : 's'}: ${unknown.join(', ')}.',
      );
    }
    for (final entry in errors.entries) {
      _fields[entry.key]!.setError(entry.value, persist: persist, force: force);
    }
  }

  /// Returns a map of field name → error message for every field that
  /// currently fails validation, or `null` if all fields are valid.
  ///
  /// Read-only: does NOT consume one-shot manual errors, does NOT touch
  /// the UI. Use this to inspect validation state for logging or custom
  /// error displays.
  Map<String, String>? errors() {
    final result = <String, String>{};
    for (final entry in _fields.entries) {
      final error = entry.value.error;
      if (error != null) {
        result[entry.key] = error;
      }
    }
    return result.isEmpty ? null : result;
  }

  /// Returns a map of field name → list of [VError]s for every field that
  /// currently fails validation, or `null` if all fields are valid.
  ///
  /// Unlike [errors], this preserves the full error detail (`code`, `path`,
  /// `message`) — useful for array fields where the path contains the
  /// failing element's index.
  ///
  /// Read-only: does NOT consume one-shot manual errors, does NOT touch
  /// the UI.
  Map<String, List<VError>>? vErrors() {
    final result = <String, List<VError>>{};
    for (final entry in _fields.entries) {
      final errs = entry.value.vError;
      if (errs != null) result[entry.key] = errs;
    }
    return result.isEmpty ? null : result;
  }

  /// Clears the imperative error on [field].
  void clearError(String field) {
    _requireField(field).clearError();
  }

  /// Clears all imperative errors across every field.
  void clearErrors() {
    for (final field in _fields.values) {
      field.clearError();
    }
  }

  VField _requireField(String key) {
    final field = _fields[key];
    if (field == null) {
      throw ArgumentError('The field "$key" does not exist.');
    }
    return field;
  }

  /// Validates all form fields and returns `true` if all are valid.
  bool validate() => _formKey.currentState?.validate() ?? false;

  /// Validates without triggering UI error messages.
  ///
  /// Mirrors [validate] semantically — runs the validart schema AND each
  /// field's validator (including cross-field validators and imperative
  /// errors set via [setError]), consuming one-shot manual errors in the
  /// process. The UI is never touched (no `FormState.validate()` call).
  ///
  /// Use `field.manualError` if you need to inspect errors without
  /// consuming state.
  bool silentValidate() {
    bool allValid = true;
    for (final field in _fields.values) {
      if (field.validator(field.value) != null) {
        allValid = false;
      }
    }
    final schemaValid = _silentValidator(
      _fields.map((key, field) => MapEntry(key, field.parsedValue)),
    );
    return allValid && schemaValid;
  }

  /// Disposes all fields and releases resources.
  void dispose() {
    _valueChangedListeners.clear();
    for (final field in _fields.values) {
      field.dispose();
    }
  }

  static VField _createField({
    required VType type,
    required dynamic initialValue,
    required List<String? Function()> validators,
  }) {
    return type.mapType(<F>(VType<F> t) {
      return VField<F>(
        type: t,
        initialValue: initialValue as F?,
        validators: validators,
      );
    });
  }
}
