import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class ManualErrorPage extends StatefulWidget {
  const ManualErrorPage({super.key});

  @override
  State<ManualErrorPage> createState() => _ManualErrorPageState();
}

class _ManualErrorPageState extends State<ManualErrorPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'email': V.string().email(),
      'username': V.string().min(3),
      'phone': V.string().min(8),
    }).form(
      initialValues: {
        'email': 'user@example.com',
        'username': 'johndoe',
      },
    );

    // Inline controllers — VField takes ownership and disposes them when
    // _form.dispose() is called.
    _email.attachTextController(
      TextEditingController(text: _email.value),
    );
    _username.attachTextController(
      TextEditingController(text: _username.value),
    );
    _phone.attachTextController(TextEditingController());
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _email => _form.field('email');
  VField<String> get _username => _form.field('username');
  VField<String> get _phone => _form.field('phone');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Error')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'Imperative errors via form.setError / field.setError — useful '
                'for backend validation ("email already taken"), async checks, '
                'or business rules.\n\n'
                'Precedence: by default, standard validators win — the manual '
                'error only surfaces when the field is otherwise valid. '
                'Setting a manual error on an invalid field silently consumes '
                'it (no ghost errors on later valid input).\n\n'
                'Pass force: true to override this and show the manual error '
                'even when standard rules would fail.\n\n'
                'Email and username start pre-filled (valid). Phone is empty '
                '(invalid) — use it to see both behaviours.',
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _email,
                label: 'Email (pre-filled, valid)',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _username,
                label: 'Username (pre-filled, valid)',
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _phone,
                label: 'Phone (empty, invalid)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => _email.setError('This email is already taken'),
                child: const Text('setError on email (valid → error shows)'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () =>
                    _username.setError('Username is reserved', persist: true),
                child: const Text(
                  'setError on username (persist: true)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => _phone.setError('Phone is blocked'),
                child: const Text(
                  'setError on phone (invalid → no ghost error)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () =>
                    _phone.setError('Phone blocked by server', force: true),
                child: const Text(
                  'setError on phone with force: true (appears anyway)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => _form.setErrors({
                  'email': 'Email conflict from API',
                  'username': 'Username conflict from API',
                  'phone': 'Phone conflict from API',
                }),
                child: const Text(
                  'Batch setErrors on all 3 (phone silently consumed)',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => _form.setErrors(
                  {
                    'email': 'Email conflict from API',
                    'username': 'Username conflict from API',
                    'phone': 'Phone conflict from API',
                  },
                  force: true,
                ),
                child: const Text(
                  'Batch setErrors with force: true (all 3 appear)',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _form.clearErrors(),
                child: const Text('Clear all manual errors'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  final ok = _form.silentValidate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'silentValidate: true (valid, no manual errors)'
                          : 'silentValidate: false (schema issue OR pending manual error — one-shot now consumed)'),
                    ),
                  );
                },
                child: const Text('silentValidate (no UI)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_form.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Submitted: ${_form.value}')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
