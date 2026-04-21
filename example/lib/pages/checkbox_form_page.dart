import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class CheckboxFormPage extends StatefulWidget {
  const CheckboxFormPage({super.key});

  @override
  State<CheckboxFormPage> createState() => _CheckboxFormPageState();
}

class _CheckboxFormPageState extends State<CheckboxFormPage> {
  late final VForm<Map<String, dynamic>> _form;

  Map<String, dynamic>? _result;
  Map<String, String>? _errors;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'name': V.string().min(3),
      'email': V.string().email(),
      // `preprocess((v) => v ?? false)` normalizes an untouched checkbox
      // (null) into `false` so the `isTrue` check always fires with its
      // custom message — otherwise null would surface the generic
      // `required` error and the `isTrue` message would never be seen.
      'acceptTerms': V.bool()
          .preprocess((v) => v ?? false)
          .isTrue(message: 'You must accept the terms'),
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
    setState(() {
      if (_form.validate()) {
        _result = _form.value;
        _errors = null;
      } else {
        _result = null;
        _errors = _form.errors();
      }
    });
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
              VTextField(
                field: _name,
                label: 'Name',
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              VCheckboxField(
                field: _acceptTerms,
                title: 'I accept the terms and conditions',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
              ResultFeedback(data: _result, errors: _errors),
            ],
          ),
        ),
      ),
    );
  }
}
