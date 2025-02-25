import 'package:flutter/widgets.dart';
import 'package:valiform/valiform.dart';

extension ValidartExtension on Validart {
  VForm form(
    VMap map, {
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

extension VMapExtension on VMap {
  VForm form({
    GlobalKey<FormState>? formKey,
    Map<String, dynamic>? defaultValues,
  }) {
    return VForm(
      this,
      formKey: formKey,
      defaultValues: defaultValues,
    );
  }
}
