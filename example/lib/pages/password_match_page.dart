import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

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

    // Section 1: Using refineFormField
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

    // Section 2: Using equalFields
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

  // Section 1 fields
  VField<String> get _refinePassword => _refineForm.field('password');
  VField<String> get _refineConfirm => _refineForm.field('confirmPassword');

  // Section 2 fields
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
            _buildRefineFormFieldSection(),
            const Divider(height: 48),
            _buildEqualFieldsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRefineFormFieldSection() {
    return Form(
      key: _refineForm.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Section 1: Using refineFormField',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Text(
              'refineFormField adds validation to both the VMap pipeline AND '
              'individual fields. The error message appears directly on the '
              'target field.',
              style: TextStyle(
                letterSpacing: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(hintText: 'Password'),
            obscureText: true,
            validator: _refinePassword.validator,
            onChanged: _refinePassword.onChanged,
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(hintText: 'Confirm Password'),
            obscureText: true,
            validator: _refineConfirm.validator,
            onChanged: _refineConfirm.onChanged,
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
    );
  }

  Widget _buildEqualFieldsSection() {
    return Form(
      key: _equalFieldsForm.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Section 2: Using equalFields',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Text(
              'equalFields adds validation only to the VMap pipeline. Use '
              'silentValidate() to check. Errors don\'t appear on individual '
              'fields - handle them yourself.',
              style: TextStyle(
                letterSpacing: 1.5,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(hintText: 'Password'),
            obscureText: true,
            validator: _equalPassword.validator,
            onChanged: _equalPassword.onChanged,
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(hintText: 'Confirm Password'),
            obscureText: true,
            validator: _equalConfirm.validator,
            onChanged: _equalConfirm.onChanged,
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
    );
  }
}
