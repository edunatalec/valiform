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
  final (bool, List<String>) Function(Map<String, dynamic>)
      _silentValidatorSync;
  final Future<(bool, List<String>)> Function(Map<String, dynamic>)
      _silentValidatorAsync;
  final T Function(Map<String, dynamic>) _valueBuilder;
  final List<void Function(T value)> _valueChangedListeners = [];
  final bool _schemaHasAsync;
  late final bool _hasAsync;

  /// Whether any field in this form depends on async validation — either
  /// its type contains `refineAsync`/`preprocessAsync`/`transformAsync`,
  /// or a `.when()` rule targets an async conditional type.
  ///
  /// When `true`, synchronous inspection methods ([validate], [value],
  /// [silentValidate], [errors], [vErrors]) throw [VAsyncRequiredException] —
  /// use the `*Async` variants.
  bool get hasAsync => _hasAsync;

  VForm._({
    required Map<String, VType> schema,
    required bool schemaHasAsync,
    required (bool, List<String>) Function(Map<String, dynamic>)
        silentValidatorSync,
    required Future<(bool, List<String>)> Function(Map<String, dynamic>)
        silentValidatorAsync,
    required T Function(Map<String, dynamic>) valueBuilder,
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? initialValues,
    List<VFieldValidator> crossValidators = const [],
    List<({String field, Object? equals, Map<String, VType> then})> whenRules =
        const [],
    Map<String, dynamic> Function(Map<String, dynamic>)?
        containerPreprocessSync,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
        containerPreprocessAsync,
    void Function(T value)? onValueChanged,
  })  : _formKey = formKey ?? GlobalKey<FormState>(),
        _silentValidatorSync = silentValidatorSync,
        _silentValidatorAsync = silentValidatorAsync,
        _valueBuilder = valueBuilder,
        _schemaHasAsync = schemaHasAsync {
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

      final asyncValidators = <Future<String?> Function()>[];

      for (final rule in whenRules) {
        final conditionalType = rule.then[key];
        if (conditionalType == null) continue;

        if (conditionalType.hasAsync) {
          asyncValidators.add(() async {
            if (rawValue[rule.field] != rule.equals) return null;

            final fieldValue = _fields[key]?.value;
            final processed =
                fieldValue is String && fieldValue.isEmpty ? null : fieldValue;

            return (await conditionalType.errorsAsync(processed))
                ?.firstOrNull
                ?.message;
          });
        } else {
          validators.add(() {
            if (rawValue[rule.field] != rule.equals) return null;

            final fieldValue = _fields[key]?.value;
            final processed = fieldValue is String &&
                    fieldValue.isEmpty &&
                    conditionalType.isNullable
                ? null
                : fieldValue;

            return conditionalType.errors(processed)?.firstOrNull?.message;
          });
        }
      }

      // Resolve the field's initial value:
      //   1. `initialValues[key]` if the caller explicitly provided it
      //      (even `null` counts — use `containsKey` to distinguish).
      //   2. `type.defaultValueOrNull` when the schema has a `defaultValue`.
      //   3. `null` otherwise.
      //
      // Because validart's `defaultValue` makes the field non-required
      // (the default is substituted for null before any validator runs),
      // surfacing it as the VField's initial value aligns the UI with the
      // pipeline and makes `reset()` restore it.
      final Object? resolvedInitial =
          initialValues != null && initialValues.containsKey(key)
              ? initialValues[key]
              : type.defaultValueOrNull;

      // Container preprocess closures, scoped to this field.
      //
      // Each VField receives a closure that, given its raw value, returns
      // the value as it would appear after the container's `preprocess()`
      // ran. The closure snapshots all sibling fields, swaps in the
      // candidate value for `key`, runs the container preprocess on the
      // full snapshot, and reads back the slot for `key` from the result.
      //
      // This mirrors the order of `VMap.safeParse` / `VObject.safeParse`:
      // container preprocess runs BEFORE each field's per-field pipeline.
      // Without these closures, the per-field validator only sees the raw
      // value and disagrees with the schema-level result whenever the
      // container preprocess "fixes" the input.
      //
      // When the surrounding container has no preprocess registered, the
      // factory passes `null` for both closures and the field falls back
      // to the legacy passthrough — zero overhead.
      final fieldKey = key;
      final preSync = containerPreprocessSync == null
          ? null
          : (Object? rawValue) {
              final snapshot = _fields.map(
                (k, f) => MapEntry(k, f.value as Object?),
              );
              snapshot[fieldKey] = rawValue;
              final processed = containerPreprocessSync(snapshot);
              return processed[fieldKey];
            };
      final preAsync = containerPreprocessAsync == null
          ? null
          : (Object? rawValue) async {
              final snapshot = _fields.map(
                (k, f) => MapEntry(k, f.value as Object?),
              );
              snapshot[fieldKey] = rawValue;
              final processed = await containerPreprocessAsync(snapshot);
              return processed[fieldKey];
            };

      _fields[key] = _createField(
        type: type,
        initialValue: resolvedInitial,
        validators: validators,
        asyncValidators: asyncValidators,
        preprocessor: preSync,
        preprocessorAsync: preAsync,
      );
    }

    _hasAsync = _schemaHasAsync || _fields.values.any((f) => f.hasAsync);

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

    // Gate the snapshot/preprocess plumbing on actually-needed work.
    // Schemas without container preprocess pay zero overhead.
    final containerPreprocessSync = map.hasPreprocessors
        ? (Map<String, dynamic> snapshot) {
            final processed = map.runPreprocessors(snapshot);
            if (processed is Map<String, dynamic>) return processed;
            return snapshot;
          }
        : null;
    final containerPreprocessAsync = map.hasPreprocessors
        ? (Map<String, dynamic> snapshot) async {
            final processed = await map.runPreprocessorsAsync(snapshot);
            if (processed is Map<String, dynamic>) return processed;
            return snapshot;
          }
        : null;

    return VForm._(
      schema: map.schema,
      schemaHasAsync: map.hasAsync,
      silentValidatorSync: (raw) => _runWithRoot(map.safeParse(raw)),
      silentValidatorAsync: (raw) async =>
          _runWithRoot(await map.safeParseAsync(raw)),
      valueBuilder: (raw) => raw as T,
      formKey: formKey,
      initialValues: initialValues,
      crossValidators: crossValidators,
      whenRules: map.whenRules,
      containerPreprocessSync: containerPreprocessSync,
      containerPreprocessAsync: containerPreprocessAsync,
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

    // Gate the snapshot/preprocess plumbing on actually-needed work.
    // For VObject the snapshot Map needs to be reconstructed into `T` via
    // `builder` before running the container preprocess (which expects
    // `T`), and then decomposed back into a Map via `object.extract`.
    final containerPreprocessSync = object.hasPreprocessors
        ? (Map<String, dynamic> snapshot) {
            final instance = builder(snapshot);
            final processed = object.runPreprocessors(instance);
            if (processed is T) return object.extract(processed);
            return snapshot;
          }
        : null;
    final containerPreprocessAsync = object.hasPreprocessors
        ? (Map<String, dynamic> snapshot) async {
            final instance = builder(snapshot);
            final processed = await object.runPreprocessorsAsync(instance);
            if (processed is T) return object.extract(processed);
            return snapshot;
          }
        : null;

    return VForm._(
      schema: object.schema,
      schemaHasAsync: object.hasAsync,
      silentValidatorSync: (raw) =>
          _runWithRoot(object.safeParse(builder(raw))),
      silentValidatorAsync: (raw) async =>
          _runWithRoot(await object.safeParseAsync(builder(raw))),
      valueBuilder: builder,
      formKey: formKey,
      initialValues: initialValues,
      whenRules: object.whenRules,
      containerPreprocessSync: containerPreprocessSync,
      containerPreprocessAsync: containerPreprocessAsync,
      onValueChanged: onValueChanged,
    );
  }

  /// Unpacks a [VResult] into the `(valid, rootMessages)` tuple consumed by
  /// the silent validators — `VSuccess` contributes nothing to `rootErrors`,
  /// while `VFailure.rootMessages()` captures schema-level errors with no
  /// specific field path (i.e. emitted by `refine(..., dependsOn: {...})`
  /// without a per-field `path`).
  static (bool, List<String>) _runWithRoot(VResult result) {
    if (result is VSuccess) return (true, const <String>[]);

    return (false, (result as VFailure).rootMessages());
  }

  void _notifyValueChanged() {
    // Value change listeners require a synchronous value. In async schemas
    // `value` would throw; skip the notification — consumers of async forms
    // should listen on [listenable] directly and await [valueAsync].
    if (_hasAsync) return;

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
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [valueAsync].
  T get value {
    if (_hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VForm.value',
        suggestion: 'valueAsync',
      );
    }

    return _valueBuilder(
      _fields.map((key, field) => MapEntry(key, field.parsedValue)),
    );
  }

  /// Async variant of [value]: awaits each field's async pipeline
  /// (`refineAsync`/`preprocessAsync`/`transformAsync`) before building
  /// the final form value.
  Future<T> get valueAsync async {
    final parsed = <String, dynamic>{};

    for (final entry in _fields.entries) {
      parsed[entry.key] = await entry.value.parsedValueAsync;
    }

    return _valueBuilder(parsed);
  }

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
  ///
  /// Calls `FormState.reset()` first so each `TextFormField` descendant
  /// restores its text from `widget.initialValue`; the subsequent
  /// `field.reset()` overrides any `''` that `TextFormField.reset()`
  /// writes back via its `widget.onChanged(text)` side effect.
  ///
  /// Requires widgets to bind `initialValue` to `VField.initialValue`
  /// (not `VField.value`) so the reset target stays stable across
  /// rebuilds — see `VField.initialValue`'s dartdoc.
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
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [errorsAsync].
  Map<String, String>? errors() {
    if (_hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VForm.errors',
        suggestion: 'errorsAsync',
      );
    }

    final result = <String, String>{};

    for (final entry in _fields.entries) {
      final error = entry.value.error;
      if (error != null) {
        result[entry.key] = error;
      }
    }

    return result.isEmpty ? null : result;
  }

  /// Async variant of [errors]: inspects the full pipeline including
  /// async steps. Still read-only.
  Future<Map<String, String>?> errorsAsync() async {
    final result = <String, String>{};

    for (final entry in _fields.entries) {
      final message = await entry.value.errorAsync;
      if (message != null) result[entry.key] = message;
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
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [vErrorsAsync].
  Map<String, List<VError>>? vErrors() {
    if (_hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VForm.vErrors',
        suggestion: 'vErrorsAsync',
      );
    }

    final result = <String, List<VError>>{};

    for (final entry in _fields.entries) {
      final errs = entry.value.vError;
      if (errs != null) result[entry.key] = errs;
    }

    return result.isEmpty ? null : result;
  }

  /// Async variant of [vErrors]: inspects the full pipeline including
  /// async steps.
  Future<Map<String, List<VError>>?> vErrorsAsync() async {
    final result = <String, List<VError>>{};

    for (final entry in _fields.entries) {
      final errs = await entry.value.vErrorAsync;
      if (errs != null) result[entry.key] = errs;
    }

    return result.isEmpty ? null : result;
  }

  /// Form-level error messages emitted by schema validators with no specific
  /// field path — typically `refine(..., dependsOn: {...})` rules on the
  /// `VMap` / `VObject` (e.g. cross-field date-range or total checks).
  ///
  /// Render these as a banner above the form; field-keyed errors come from
  /// [errors]. Always reflects the current parsed values: each access
  /// re-runs the schema-level `safeParse`, so mounting a [ListenableBuilder]
  /// on [listenable] keeps the banner in sync without a manual
  /// [silentValidate] call.
  ///
  /// ```dart
  /// final form = V.map({
  ///   'startDate': V.date(),
  ///   'endDate': V.date(),
  /// }).refine(
  ///   (m) => (m['endDate'] as DateTime).isAfter(m['startDate'] as DateTime),
  ///   message: 'endDate must be after startDate',
  ///   dependsOn: const {'startDate', 'endDate'},
  /// ).form();
  ///
  /// // After invalid input:
  /// form.rootErrors; // ['endDate must be after startDate']
  /// ```
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [rootErrorsAsync].
  List<String> get rootErrors {
    if (_hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VForm.rootErrors',
        suggestion: 'rootErrorsAsync',
      );
    }

    final (_, root) = _silentValidatorSync(
      _fields.map((key, field) => MapEntry(key, field.parsedValue)),
    );

    return root;
  }

  /// Async variant of [rootErrors]: awaits each field's async pipeline
  /// before re-running the schema-level `safeParseAsync` to capture any
  /// `refineAsync(..., dependsOn: {...})` failures.
  Future<List<String>> get rootErrorsAsync async {
    final parsed = <String, dynamic>{};

    for (final entry in _fields.entries) {
      parsed[entry.key] = await entry.value.parsedValueAsync;
    }

    final (_, root) = await _silentValidatorAsync(parsed);

    return root;
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
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [validateAsync].
  bool validate() {
    if (_hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VForm.validate',
        suggestion: 'validateAsync',
      );
    }

    return _formKey.currentState?.validate() ?? false;
  }

  /// Async variant of [validate]: runs the full validation pipeline,
  /// including `refineAsync`/`preprocessAsync` steps, and surfaces any
  /// async errors as persistent imperative errors so they show up in
  /// `FormField` widgets just like regular errors. Returns `true` when
  /// every field is valid.
  Future<bool> validateAsync() async {
    bool allValid = true;

    for (final entry in _fields.entries) {
      final field = entry.value;
      final message = await field.computeAsyncError();

      if (message != null) {
        allValid = false;
        field.setError(message, persist: true);
      } else {
        field.clearError();
      }
    }

    // Also repaint the UI so the persisted errors surface through
    // FormField.validator.
    _formKey.currentState?.validate();

    return allValid;
  }

  /// Validates without triggering UI error messages.
  ///
  /// Mirrors [validate] semantically — runs the validart schema AND each
  /// field's validator (including cross-field validators and imperative
  /// errors set via [setError]), consuming one-shot manual errors in the
  /// process. The UI is never touched (no `FormState.validate()` call).
  ///
  /// Use `field.manualError` if you need to inspect errors without
  /// consuming state.
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [silentValidateAsync].
  bool silentValidate() {
    if (_hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VForm.silentValidate',
        suggestion: 'silentValidateAsync',
      );
    }

    bool allValid = true;

    for (final field in _fields.values) {
      if (field.validator(field.value) != null) {
        allValid = false;
      }
    }

    final (schemaValid, _) = _silentValidatorSync(
      _fields.map((key, field) => MapEntry(key, field.parsedValue)),
    );

    return allValid && schemaValid;
  }

  /// Async variant of [silentValidate]: runs full pipeline without
  /// touching the UI. Does NOT consume one-shot manual errors.
  Future<bool> silentValidateAsync() async {
    bool allValid = true;

    for (final field in _fields.values) {
      final message = await field.errorAsync;
      if (message != null) allValid = false;
    }

    final parsed = <String, dynamic>{};

    for (final entry in _fields.entries) {
      parsed[entry.key] = await entry.value.parsedValueAsync;
    }

    final (schemaValid, _) = await _silentValidatorAsync(parsed);

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
    List<Future<String?> Function()> asyncValidators = const [],
    Object? Function(Object?)? preprocessor,
    Future<Object?> Function(Object?)? preprocessorAsync,
  }) {
    return type.mapType(<F>(VType<F> t) {
      return VField<F>(
        type: t,
        initialValue: initialValue as F?,
        validators: validators,
        asyncValidators: asyncValidators,
        preprocessor: preprocessor == null ? null : (raw) => preprocessor(raw),
        preprocessorAsync:
            preprocessorAsync == null ? null : (raw) => preprocessorAsync(raw),
      );
    });
  }
}
