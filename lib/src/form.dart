import 'package:valiform/src/field.dart';
import 'package:flutter/widgets.dart';
import 'package:validart/validart.dart';

/// A form manager that integrates validation, state management, and input handling.
///
/// The `VForm` class represents a **validatable form** that holds multiple fields (`VField<T>`).
/// It is built on top of `Validart` and provides utilities for:
/// - **Field validation and error handling**.
/// - **State management using `GlobalKey<FormState>`**.
/// - **Automatic form reset, clear, and disposal**.
/// - **Listening to field changes** for UI updates.
///
/// ### Features
/// - **Automatic Field Validation**: Ensures that fields follow their validation rules.
/// - **Global Form Key**: Integrates seamlessly with Flutter’s `Form` widget.
/// - **Custom Initial Values**: Allows setting default field values.
/// - **Typed Field Access**: Retrieves `VField<T>` safely with `field<T>()`.
///
/// ### Example
/// ```dart
/// final form = v.map({
///   'email': v.string().email(),
///   'password': v.string().password(),
/// }).form();
///
/// final emailField = form.field<String>('email');
///
/// print(emailField.validate()); // Returns true if valid
/// print(form.validate()); // Returns true if all fields are valid
///
/// form.reset(); // Resets to initial values
/// form.clear(); // Clears all fields
/// form.dispose(); // Cleans up resources
/// ```
class VForm {
  /// The underlying `VMap` validation schema for the form.
  final VMap _map;

  /// The form state key, used for integrating with Flutter's `Form` widget.
  final GlobalKey<FormState> _formKey;

  /// A collection of form fields, mapped by field name.
  final Map<String, VField> _fields = {};

  /// Stores the initial default values for the form.
  final Map<String, dynamic> _defaultValues = {};

  /// Creates a new `VForm` instance from a `VMap` schema.
  ///
  /// - [formKey]: *(optional)* A custom `GlobalKey<FormState>` to use.
  /// - [defaultValues]: *(optional)* A map of initial values for form fields.
  ///
  /// ### Example
  /// ```dart
  /// final form = v.map({
  ///   'email': v.string().email(),
  ///   'age': v.int().min(18),
  /// }).form(defaultValues: {'email': 'user@example.com', 'age': 25});
  /// ```
  VForm(
    this._map, {
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
  }) : _formKey = formKey ?? GlobalKey<FormState>() {
    if (defaultValues != null) {
      _defaultValues.addAll(defaultValues);
    }

    // Initializes fields based on the validation map.
    for (final entry in _map.object.entries) {
      final key = entry.key;
      final type = entry.value;

      final validators = _map.validators
          .where((validator) =>
              validator is RefineMapValidator && validator.path == key)
          .map((validator) => () => validator.validate(value))
          .toList();

      if (type is VString) {
        _fields[key] = VField<String>(
          type: type,
          initialValue: defaultValues?[key],
          validators: validators,
        );
      } else if (type is VInt) {
        _fields[key] = VField<int>(
          type: type,
          initialValue: defaultValues?[key],
          validators: validators,
        );
      } else if (type is VDouble) {
        _fields[key] = VField<double>(
          type: type,
          initialValue: defaultValues?[key],
          validators: validators,
        );
      } else if (type is VNum) {
        _fields[key] = VField<num>(
          type: type,
          initialValue: defaultValues?[key],
          validators: validators,
        );
      } else if (type is VBool) {
        _fields[key] = VField<bool>(
          type: type,
          initialValue: defaultValues?[key],
          validators: validators,
        );
      } else if (type is VDate) {
        _fields[key] = VField<DateTime>(
          type: type,
          initialValue: defaultValues?[key],
          validators: validators,
        );
      }
    }
  }

  /// The global form key used for managing form state.
  ///
  /// This key can be used inside a `Form` widget:
  /// ```dart
  /// Form(
  ///   key: form.key,
  ///   child: Column(
  ///     children: [
  ///       TextFormField(controller: form.field<String>('email').controller),
  ///     ],
  ///   ),
  /// )
  /// ```
  GlobalKey<FormState> get key => _formKey;

  /// A combined `Listenable` object for detecting changes across all fields.
  ///
  /// Can be used with `ValueListenableBuilder` to update UI reactively.
  Listenable get listenable {
    return Listenable.merge(
      _fields.values.map((field) => field.listenable),
    );
  }

  /// Retrieves the current values of all fields as a `Map<String, dynamic>`.
  ///
  /// ```dart
  /// print(form.value); // {'email': 'user@example.com', 'age': 25}
  /// ```
  Map<String, dynamic> get value {
    return _fields.map((key, field) => MapEntry(key, field.value));
  }

  /// Retrieves a specific form field by its key.
  ///
  /// Ensures type safety, throwing an error if the type does not match.
  ///
  /// ```dart
  /// final emailField = form.field<String>('email');
  /// ```
  ///
  /// ### Throws:
  /// - `ArgumentError` if the field does not exist.
  /// - `ArgumentError` if the field type does not match the expected type.
  VField<T> field<T>(String key) {
    final field = _fields[key];

    if (field == null) {
      throw ArgumentError('The field "$key" does not exist.');
    }

    if (field is! VField<T>) {
      throw ArgumentError(
        'The field "$key" is of type ${field.runtimeType}, not VField<$T>.',
      );
    }

    return field;
  }

  /// Calls `onSaved` on all fields, saving the current form state.
  void save() => _formKey.currentState?.save();

  /// Resets all form fields to their initial values.
  ///
  /// ```dart
  /// form.reset(); // Restores default values
  /// ```
  void reset() {
    _formKey.currentState?.reset();
    for (final field in _fields.values) {
      field.reset();
    }
  }

  /// Clears all fields in the form.
  ///
  /// ```dart
  /// form.clear(); // Empties all fields
  /// ```
  void clear() {
    _formKey.currentState?.reset();
    for (final field in _fields.values) {
      field.clear();
    }
  }

  /// Validates all form fields and returns `true` if all fields are valid.
  ///
  /// ```dart
  /// bool isValid = form.validate();
  /// ```
  bool validate() => _formKey.currentState?.validate() ?? false;

  /// Performs validation **without triggering UI error messages**.
  ///
  /// This is useful for checking field validity without displaying errors.
  ///
  /// ```dart
  /// bool isValid = form.silentValidate();
  /// ```
  bool silentValidate() => _map.validate(value);

  /// Disposes all fields and releases resources.
  ///
  /// This method **must** be called when the form is no longer needed.
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   form.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
  }
}
