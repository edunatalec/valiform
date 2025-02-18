import 'package:valiform/src/field.dart';
import 'package:flutter/widgets.dart';
import 'package:validart/validart.dart';

class VForm {
  final VMap _map;
  final GlobalKey<FormState> _formKey;
  final Map<String, VField> _fields = {};
  final Map<String, dynamic> _defaultValues = {};

  VForm(
    Map<String, VType> map, {
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
  })  : assert(map.isNotEmpty, 'Map must have at least one field.'),
        _formKey = formKey ?? GlobalKey<FormState>(),
        _map = VMap(map, MapMessage()) {
    if (defaultValues != null) {
      _defaultValues.addAll(defaultValues);
    }

    for (final entry in map.entries) {
      if (entry.value is VString) {
        _fields[entry.key] = VField<String>(
          type: entry.value as VString,
          initialValue: defaultValues?[entry.key],
        );
      } else if (entry.value is VInt) {
        _fields[entry.key] = VField<int>(
          type: entry.value as VInt,
          initialValue: defaultValues?[entry.key],
        );
      } else if (entry.value is VDouble) {
        _fields[entry.key] = VField<double>(
          type: entry.value as VDouble,
          initialValue: defaultValues?[entry.key],
        );
      } else if (entry.value is VNum) {
        _fields[entry.key] = VField<num>(
          type: entry.value as VNum,
          initialValue: defaultValues?[entry.key],
        );
      } else if (entry.value is VBool) {
        _fields[entry.key] = VField<bool>(
          type: entry.value as VBool,
          initialValue: defaultValues?[entry.key],
        );
      }
    }
  }

  GlobalKey<FormState> get key => _formKey;

  Listenable get listenable {
    return Listenable.merge(
      _fields.entries.map((entry) {
        return entry.value.listenable;
      }),
    );
  }

  Map<String, dynamic> get value {
    return _fields.map((key, control) => MapEntry(key, control.value));
  }

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

    return _fields[key] as VField<T>;
  }

  void save() => _formKey.currentState?.save();

  void reset() {
    _formKey.currentState?.reset();

    for (final entry in _fields.entries) {
      entry.value.reset();
    }
  }

  void clear() {
    _formKey.currentState?.reset();

    for (final entry in _fields.entries) {
      entry.value.clear();
    }
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  bool silentValidate() => _map.validate(value);

  void dispose() {
    for (final entry in _fields.entries) {
      entry.value.dispose();
    }
  }
}
