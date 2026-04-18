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
                    onPressed: () {
                      if (_refineForm.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords match!')),
                        );
                      }
                    },
                    child: const Text('Submit (refineFormField)'),
                  ),
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
                    onPressed: () {
                      final fieldsValid = _equalFieldsForm.validate();

                      if (fieldsValid && !_equalFieldsForm.silentValidate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords must match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (fieldsValid && _equalFieldsForm.silentValidate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords match!')),
                        );
                      }
                    },
                    child: const Text('Submit (equalFields)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
