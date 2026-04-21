import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class PasswordMatchPage extends StatefulWidget {
  const PasswordMatchPage({super.key});

  @override
  State<PasswordMatchPage> createState() => _PasswordMatchPageState();
}

class _PasswordMatchPageState extends State<PasswordMatchPage> {
  late final VForm<Map<String, dynamic>> _refineForm;
  late final VForm<Map<String, dynamic>> _equalFieldsForm;

  Map<String, dynamic>? _refineResult;
  Map<String, String>? _refineErrors;

  Map<String, dynamic>? _equalResult;
  Map<String, String>? _equalErrors;

  @override
  void initState() {
    super.initState();

    _refineForm = V
        .map({
          'password': V.string().password(),
          'confirmPassword': V.string().password(),
        })
        .refineFormField(
          (data) => data['password'] == data['confirmPassword'],
          path: 'confirmPassword',
          message: 'Passwords do not match',
        )
        .form();

    _equalFieldsForm = V
        .map({
          'password': V.string().password(),
          'confirmPassword': V.string().password(),
        })
        .equalFields(
          'password',
          'confirmPassword',
          message: 'Passwords must match',
        )
        .form();
  }

  @override
  void dispose() {
    _refineForm.dispose();
    _equalFieldsForm.dispose();

    super.dispose();
  }

  VField<String> get _refinePassword => _refineForm.field('password');
  VField<String> get _refineConfirm => _refineForm.field('confirmPassword');
  VField<String> get _equalPassword => _equalFieldsForm.field('password');
  VField<String> get _equalConfirm => _equalFieldsForm.field('confirmPassword');

  void _submitRefine() {
    setState(() {
      if (_refineForm.validate()) {
        _refineResult = _refineForm.value;
        _refineErrors = null;
      } else {
        _refineResult = null;
        _refineErrors = _refineForm.errors();
      }
    });
  }

  void _submitEqualFields() {
    final fieldsValid = _equalFieldsForm.validate();
    final schemaValid = fieldsValid && _equalFieldsForm.silentValidate();

    setState(() {
      if (schemaValid) {
        _equalResult = _equalFieldsForm.value;
        _equalErrors = null;
      } else {
        _equalResult = null;
        // equalFields errors only show up in silentValidate, not on individual
        // fields — merge a synthetic error into the map so ResultBox.failure
        // has something to render.
        final errs = _equalFieldsForm.errors() ?? <String, String>{};
        if (fieldsValid && !_equalFieldsForm.silentValidate()) {
          errs['_form'] = 'Passwords must match';
        }
        _equalErrors = errs.isEmpty ? null : errs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _refineForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Section 1: Using refineFormField'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'refineFormField adds validation to both the VMap pipeline '
                    'AND individual fields. The error message appears directly '
                    'on the target field.',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: _refinePassword,
                    hint: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _refineConfirm,
                    hint: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitRefine,
                    child: const Text('Submit (refineFormField)'),
                  ),
                  if (_refineResult != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.success(data: _refineResult!),
                  ] else if (_refineErrors != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.failure(errors: _refineErrors!),
                  ],
                ],
              ),
            ),
            const Divider(height: 48),
            Form(
              key: _equalFieldsForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Section 2: Using equalFields'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'equalFields adds validation only to the VMap pipeline. '
                    'Use silentValidate() to check. Errors don\'t appear on '
                    'individual fields — handle them yourself.',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: _equalPassword,
                    hint: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _equalConfirm,
                    hint: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitEqualFields,
                    child: const Text('Submit (equalFields)'),
                  ),
                  if (_equalResult != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.success(data: _equalResult!),
                  ] else if (_equalErrors != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.failure(errors: _equalErrors!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
