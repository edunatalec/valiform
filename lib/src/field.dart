import 'package:flutter/widgets.dart';
import 'package:validart/validart.dart';

/// A form field abstraction for managing validation and state.
///
/// The `VField<T>` class represents a single form field inside a validation schema.
/// It provides **automatic validation** and **state management** via `ValueNotifier`.
///
/// A controller can be attached optionally for bidirectional synchronization:
/// - [attachController] accepts a `ValueNotifier<T?>` (or any subclass, like
///   `LuneSelectFieldController<T>`).
/// - `attachTextController` (via extension on `VField<String>`) accepts a
///   `TextEditingController`.
/// - [onValueChanged] takes a callback and invokes it on every value change —
///   useful for bridging to external state that isn't a `ValueNotifier<T?>`.
class VField<T> {
  final VType<T> _type;
  final ValueNotifier<T?> _value;
  final T? _initialValue;
  final List<String? Function()> _validators;
  final List<Future<String?> Function()> _asyncValidators;
  late final bool _acceptsNull = _type.isNullable;

  /// Attach this key to the corresponding `TextFormField` (or any
  /// `FormField`) to enable single-field revalidation via [setError].
  /// Without it, errors set imperatively only surface on the next full
  /// `VForm.validate()` call.
  final GlobalKey<FormFieldState<T>> key = GlobalKey<FormFieldState<T>>();

  ValueNotifier<T?>? _attachedController;
  TextEditingController? _attachedTextController;
  bool _ownsAttachedController = false;
  bool _syncing = false;
  final List<VoidCallback> _onValueChangedListeners = [];

  String? _manualError;
  bool _persistManualError = false;
  bool _forceManualError = false;

  /// Creates a new [VField] with the given [type], [validators], and optional [initialValue].
  VField({
    required VType<T> type,
    required List<String? Function()> validators,
    List<Future<String?> Function()> asyncValidators = const [],
    T? initialValue,
  })  : _type = type,
        _initialValue = initialValue,
        _value = ValueNotifier<T?>(initialValue),
        _validators = validators,
        _asyncValidators = asyncValidators;

  /// Listenable for tracking field value changes.
  Listenable get listenable => _value;

  /// Whether this field has any async-only validation step — either the
  /// underlying [VType] contains `refineAsync`/`preprocessAsync`/
  /// `transformAsync`, or a conditional (`.when()`) rule targeting this
  /// field points at an async type.
  ///
  /// When `true`, the synchronous inspection methods ([validate], [error],
  /// [vError], [parsedValue]) throw [VAsyncRequiredException] — use the
  /// `*Async` variants. The sole exception is [validator], the required
  /// adapter for Flutter's synchronous `FormField.validator`.
  bool get hasAsync => _type.hasAsync || _asyncValidators.isNotEmpty;

  /// The current value of the field.
  /// The current raw value of the field (as stored, without transforms).
  T? get value {
    final val = _value.value;

    if (val == null) return null;
    if (val is String && val.isEmpty && _acceptsNull) return null;

    return val;
  }

  /// The current value after running through the validation pipeline
  /// (transforms like trim, toLowerCase, etc. are applied).
  ///
  /// Returns the raw value if parsing fails.
  ///
  /// Throws [VAsyncRequiredException] when the schema contains async
  /// steps — use [parsedValueAsync] instead.
  T? get parsedValue {
    if (hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VField.parsedValue',
        suggestion: 'parsedValueAsync',
      );
    }

    final result = _type.safeParse(value);

    if (result case VSuccess<T?>(value: final parsed)) return parsed;

    return value;
  }

  /// Async variant of [parsedValue]: runs the full pipeline, including
  /// async preprocessors and transforms. Returns the raw value if parsing
  /// fails.
  Future<T?> get parsedValueAsync async {
    final result = await _type.safeParseAsync(value);

    if (result case VSuccess<T?>(value: final parsed)) return parsed;

    return value;
  }

  /// Attaches a `ValueNotifier<T?>` for bidirectional synchronization.
  ///
  /// When the controller's value changes, the field value updates. When [set]
  /// or [reset] are called, the controller updates.
  ///
  /// By default (`owns: true`), the field takes ownership and disposes the
  /// controller when [dispose] is called — enabling the inline pattern:
  ///
  /// ```dart
  /// field.attachController(ValueNotifier<int?>(null));
  /// // or for custom controllers that extend ValueNotifier<T?>:
  /// field.attachController(LuneSelectFieldController<Country>());
  /// ```
  ///
  /// Pass `owns: false` when the controller's lifecycle is managed externally.
  ///
  /// For `TextEditingController`, use `attachTextController` (extension on
  /// `VField<String>`) since its value type is `TextEditingValue`, not `T?`.
  void attachController(ValueNotifier<T?> controller, {bool owns = true}) {
    final previouslyOwned = _ownsAttachedController
        ? (_attachedTextController ?? _attachedController)
        : null;

    detachController();

    if (previouslyOwned != null && !identical(previouslyOwned, controller)) {
      previouslyOwned.dispose();
    }

    _ownsAttachedController = owns;
    _attachedController = controller;

    controller.addListener(_onControllerChanged);
    _value.addListener(_onValueChanged);
  }

  /// The `ValueNotifier<T?>` currently attached via [attachController], or
  /// `null` if none. For `TextEditingController` on `VField<String>`, use
  /// `textController` (from the string extension).
  ValueNotifier<T?>? get controller => _attachedController;

  /// Registers a callback invoked whenever the field value changes, receiving
  /// the typed value. Use this to bridge to external state that isn't a
  /// `ValueNotifier<T?>` — for instance, pushing the value into a
  /// `TextEditingController` manually or forwarding it to analytics.
  ///
  /// Does NOT fire immediately with the current value — only on subsequent
  /// changes. Returns a dispose function that removes the listener.
  ///
  /// ```dart
  /// final dispose = field.onValueChanged((value) {
  ///   myController.text = value ?? '';
  /// });
  /// // later: dispose();
  /// ```
  VoidCallback onValueChanged(void Function(T? value) callback) {
    void wrapper() => callback(value);

    _value.addListener(wrapper);
    _onValueChangedListeners.add(wrapper);

    return () {
      if (_onValueChangedListeners.remove(wrapper)) {
        _value.removeListener(wrapper);
      }
    };
  }

  /// Detaches any attached controller, removing all listeners. Does NOT
  /// dispose the controller (even if the field owns it); that happens in
  /// [dispose].
  void detachController() {
    if (_attachedController != null) {
      _attachedController!.removeListener(_onControllerChanged);
      _value.removeListener(_onValueChanged);

      _attachedController = null;
    }

    if (_attachedTextController != null) {
      _attachedTextController!.removeListener(_onTextControllerChanged);
      _value.removeListener(_onValueChangedForText);

      _attachedTextController = null;
    }

    _ownsAttachedController = false;
  }

  void _onControllerChanged() {
    if (_syncing) return;

    final T? newValue = _attachedController!.value;
    if (_value.value == newValue) return;

    _syncing = true;
    _value.value = newValue;
    _syncing = false;
  }

  void _onValueChanged() {
    if (_syncing) return;
    if (_attachedController!.value == _value.value) return;

    _syncing = true;
    _attachedController!.value = _value.value;
    _syncing = false;
  }

  void _onTextControllerChanged() {
    if (_syncing) return;

    final newValue = _attachedTextController!.text as T;
    if (_value.value == newValue) return;

    _syncing = true;
    _value.value = newValue;
    _syncing = false;
  }

  void _onValueChangedForText() {
    if (_syncing) return;

    final String newText = _value.value?.toString() ?? '';
    if (_attachedTextController!.text == newText) return;

    _syncing = true;
    _attachedTextController!.text = newText;
    _syncing = false;
  }

  /// Updates the value of the field programmatically.
  void set(T? value) {
    _value.value = value;
  }

  /// Handles value changes from UI components.
  ///
  /// Accepts `T?` so it can be wired directly to widgets whose `onChanged`
  /// passes a nullable value (e.g. `DropdownButtonFormField`), not just
  /// `TextFormField`.
  void onChanged(T? value) {
    _value.value = value;
  }

  /// Handles `onSaved` callback in form fields.
  void onSaved(T? value) {
    _value.value = value;
  }

  /// Resets the field to its initial value.
  void reset() {
    _value.value = _initialValue;
  }

  /// The imperatively-set error message currently attached to this field,
  /// or `null` if none.
  String? get manualError => _manualError;

  /// Sets an imperative error message on this field.
  ///
  /// - `persist: false` (default) — one-shot: surfaces on the next [validator]
  ///   call and is cleared on it, even when a standard validator takes
  ///   precedence (prevents ghost errors).
  /// - `persist: true` — the error stays until [clearError] is called.
  /// - `force: false` (default) — standard validators win precedence; the
  ///   manual error only appears when the field is otherwise valid.
  /// - `force: true` — the manual error takes precedence over standard
  ///   validators for this setError, so you can flag a field even while it
  ///   would otherwise fail its own rules.
  ///
  /// If [key] is attached to a `TextFormField`, this triggers
  /// revalidation of that single field only — other fields are untouched.
  void setError(String message, {bool persist = false, bool force = false}) {
    _manualError = message;
    _persistManualError = persist;
    _forceManualError = force;

    key.currentState?.validate();
  }

  /// Clears the imperative error (if any) and refreshes the attached
  /// `TextFormField` so any cached error text disappears from the UI.
  void clearError() {
    _manualError = null;
    _persistManualError = false;
    _forceManualError = false;

    key.currentState?.validate();
  }

  /// Validates the given value using all registered validators.
  ///
  /// Returns `null` if valid, or an error message if invalid.
  /// Called by Flutter's `FormField` pipeline — consumes one-shot manual
  /// errors as a side effect.
  ///
  /// **Does NOT throw on async schemas.** This is the one sync adapter
  /// the Flutter `FormField.validator` signature requires. It runs only
  /// the synchronous extras (cross-field validators + `manualError`) and
  /// is the channel [VForm.validateAsync] uses to surface async errors
  /// via `setError(persist: true)`.
  String? validator(T? value) => _runValidators(value, consume: true);

  /// Returns `true` if the current value passes all validators.
  ///
  /// Read-only: unlike [validator], this does NOT consume one-shot manual
  /// errors. Call it as many times as you like without affecting state.
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [validateAsync].
  bool validate() {
    if (hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VField.validate',
        suggestion: 'validateAsync',
      );
    }
    return _runValidators(value, consume: false) == null;
  }

  /// Async variant of [validate]: runs the full pipeline (sync + async
  /// steps) and every registered extra validator. Does NOT consume
  /// one-shot manual errors.
  Future<bool> validateAsync() async =>
      (await _runValidatorsAsync(value)) == null;

  /// Internal: runs only schema + extra validators asynchronously,
  /// ignoring any `manualError`. Used by `VForm.validateAsync` which
  /// manages manual errors itself (so stale async errors don't mask a
  /// newly-valid value).
  Future<String?> computeAsyncError() async {
    final value = this.value;
    final processed = value is String && value.isEmpty ? null : value;

    final stdError = (await _type.errorsAsync(processed))?.firstOrNull?.message;
    if (stdError != null) return stdError;

    for (final fn in _validators) {
      final message = fn();
      if (message != null) return message;
    }

    for (final fn in _asyncValidators) {
      final message = await fn();
      if (message != null) return message;
    }

    return null;
  }

  /// The current error message for this field (from standard validators,
  /// cross-field validators, or imperative errors) — or `null` if valid.
  ///
  /// Read-only: does NOT consume one-shot manual errors. Use this to
  /// inspect the state without mutating it.
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [errorAsync].
  String? get error {
    if (hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VField.error',
        suggestion: 'errorAsync',
      );
    }
    return _runValidators(value, consume: false);
  }

  /// Async variant of [error]: runs async schema validation too.
  Future<String?> get errorAsync => _runValidatorsAsync(value);

  /// Returns the full list of [VError]s for this field's current value,
  /// preserving each error's `code`, `path`, and `message` — or `null` if
  /// valid. Useful for array fields where the path contains the failing
  /// element's index.
  ///
  /// Cross-field and imperative errors are wrapped as `VError(code:
  /// VCode.custom, message: ...)` since they're produced outside validart.
  ///
  /// Read-only: does NOT consume one-shot manual errors.
  ///
  /// Throws [VAsyncRequiredException] when [hasAsync] is `true` — use
  /// [vErrorAsync].
  List<VError>? get vError {
    if (hasAsync) {
      throw const VAsyncRequiredException(
        methodName: 'VField.vError',
        suggestion: 'vErrorAsync',
      );
    }
    return _buildVError(_stdErrorsSync(), null);
  }

  /// Async variant of [vError]: includes errors produced by async schema
  /// steps and async extra validators.
  Future<List<VError>?> get vErrorAsync async {
    final stdErrors = await _stdErrorsAsync();
    String? asyncExtra;
    for (final fn in _asyncValidators) {
      final message = await fn();
      if (message != null) {
        asyncExtra = message;
        break;
      }
    }
    return _buildVError(stdErrors, asyncExtra);
  }

  List<VError>? _stdErrorsSync() {
    if (_type.hasAsync) return null;

    final value = this.value;
    final processed = value is String && value.isEmpty ? null : value;

    return _type.errors(processed);
  }

  Future<List<VError>?> _stdErrorsAsync() async {
    final value = this.value;
    final processed = value is String && value.isEmpty ? null : value;

    return _type.errorsAsync(processed);
  }

  List<VError>? _buildVError(List<VError>? stdErrors, String? asyncExtra) {
    String? extraError;

    for (final fn in _validators) {
      final message = fn();
      if (message != null) {
        extraError = message;
        break;
      }
    }

    extraError ??= asyncExtra;

    final manual = _manualError;
    final forced = _forceManualError;

    if (forced && manual != null) {
      return [VError(code: VCode.custom, message: manual)];
    }

    if (stdErrors != null && stdErrors.isNotEmpty) return stdErrors;

    if (extraError != null) {
      return [VError(code: VCode.custom, message: extraError)];
    }

    if (manual != null) {
      return [VError(code: VCode.custom, message: manual)];
    }

    return null;
  }

  String? _runValidators(T? value, {required bool consume}) {
    final processed = value is String && value.isEmpty ? null : value;
    final stdError = _type.hasAsync
        ? null
        : _type.errors(processed)?.firstOrNull?.message;

    String? extraError;

    for (final fn in _validators) {
      final message = fn();
      if (message != null) {
        extraError = message;
        break;
      }
    }

    final manual = _manualError;
    final forced = _forceManualError;

    if (consume && manual != null && !_persistManualError) {
      _manualError = null;
      _forceManualError = false;
    }

    if (forced && manual != null) return manual;

    return stdError ?? extraError ?? manual;
  }

  Future<String?> _runValidatorsAsync(T? value) async {
    final processed = value is String && value.isEmpty ? null : value;
    final stdError = (await _type.errorsAsync(processed))?.firstOrNull?.message;

    String? extraError;

    for (final fn in _validators) {
      final message = fn();
      if (message != null) {
        extraError = message;
        break;
      }
    }

    if (extraError == null) {
      for (final fn in _asyncValidators) {
        final message = await fn();
        if (message != null) {
          extraError = message;
          break;
        }
      }
    }

    final manual = _manualError;
    final forced = _forceManualError;

    if (forced && manual != null) return manual;

    return stdError ?? extraError ?? manual;
  }

  /// Disposes of the field, freeing resources.
  ///
  /// Detaches any attached controller. If the field owns the controller
  /// (default when attached via [attachController] or `attachTextController`),
  /// it's disposed too. Removes any [onValueChanged] listeners still active
  /// and always disposes the internal `ValueNotifier`.
  void dispose() {
    for (final listener in _onValueChangedListeners) {
      _value.removeListener(listener);
    }

    _onValueChangedListeners.clear();

    final ownedText = _ownsAttachedController ? _attachedTextController : null;
    final ownedValue = _ownsAttachedController ? _attachedController : null;

    detachController();

    ownedText?.dispose();
    ownedValue?.dispose();
    _value.dispose();
  }
}

/// `TextEditingController` integration for `VField<String>`. Adds a
/// specialized attach method and a typed getter, since `TextEditingController`
/// exposes its value as `TextEditingValue` rather than `String`.
extension VFieldStringController on VField<String> {
  /// Attaches a `TextEditingController` for bidirectional sync with this
  /// `VField<String>`. Same ownership semantics as [attachController] —
  /// defaults to `owns: true`, so the controller is disposed together with
  /// the field.
  void attachTextController(
    TextEditingController controller, {
    bool owns = true,
  }) {
    // Extension is statically constrained to VField<String>, so T is always
    // String here — no runtime type check needed.
    final previouslyOwned = _ownsAttachedController
        ? (_attachedTextController ?? _attachedController)
        : null;

    detachController();

    if (previouslyOwned != null && !identical(previouslyOwned, controller)) {
      previouslyOwned.dispose();
    }

    _ownsAttachedController = owns;
    _attachedTextController = controller;

    controller.addListener(_onTextControllerChanged);
    _value.addListener(_onValueChangedForText);
  }

  /// The attached `TextEditingController`, or `null` if none.
  TextEditingController? get textController => _attachedTextController;
}
