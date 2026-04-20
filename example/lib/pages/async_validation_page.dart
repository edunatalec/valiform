import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../utils.dart';
import '../widgets/widgets.dart';

class AsyncValidationPage extends StatefulWidget {
  const AsyncValidationPage({super.key});

  @override
  State<AsyncValidationPage> createState() => _AsyncValidationPageState();
}

class _AsyncValidationPageState extends State<AsyncValidationPage> {
  // Fake remote check: anything in this set is considered "already taken".
  static const _takenUsernames = {'admin', 'root'};

  late final VForm<Map<String, dynamic>> _form;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'username': V
          .string()
          .min(3)
          // Async check runs only when the sync rules above pass.
          .refineAsync(
        (value) async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          return !_takenUsernames.contains(value.toLowerCase());
        },
        message: 'Username already taken',
        timeout: const Duration(seconds: 2),
      ),
      'email': V.string().email(),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _username => _form.field('username');
  VField<String> get _email => _form.field('email');

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final valid = await _form.validateAsync();
    if (!mounted) return;

    // Read the parsed value via valueAsync — `_form.value` would throw
    // VAsyncRequiredException because the schema has async steps.
    final data = valid ? await _form.valueAsync : null;
    if (!mounted) return;

    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          data != null
              ? 'Submitted: ${prettyJson(data)}'
              : 'Fix the errors above',
        ),
      ),
    );
  }

  void _trySyncValidate() {
    // Demonstrates the strict contract: calling a sync method on a form
    // with async steps throws VAsyncRequiredException, mirroring validart.
    try {
      _form.validate();
    } on VAsyncRequiredException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Caught: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Validation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Username availability'),
              const SizedBox(height: 8),
              const InfoCard(
                'The username field uses refineAsync to simulate a remote '
                'check (600ms delay). Sync rules (min 3 chars) run locally '
                'as the user types; the async check fires only on submit '
                'via form.validateAsync(). Try "admin" or "root" '
                'to see the async error surface through the same FormField '
                'error pipeline as regular validations.',
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _username,
                label: 'Username',
                hint: 'try "admin" or pick your own',
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign Up'),
              ),
              const SizedBox(height: 32),
              const SectionTitle('Strict async contract'),
              const SizedBox(height: 8),
              const InfoCard(
                'Sync inspection methods (validate, silentValidate, errors, '
                'vErrors, value) throw VAsyncRequiredException when the '
                'schema has async steps — same contract as validart. This '
                'prevents a form from looking "valid" before the async '
                'check ran. Tap below to see the exception.',
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _trySyncValidate,
                child: const Text('Call form.validate() (expected to throw)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
