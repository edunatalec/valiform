import 'package:flutter/widgets.dart';
import 'package:validart/validart.dart';

class VField<T> {
  final VType<T> _type;
  final ValueNotifier<T?> _value;
  final T? _initialValue;

  TextEditingController? _controller;

  VField({
    required VType<T> type,
    T? initialValue,
  })  : _type = type,
        _initialValue = initialValue,
        _value = ValueNotifier<T?>(initialValue);

  Listenable get listenable => _value;

  T? get value {
    final val = _value.value;

    if (val == null) return null;
    if (val is String && val.isEmpty && _type.isOptional) return null;

    return val;
  }

  TextEditingController? get controller {
    if (T is String) {
      _controller ??= TextEditingController(text: value?.toString());
    }

    return _controller;
  }

  void set(T? value) {
    _value.value = value;
    _controller?.text = value?.toString() ?? '';
  }

  void onChanged(T value) {
    _value.value = value;
  }

  void onSaved(T? value) {
    _value.value = value;
  }

  void clear() {
    _controller?.clear();
    _value.value = null;
  }

  void reset() {
    _value.value = _initialValue;
    _controller?.text = _initialValue?.toString() ?? '';
  }

  String? validator(T? value) => _type.getErrorMessage(value) as String?;

  bool validate() => _type.validate(value);

  void dispose() {
    _value.dispose();
    _controller?.dispose();
  }
}
