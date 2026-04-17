import 'package:flutter/widgets.dart';
import 'package:validart/validart.dart';

/// A form field abstraction for managing validation and state.
///
/// The `VField<T>` class represents a single form field inside a validation schema.
/// It provides **automatic validation** and **state management** via `ValueNotifier`.
///
/// Controllers can be attached optionally for bidirectional synchronization:
/// - [attachController] for any `ValueNotifier<T?>`
/// - [attachTextController] for `TextEditingController` (String fields only)
class VField<T> {
  final VType<T> _type;
  final ValueNotifier<T?> _value;
  final T? _initialValue;
  final List<String? Function()> _validators;

  /// Attach this key to the corresponding `TextFormField` (or any
  /// `FormField`) to enable single-field revalidation via [setError].
  /// Without it, errors set imperatively only surface on the next full
  /// `VForm.validate()` call.
  final GlobalKey<FormFieldState<T>> formFieldKey =
      GlobalKey<FormFieldState<T>>();

  ValueNotifier<T?>? _attachedController;
  TextEditingController? _attachedTextController;
  bool _syncing = false;

  String? _manualError;
  bool _persistManualError = false;
  bool _forceManualError = false;

  /// Creates a new [VField] with the given [type], [validators], and optional [initialValue].
  VField({
    required VType<T> type,
    required List<String? Function()> validators,
    T? initialValue,
  })  : _type = type,
        _initialValue = initialValue,
        _value = ValueNotifier<T?>(initialValue),
        _validators = validators;

  /// Listenable for tracking field value changes.
  Listenable get listenable => _value;

  /// The current value of the field.
  /// The current raw value of the field (as stored, without transforms).
  T? get value {
    final val = _value.value;

    if (val == null) return null;
    if (val is String && val.isEmpty && _type.validate(null)) return null;

    return val;
  }

  /// The current value after running through the validation pipeline
  /// (transforms like trim, toLowerCase, etc. are applied).
  ///
  /// Returns the raw value if parsing fails.
  T? get parsedValue {
    final result = _type.safeParse(value);

    if (result case VSuccess<T?>(:final value)) return value;

    return value;
  }

  /// Attaches a `ValueNotifier<T?>` for bidirectional synchronization.
  ///
  /// When the controller value changes, the field value updates.
  /// When `set`, `clear`, or `reset` are called, the controller updates.
  ///
  /// The caller is responsible for disposing the controller.
  void attachController(ValueNotifier<T?> controller) {
    detachController();
    _attachedController = controller;
    controller.addListener(_onControllerChanged);
    _value.addListener(_onValueChanged);
  }

  /// Attaches a `TextEditingController` for bidirectional synchronization.
  ///
  /// Only works when `T` is `String`. Converts between `String` and the
  /// controller's text property automatically.
  ///
  /// The caller is responsible for disposing the controller.
  void attachTextController(TextEditingController controller) {
    detachController();
    _attachedTextController = controller;
    controller.addListener(_onTextControllerChanged);
    _value.addListener(_onValueChangedForText);
  }

  /// Detaches any attached controller, removing all listeners.
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
  }

  void _onControllerChanged() {
    if (_syncing) return;
    final newValue = _attachedController!.value;
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
    final newValue = _attachedTextController!.text as T?;
    if (_value.value == newValue) return;
    _syncing = true;
    _value.value = newValue;
    _syncing = false;
  }

  void _onValueChangedForText() {
    if (_syncing) return;
    final newText = _value.value?.toString() ?? '';
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
  void onChanged(T value) {
    _value.value = value;
  }

  /// Handles `onSaved` callback in form fields.
  void onSaved(T? value) {
    _value.value = value;
  }

  /// Clears the field value to `null`.
  void clear() {
    _value.value = null;
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
  /// If [formFieldKey] is attached to a `TextFormField`, this triggers
  /// revalidation of that single field only — other fields are untouched.
  void setError(String message, {bool persist = false, bool force = false}) {
    _manualError = message;
    _persistManualError = persist;
    _forceManualError = force;
    formFieldKey.currentState?.validate();
  }

  /// Clears the imperative error (if any) and refreshes the attached
  /// `TextFormField` so any cached error text disappears from the UI.
  void clearError() {
    _manualError = null;
    _persistManualError = false;
    _forceManualError = false;
    formFieldKey.currentState?.validate();
  }

  /// Validates the given value using all registered validators.
  ///
  /// Returns `null` if valid, or an error message if invalid.
  String? validator(T? value) {
    final processed = value is String && value.isEmpty ? null : value;
    final stdError = _type.errors(processed)?.firstOrNull?.message;

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
    if (manual != null && !_persistManualError) {
      _manualError = null;
      _forceManualError = false;
    }

    if (forced && manual != null) return manual;
    return stdError ?? extraError ?? manual;
  }

  /// Returns `true` if the current value passes validation.
  bool validate() => _type.validate(value);

  /// Disposes of the field, freeing resources.
  ///
  /// Detaches any attached controller (without disposing it)
  /// and disposes the internal `ValueNotifier`.
  void dispose() {
    detachController();
    _value.dispose();
  }
}
