import 'package:flutter/widgets.dart';
import 'package:valiform/src/field.dart';
import 'package:validart/validart.dart';

/// A form manager that integrates validation, state management, and input handling.
///
/// `VForm<T>` is generic over the value type:
/// - `VForm<Map<String, dynamic>>` when created from a `VMap`
/// - `VForm<YourClass>` when created from a `VObject<YourClass>`
class VForm<T> {
  final GlobalKey<FormState> _formKey;
  final Map<String, VField> _fields = {};
  final (bool, List<String>, Map<String, String>) Function(
    Map<String, dynamic>,
  ) _silentValidatorSync;
  final Future<(bool, List<String>, Map<String, String>)> Function(
    Map<String, dynamic>,
  ) _silentValidatorAsync;
  final T Function(Map<String, dynamic>) _valueBuilder;
  final List<void Function(Map<String, dynamic> rawValue)>
      _valueChangedListeners = [];
  final bool _schemaHasAsync;
  late final bool _hasAsync;

  /// Snapshot of the schema-level errors that have a non-empty path,
  /// keyed by the top-level field name. Refreshed by every call to
  /// [validate] / [silentValidate] (and async equivalents). Read by
  /// each [VField] via its `schemaErrorLookup` closure so the error
  /// emitted by `refineField` / `refineFieldRaw` / nested-path `refine`
  /// reaches `field.error`, `field.validator`, `form.errors()`, and
  /// the `FormField.validator` chain.
  ///
  /// The sync per-field path actually re-runs the schema validator
  /// on demand (so the lookup never goes stale between the user typing
  /// and the next validate); this snapshot is the channel for the
  /// async path, where the sync `field.validator` cannot await.
  Map<String, String> _schemaFieldErrors = const {};

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
    required (bool, List<String>, Map<String, String>) Function(
      Map<String, dynamic>,
    ) silentValidatorSync,
    required Future<(bool, List<String>, Map<String, String>)> Function(
      Map<String, dynamic>,
    ) silentValidatorAsync,
    required T Function(Map<String, dynamic>) valueBuilder,
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? initialValues,
    List<({String field, Object? equals, Map<String, VType> then})> whenRules =
        const [],
    Map<String, dynamic> Function(Map<String, dynamic>)?
        containerPreprocessSync,
    Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
        containerPreprocessAsync,
    void Function(Map<String, dynamic> rawValue)? onValueChanged,
  })  : _formKey = formKey ?? GlobalKey<FormState>(),
        _silentValidatorSync = silentValidatorSync,
        _silentValidatorAsync = silentValidatorAsync,
        _valueBuilder = valueBuilder,
        _schemaHasAsync = schemaHasAsync {
    for (final entry in schema.entries) {
      final key = entry.key;
      final type = entry.value;

      // Per-field sync extra-validators populated below (currently only
      // by sync `.when()` rules). Schema-level cross-field rules
      // (`refineField`, nested-path `refine`) flow through the
      // `_schemaFieldErrors` snapshot consulted by `schemaErrorLookup`,
      // so they do NOT need to be added here.
      final validators = <String? Function()>[];

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

      // Schema error lookup, scoped to this field.
      //
      // Sync path: re-runs the schema validator on demand each time the
      // per-field validator is called, so the snapshot always reflects
      // the current sibling values. Without this, the snapshot would go
      // stale the moment any other field changed (e.g. flipping a
      // `when` condition off should drop the conditional error
      // immediately). Cost is O(N) per keystroke — same shape as the
      // container preprocess closure, and gated on the schema actually
      // having validation power: pure schemas with no refine /
      // refineField / equalFields / whenRules return an empty
      // fieldErrors map and the lookup degrades to a no-op.
      //
      // Async path: a sync per-field validator can't await the schema,
      // so we fall through to `_schemaFieldErrors`, which is a snapshot
      // refreshed by every `validateAsync` / `silentValidateAsync` call.
      _fields[key] = _createField(
        type: type,
        initialValue: resolvedInitial,
        validators: validators,
        asyncValidators: asyncValidators,
        preprocessor: preSync,
        preprocessorAsync: preAsync,
        schemaErrorLookup: () {
          if (!_hasAsync) {
            // Pass raw values (with empty strings normalized to null so
            // defaultValue / nullable handling engages): the underlying
            // safeParse applies container preprocess + per-field pipeline
            // on its own. Sending parsed would double-process and would
            // hide raw values from `refineFieldRaw`.
            final (_, _, fieldErrors) = _silentValidatorSync(_rawSnapshot());
            return fieldErrors[fieldKey];
          }
          return _schemaFieldErrors[fieldKey];
        },
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
    void Function(Map<String, dynamic> rawValue)? onValueChanged,
  }) {
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
    void Function(Map<String, dynamic> rawValue)? onValueChanged,
  }) {
    final initialValues =
        initialValue != null ? object.extract(initialValue) : null;

    // Gate the snapshot/preprocess plumbing on actually-needed work.
    // For VObject the snapshot Map needs to be reconstructed into `T` via
    // `builder` before running the container preprocess (which expects
    // `T`), and then decomposed back into a Map via `object.extract`.
    // Container preprocess on VObject needs `T` — but the snapshot used
    // here can be partial (any field still null while the user types).
    // A non-null-tolerant builder would throw `TypeError` and tank the
    // whole field-validator chain. When that happens, treat preprocess
    // as a no-op for this tick (return the snapshot unchanged): the user
    // is still typing, the snapshot will eventually be complete, and
    // preprocess will run on the canonical `safeParse` path then.
    final containerPreprocessSync = object.hasPreprocessors
        ? (Map<String, dynamic> snapshot) {
            final T instance;
            try {
              instance = builder(snapshot);
            } catch (_) {
              return snapshot;
            }

            final processed = object.runPreprocessors(instance);
            if (processed is T) return object.extract(processed);

            return snapshot;
          }
        : null;
    final containerPreprocessAsync = object.hasPreprocessors
        ? (Map<String, dynamic> snapshot) async {
            final T instance;
            try {
              instance = builder(snapshot);
            } catch (_) {
              return snapshot;
            }

            final processed = await object.runPreprocessorsAsync(instance);
            if (processed is T) return object.extract(processed);

            return snapshot;
          }
        : null;

    // Silent validators take the canonical `object.safeParse(builder(raw))`
    // path whenever the user's `builder` can construct a `T` from the
    // current raw map. That preserves every schema feature (container
    // preprocess, `refine`, `refineField`, `refineFieldRaw`, `equalFields`,
    // `whenRules`) — most importantly, container preprocess, which can
    // rewrite field values before per-field validation observes them.
    //
    // When the builder throws `TypeError` — the common shape is a builder
    // that dereferences `data['x']` into a non-nullable parameter on a
    // partial form — fall back to a per-field iteration over
    // `object.schema` with raw values. Schema-level rules can't run
    // without `T`, but per-field errors are exactly what a half-filled
    // form needs anyway: tell the user which fields are still required.
    //
    // Catching `TypeError` specifically (not `Exception`) keeps the scope
    // tight to the missing-field case; validart's safeParse never throws
    // on validation outcomes, so the caught error is virtually always the
    // builder's null-deref.
    return VForm._(
      schema: object.schema,
      schemaHasAsync: object.hasAsync,
      silentValidatorSync: (raw) {
        try {
          return _runWithRoot(object.safeParse(builder(raw)));
        } on TypeError {
          final List<VError> perFieldErrors = _objectPerFieldErrorsSync(
            object.schema,
            raw,
          );

          // Builder failed AND every field passed per-field validation.
          // That can only mean a schema/class mismatch (e.g. schema field
          // is `.nullable()` but the user's class declares the parameter
          // non-nullable). Surfacing `(false, [], {})` here would leave
          // `silentValidate()` reporting invalid with no errors to render
          // — a worse foot-gun than the original crash. Re-throw so the
          // user sees the underlying TypeError instead of silent state
          // corruption.
          if (perFieldErrors.isEmpty) rethrow;

          return _runWithRoot(VFailure<T?>(perFieldErrors));
        }
      },
      silentValidatorAsync: (raw) async {
        try {
          return _runWithRoot(await object.safeParseAsync(builder(raw)));
        } on TypeError {
          final List<VError> perFieldErrors =
              await _objectPerFieldErrorsAsync(object.schema, raw);

          if (perFieldErrors.isEmpty) rethrow;

          return _runWithRoot(VFailure<T?>(perFieldErrors));
        }
      },
      valueBuilder: builder,
      formKey: formKey,
      initialValues: initialValues,
      whenRules: object.whenRules,
      containerPreprocessSync: containerPreprocessSync,
      containerPreprocessAsync: containerPreprocessAsync,
      onValueChanged: onValueChanged,
    );
  }

  /// Snapshot of the raw field values, with empty strings normalized to
  /// `null`. The normalization lets validart's `_resolveNull` engage so
  /// `defaultValue` / `nullable` handling kicks in when the user clears
  /// a text field — without it, `''` would bypass those gates and the
  /// pipeline would run against the empty string.
  ///
  /// `refineFieldRaw` callbacks see the post-normalization map (so an
  /// empty text field shows as `null`, not `''`); the rest of the
  /// pipeline (container preprocess → per-field iteration) is applied
  /// by the underlying `safeParse`.
  Map<String, dynamic> _rawSnapshot() {
    return _fields.map((key, field) {
      final v = field.value;
      return MapEntry(key, v is String && v.isEmpty ? null : v);
    });
  }

  /// Unpacks a [VResult] into a `(valid, rootMessages, fieldMessages)`
  /// tuple consumed by the silent validators.
  ///
  /// `rootMessages` are the messages of every error with an empty path
  /// (emitted by `refine(...)` / `equalFields` applied at the schema
  /// root). `fieldMessages` is keyed by the top-level field name and
  /// holds the first message of every error with a non-empty path
  /// (emitted by `refineField(check, path: 'x')`, nested-path `refine`,
  /// or any other schema construct that targets a specific field).
  /// Together, the two partitions cover every error in the [VFailure]
  /// — root errors render in a banner, field errors render inline.
  static (bool, List<String>, Map<String, String>) _runWithRoot(
    VResult result,
  ) {
    if (result is VSuccess) {
      return (true, const <String>[], const <String, String>{});
    }

    final f = result as VFailure;

    // Root messages: delegate to validart's canonical implementation —
    // single source of truth. If validart ever changes the definition
    // of "root error" (e.g. how `path` empty is detected), valiform
    // follows automatically.
    final rootMessages = f.rootMessages();

    // Field messages: keep custom logic. Validart's `toMapFirst()`
    // keys by `pathString` (joined with `.`, e.g. `'address.zip'`),
    // but `VForm._fields` is indexed by TOP-LEVEL key only
    // (`'address'`). Routing a nested error to the wrong key would
    // mean it never reaches the right `VField`, so we iterate
    // manually and take `path.first` as the routing key. The full
    // path is still available via `form.vErrors()` for callers that
    // need it.
    final fieldMessages = <String, String>{};

    for (final err in f.errors) {
      if (err.path.isEmpty) continue;

      final key = err.path.first.toString();
      fieldMessages.putIfAbsent(key, () => err.message);
    }

    return (false, rootMessages, fieldMessages);
  }

  void _notifyValueChanged() {
    // The form-level callback delivers `rawValue` (not the typed builder
    // result) for two reasons:
    //
    // 1. A field change does not imply the form is valid enough to
    //    construct `T`. For `VForm.object`, computing `value` would invoke
    //    the user-supplied `builder` against a partial map and throw
    //    `TypeError` whenever the builder dereferences `data['key']` into
    //    a non-nullable parameter — see the dartdoc on [value].
    // 2. `rawValue` is sync-safe regardless of whether the schema has any
    //    async pipeline, so the listener works uniformly for sync and
    //    async forms.
    //
    // Iterate over a snapshot so a listener that registers or removes
    // another listener mid-dispatch doesn't trip a
    // `ConcurrentModificationError`.
    if (_valueChangedListeners.isEmpty) return;

    final Map<String, dynamic> raw = rawValue;

    for (final listener in List.of(_valueChangedListeners)) {
      listener(raw);
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
  /// The listener receives the current `rawValue` (a
  /// `Map<String, dynamic>` of every field), regardless of whether the
  /// form was created from a `VMap` or a `VObject<T>`. A field change
  /// does not imply the form is valid enough to construct `T`, so the
  /// callback intentionally bypasses the typed `builder`. To consume
  /// the typed value, validate first and read [value]:
  ///
  /// ```dart
  /// form.addValueChangedListener((raw) {
  ///   if (form.silentValidate()) {
  ///     final user = form.value; // safe: schema validated.
  ///     // ...
  ///   }
  /// });
  /// ```
  ///
  /// Fires for both sync and async forms — `rawValue` is synchronous.
  void addValueChangedListener(
    void Function(Map<String, dynamic> rawValue) listener,
  ) {
    _valueChangedListeners.add(listener);
  }

  /// Removes a previously added value changed listener.
  void removeValueChangedListener(
    void Function(Map<String, dynamic> rawValue) listener,
  ) {
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

    final (_, root, _) = _silentValidatorSync(
      _rawSnapshot(),
    );

    return root;
  }

  /// Async variant of [rootErrors]: awaits each field's async pipeline
  /// before re-running the schema-level `safeParseAsync` to capture any
  /// `refineAsync(..., dependsOn: {...})` failures.
  Future<List<String>> get rootErrorsAsync async {
    final (_, root, _) = await _silentValidatorAsync(_rawSnapshot());

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
  /// Safe on partial / empty `VForm.object` forms: the user-supplied
  /// `builder` is not invoked when any field is missing or has the wrong
  /// type, so a builder that dereferences `data['x']` into a non-nullable
  /// parameter (without `?? fallback`) won't throw `TypeError`. Per-field
  /// errors surface as usual; schema-level rules (`refine`, `refineField`,
  /// `equalFields`, `whenRules`, container preprocess) only run once
  /// every field is individually valid — at which point constructing
  /// `T` is guaranteed safe.
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

    // Run the schema validator FIRST so we can refresh _schemaFieldErrors
    // before FormState.validate() walks each FormField. That way the
    // per-field validators see up-to-date schema errors via the
    // schemaErrorLookup closure and surface them inline.
    final (schemaValid, _, fieldErrors) = _silentValidatorSync(
      _rawSnapshot(),
    );
    _schemaFieldErrors = fieldErrors;

    final fieldsValid = _formKey.currentState?.validate() ?? false;

    // Per-field validation alone is not enough: schema-level rules
    // (`refine`, `equalFields`, `refineField`, `dependsOn`) emit errors
    // that don't go through any FormField. Without checking them here,
    // `validate()` would return `true` for inputs the schema rejects —
    // a foot-gun that previously forced consumers to write
    // `if (form.validate() && form.silentValidate())`.
    return fieldsValid && schemaValid;
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

    // Per-field check alone misses schema-level rules — see the comment
    // on the sync `validate()` for the rationale. Refresh the schema
    // error snapshot before the final FormState.validate() repaint so
    // path-keyed schema errors surface inline. Pass raw values: the
    // underlying safeParseAsync applies container preprocess + per-field
    // pipeline on its own (and refineFieldRaw observes the raw input).
    final (schemaValid, _, fieldErrors) =
        await _silentValidatorAsync(_rawSnapshot());
    _schemaFieldErrors = fieldErrors;

    // Repaint the UI so persisted errors AND schema-level field errors
    // surface through FormField.validator.
    _formKey.currentState?.validate();

    return allValid && schemaValid;
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
  /// Same partial-form safety as [validate]: never invokes the
  /// `VForm.object` builder when fields are missing — see [validate].
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

    // Schema validator first so per-field validators below pick up the
    // refreshed schema field errors via schemaErrorLookup.
    final (schemaValid, _, fieldErrors) = _silentValidatorSync(
      _rawSnapshot(),
    );
    _schemaFieldErrors = fieldErrors;

    bool allValid = true;

    for (final field in _fields.values) {
      if (field.validator(field.value) != null) {
        allValid = false;
      }
    }

    return allValid && schemaValid;
  }

  /// Async variant of [silentValidate]: runs full pipeline without
  /// touching the UI. Does NOT consume one-shot manual errors.
  Future<bool> silentValidateAsync() async {
    final (schemaValid, _, fieldErrors) =
        await _silentValidatorAsync(_rawSnapshot());
    _schemaFieldErrors = fieldErrors;

    bool allValid = true;

    for (final field in _fields.values) {
      final message = await field.errorAsync;
      if (message != null) allValid = false;
    }

    return allValid && schemaValid;
  }

  /// Disposes all fields and releases resources.
  void dispose() {
    _valueChangedListeners.clear();

    for (final field in _fields.values) {
      field.dispose();
    }
  }

  /// Validates each field in [schema] against the corresponding raw value
  /// in [raw], without ever constructing the typed `T` instance.
  ///
  /// Used by the `VForm.object` silent validators to avoid invoking the
  /// user-supplied `builder` on partial forms (which would crash on
  /// non-nullable parameters). Mirrors the field-iteration loop inside
  /// `VObject.safeParse` so the resulting [VError]s look identical:
  /// each error's `path` is prefixed with the field name. Schema-level
  /// rules (`refine`, `refineField`, `refineFieldRaw`, `equalFields`,
  /// `whenRules`, container preprocess) are NOT evaluated here — those
  /// run only on the canonical `object.safeParse(builder(raw))` path,
  /// reached when this helper returns an empty list.
  static List<VError> _objectPerFieldErrorsSync(
    Map<String, VType> schema,
    Map<String, dynamic> raw,
  ) {
    final List<VError> errors = [];

    for (final entry in schema.entries) {
      final result = entry.value.safeParse(raw[entry.key]);

      if (result is VFailure) {
        for (final err in result.errors) {
          errors.add(err.copyWith(path: [entry.key, ...err.path]));
        }
      }
    }

    return errors;
  }

  /// Async variant of [_objectPerFieldErrorsSync]. Falls back to
  /// `safeParse` for fields whose VType is sync-only, so a mixed schema
  /// (some async fields, some sync) still produces consistent errors.
  static Future<List<VError>> _objectPerFieldErrorsAsync(
    Map<String, VType> schema,
    Map<String, dynamic> raw,
  ) async {
    final List<VError> errors = [];

    for (final entry in schema.entries) {
      final result = entry.value.hasAsync
          ? await entry.value.safeParseAsync(raw[entry.key])
          : entry.value.safeParse(raw[entry.key]);

      if (result is VFailure) {
        for (final err in result.errors) {
          errors.add(err.copyWith(path: [entry.key, ...err.path]));
        }
      }
    }

    return errors;
  }

  static VField _createField({
    required VType type,
    required dynamic initialValue,
    required List<String? Function()> validators,
    List<Future<String?> Function()> asyncValidators = const [],
    Object? Function(Object?)? preprocessor,
    Future<Object?> Function(Object?)? preprocessorAsync,
    String? Function()? schemaErrorLookup,
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
        schemaErrorLookup: schemaErrorLookup,
      );
    });
  }
}
