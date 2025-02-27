import 'package:flutter/widgets.dart';
import 'package:validart/validart.dart';

/// A form field abstraction for managing validation, state, and UI integration.
///
/// The `VField<T>` class represents a single form field inside a validation schema.
/// It integrates with `Validart` to provide **automatic validation**, **state management**,
/// and **text field controllers** for easy UI handling.
///
/// ### Features
/// - **Automatic Validation**: Ensures values meet defined constraints.
/// - **State Management**: Uses `ValueNotifier` for reactive updates.
/// - **Text Editing Controller**: Manages `TextFormField` bindings (for `String` values).
/// - **Reset & Clear**: Supports resetting to an initial value and clearing fields.
/// - **Disposable**: Ensures resources are properly released.
///
/// ### Example
/// ```dart
/// final form = v.map({
///   'email': v.string().email(),
///   'password': v.string().password(),
/// }).form();
///
/// final VField<String> emailField = form.field('email');
/// final VField<String> passwordField = form.field('password');
///
/// print(emailField.validate()); // Returns true if the value is valid
/// print(emailField.value); // Gets the current value
///
/// emailField.set("new@example.com"); // Updates the value
/// emailField.clear(); // Clears the field
/// ```
class VField<T> {
  /// The validation type associated with this field.
  final VType<T> _type;

  /// Stores the current value of the field.
  final ValueNotifier<T?> _value;

  /// Stores the initial value assigned to the field.
  final T? _initialValue;

  /// A list of additional custom validators.
  final List<String? Function()> _validators;

  /// The `TextEditingController` for managing text-based input fields.
  ///
  /// Only used when `T` is a `String`, otherwise it remains `null`.
  TextEditingController? _controller;

  /// Creates a new `VField<T>` with validation and state management.
  ///
  /// ### Parameters
  /// - `type`: The validation type (`VString`, `VInt`, etc.).
  /// - `validators`: A list of custom validation functions.
  /// - `initialValue`: *(optional)* The starting value for the field.
  VField({
    required VType<T> type,
    required List<String? Function()> validators,
    T? initialValue,
  })  : _type = type,
        _initialValue = initialValue,
        _value = ValueNotifier<T?>(initialValue),
        _validators = validators;

  /// Listenable object for tracking field value changes.
  ///
  /// This allows UI components to listen for updates and rebuild accordingly.
  Listenable get listenable => _value;

  /// Retrieves the current value of the field.
  ///
  /// - If the value is `null`, returns `null`.
  /// - If the value is an **empty string** and the field is **optional**, returns `null`.
  T? get value {
    final val = _value.value;

    if (val == null) return null;
    if (val is String && val.isEmpty && _type.isOptional) return null;

    return val;
  }

  /// Provides a `TextEditingController` for text-based fields.
  ///
  /// If `T` is `String`, this controller allows binding the field to a `TextFormField`.
  ///
  /// ### Example
  /// ```dart
  /// final emailField = v.string().email().form().field('email');
  ///
  /// TextFormField(
  ///   controller: emailField.controller,
  ///   validator: emailField.validator,
  ///   onChanged: emailField.onChanged,
  /// );
  /// ```
  TextEditingController? get controller {
    if (T == String && _controller == null) {
      _controller ??= TextEditingController(text: value?.toString());
    }

    return _controller;
  }

  /// Updates the value of the field programmatically.
  ///
  /// This method also updates the `TextEditingController` (if applicable).
  ///
  /// ### Example
  /// ```dart
  /// emailField.set("new@example.com");
  /// ```
  void set(T? value) {
    _value.value = value;
    _controller?.text = value?.toString() ?? '';
  }

  /// Handles value changes from UI components.
  ///
  /// Typically used in `onChanged` handlers for `TextFormField`.
  void onChanged(T value) {
    _value.value = value;
  }

  /// Handles `onSaved` callback in form fields.
  ///
  /// This method is typically used in `Form.onSaved` handlers.
  void onSaved(T? value) {
    _value.value = value;
  }

  /// Clears the field value.
  ///
  /// - Sets the value to `null`.
  /// - Clears the associated `TextEditingController` (if applicable).
  void clear() {
    _controller?.clear();
    _value.value = null;
  }

  /// Resets the field to its initial value.
  ///
  /// - If an initial value was provided, restores it.
  /// - Updates the `TextEditingController` (if applicable).
  void reset() {
    _value.value = _initialValue;
    _controller?.text = _initialValue?.toString() ?? '';
  }

  /// Validates the current value using all registered validators.
  ///
  /// - Runs the built-in validation from `_type`.
  /// - Runs additional custom validators.
  ///
  /// ### Example
  /// ```dart
  /// final emailField = v.string().email().form().field('email');
  ///
  /// print(emailField.validator("invalid-email")); // "Enter a valid email"
  /// ```
  ///
  /// ### Returns
  /// - `null` if the value is valid.
  /// - An error message if the value is invalid.
  String? validator(T? value) {
    final error = _type.getErrorMessage(value) as String?;

    if (error != null) return error;

    for (final validator in _validators) {
      final message = validator();

      if (message != null) return message;
    }

    return null;
  }

  /// Returns `true` if the current value passes validation.
  ///
  /// This method uses the `VType.validate()` function for validation.
  ///
  /// ### Example
  /// ```dart
  /// if (emailField.validate()) {
  ///   print("Valid email!");
  /// }
  /// ```
  bool validate() => _type.validate(value);

  /// Disposes of the field, freeing resources.
  ///
  /// - Disposes the `TextEditingController` (if applicable).
  /// - Disposes the `ValueNotifier`.
  ///
  /// **Must be called when the field is no longer needed** to prevent memory leaks.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void dispose() {
  ///   emailField.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    _controller?.dispose();
    _value.dispose();
  }
}
