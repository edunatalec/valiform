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
  final Map<String, dynamic> _defaultValues = {};
  final bool Function(Map<String, dynamic>) _silentValidator;
  final T Function(Map<String, dynamic>) _valueBuilder;
  final List<void Function(T value)> _valueChangedListeners = [];

  VForm._({
    required Map<String, VType> schema,
    required bool Function(Map<String, dynamic>) silentValidator,
    required T Function(Map<String, dynamic>) valueBuilder,
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
    List<VFieldValidator> crossValidators = const [],
    void Function(T value)? onValueChanged,
  })  : _formKey = formKey ?? GlobalKey<FormState>(),
        _silentValidator = silentValidator,
        _valueBuilder = valueBuilder {
    if (defaultValues != null) {
      _defaultValues.addAll(defaultValues);
    }

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

      _fields[key] = _createField(
        type: type,
        initialValue: defaultValues?[key],
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
    Map<String, dynamic>? defaultValues,
    void Function(T value)? onValueChanged,
  }) {
    final crossValidators = formFieldValidators[map] ?? [];

    return VForm._(
      schema: map.schema,
      silentValidator: (raw) => map.validate(raw),
      valueBuilder: (raw) => raw as T,
      formKey: formKey,
      defaultValues: defaultValues,
      crossValidators: crossValidators,
      onValueChanged: onValueChanged,
    );
  }

  /// Creates a `VForm` from a `VObject<T>` schema.
  ///
  /// Requires a [builder] function to construct `T` from the field values.
  /// Accepts an optional [defaultValue] of type `T` to set initial field values.
  /// The resulting form's [value] returns an instance of `T`.
  factory VForm.object(
    VObject<T> object, {
    required T Function(Map<String, dynamic> data) builder,
    GlobalKey<FormState>? formKey,
    T? defaultValue,
    void Function(T value)? onValueChanged,
  }) {
    final defaultValues =
        defaultValue != null ? object.extract(defaultValue) : null;

    return VForm._(
      schema: object.schema,
      silentValidator: (raw) => object.validate(builder(raw)),
      valueBuilder: builder,
      formKey: formKey,
      defaultValues: defaultValues,
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

  /// Clears all fields in the form.
  void clear() {
    _formKey.currentState?.reset();
    for (final field in _fields.values) {
      field.clear();
    }
  }

  /// Validates all form fields and returns `true` if all are valid.
  bool validate() => _formKey.currentState?.validate() ?? false;

  /// Validates without triggering UI error messages.
  bool silentValidate() => _silentValidator(
        _fields.map((key, field) => MapEntry(key, field.parsedValue)),
      );

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
