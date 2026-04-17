import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

class BasicMapFormPage extends StatefulWidget {
  const BasicMapFormPage({super.key});

  @override
  State<BasicMapFormPage> createState() => _BasicMapFormPageState();
}

class _BasicMapFormPageState extends State<BasicMapFormPage> {
  late final VForm<Map<String, dynamic>> _form;
  late final VForm<Map<String, dynamic>> _defaultForm;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'email': V.string().email(),
      'password': V.string().password(),
    }).form();

    _defaultForm = V.map({
      'email': V.string().email(),
      'password': V.string().password(),
    }).form(
      initialValues: {'email': 'user@example.com', 'password': 'Aa1@aaaa'},
    );
  }

  @override
  void dispose() {
    _form.dispose();
    _defaultForm.dispose();
    super.dispose();
  }

  VField<String> get _email => _form.field('email');
  VField<String> get _password => _form.field('password');
  VField<String> get _defEmail => _defaultForm.field('email');
  VField<String> get _defPassword => _defaultForm.field('password');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Map Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBasicSection(),
            const Divider(height: 48),
            _buildDefaultValuesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    return Form(
      key: _form.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Without Default Values',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const InfoCard(
            'The simplest way to create a form with Valiform. A VMap schema '
            'defines email and password fields with built-in validation. '
            'The .form() extension converts it into a VForm. No controller '
            'needed — just wire onChanged and validator to TextFormField.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            onChanged: _email.onChanged,
            validator: _email.validator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            onChanged: _password.onChanged,
            validator: _password.validator,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_form.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Submitted: ${_form.value}')),
                );
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultValuesSection() {
    return Form(
      key: _defaultForm.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'With Default Values',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const InfoCard(
            'Pass initialValues to .form() to set initial field values. '
            'Fields start pre-filled. Calling form.reset() restores them '
            'to the default values.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            initialValue: _defEmail.value,
            onChanged: _defEmail.onChanged,
            validator: _defEmail.validator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            initialValue: _defPassword.value,
            onChanged: _defPassword.onChanged,
            validator: _defPassword.validator,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _defaultForm.reset(),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_defaultForm.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Submitted: ${_defaultForm.value}'),
                        ),
                      );
                    }
                  },
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
