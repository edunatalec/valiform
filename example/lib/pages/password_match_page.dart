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
        .refineField(
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
    setState(() {
      // form.validate() covers both per-field and schema-level rules
      // (equalFields emits a root-level error and is included).
      if (_equalFieldsForm.validate()) {
        _equalResult = _equalFieldsForm.value;
        _equalErrors = null;
      } else {
        _equalResult = null;
        // Field-keyed errors stay in errors(); the equalFields mismatch is
        // root-level and is rendered by the RootErrorBanner above the fields.
        _equalErrors = _equalFieldsForm.errors();
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
                  const SectionTitle('Section 1: Using refineField'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'refineField attaches a path-keyed cross-field check to '
                    'the schema. Because the path is declared, VForm demuxes '
                    'the error and surfaces it inline under the target field.',
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
                    child: const Text('Submit (refineField)'),
                  ),
                  ResultFeedback(data: _refineResult, errors: _refineErrors),
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
                    'equalFields emits a root-level error (no field path). '
                    'Render it as a banner via form.rootErrors instead of '
                    'looking for it in form.errors() — that map only carries '
                    'field-keyed errors.',
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _equalFieldsForm.listenable,
                    builder: (context, _) {
                      final root = _equalFieldsForm.rootErrors;
                      if (root.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RootErrorBanner(messages: root),
                      );
                    },
                  ),
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
                  ResultFeedback(data: _equalResult, errors: _equalErrors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
