import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../utils.dart';
import '../widgets/widgets.dart';

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
            Form(
              key: _form.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Without Default Values'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'The simplest way to create a form with Valiform. A VMap '
                    'schema defines email and password fields with built-in '
                    'validation. The .form() extension converts it into a '
                    'VForm. No controller needed — VTextField wires '
                    'onChanged and validator automatically.',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: _password,
                    label: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_form.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Submitted: ${prettyJson(_form.value)}',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
            const Divider(height: 48),
            Form(
              key: _defaultForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('With Default Values'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'Pass initialValues to .form() to set initial field '
                    'values. Fields start pre-filled. Calling form.reset() '
                    'restores them to the default values.',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: _defEmail,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: _defPassword,
                    label: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _defaultForm.reset,
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
                                  content: Text(
                                    'Submitted: ${prettyJson(_defaultForm.value)}',
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
