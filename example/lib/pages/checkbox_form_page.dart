import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

class CheckboxFormPage extends StatefulWidget {
  const CheckboxFormPage({super.key});

  @override
  State<CheckboxFormPage> createState() => _CheckboxFormPageState();
}

class _CheckboxFormPageState extends State<CheckboxFormPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();
    _form = V.map({
      'name': V.string().min(3),
      'email': V.string().email(),
      'acceptTerms': V.bool().isTrue(message: 'You must accept the terms'),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _email => _form.field('email');
  VField<bool> get _acceptTerms => _form.field('acceptTerms');

  void _submit() {
    if (_form.validate()) {
      final values = _form.value;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Form Submitted'),
          content: Text(
            'Name: ${values['name']}\n'
            'Email: ${values['email']}\n'
            'Accepted Terms: ${values['acceptTerms']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkbox Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'V.bool().isTrue() ensures the field must be true before the '
                'form can be submitted. Combined with a CheckboxListTile and '
                'FormField<bool>, this creates a required terms acceptance '
                'pattern with proper validation error display.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: _name.onChanged,
                validator: _name.validator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: _email.onChanged,
                validator: _email.validator,
              ),
              const SizedBox(height: 16),
              FormField<bool>(
                initialValue: _acceptTerms.value ?? false,
                validator: (_) => _acceptTerms.validator(_acceptTerms.value),
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: const Text(
                          'I accept the terms and conditions',
                        ),
                        value: _acceptTerms.value ?? false,
                        onChanged: (val) {
                          _acceptTerms.set(val);
                          state.didChange(val);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
