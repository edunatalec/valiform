import 'package:flutter/widgets.dart';
import 'package:valiform/valiform.dart';

extension ValidartExtension on Validart {
  VForm form(
    Map<String, VType> map, {
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
  }) {
    return VForm(
      map,
      formKey: formKey,
      defaultValues: defaultValues,
    );
  }
}
