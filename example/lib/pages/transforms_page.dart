import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class TransformsPage extends StatefulWidget {
  const TransformsPage({super.key});

  @override
  State<TransformsPage> createState() => _TransformsPageState();
}

class _TransformsPageState extends State<TransformsPage> {
  late final VForm<Map<String, dynamic>> _form;

  Map<String, dynamic>? _result;
  Map<String, String>? _errors;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      // .trim() removes leading/trailing whitespace before validation.
      // .toLowerCase() normalizes email casing.
      'email': V.string().trim().toLowerCase().email(),
      // .trim() removes leading/trailing whitespace before validation.
      'name': V.string().trim().min(3),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

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

  VField<String> get _email => _form.field('email');
  VField<String> get _name => _form.field('name');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transforms')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'validart pipelines (.trim(), .toLowerCase(), .preprocess()) '
                'run BEFORE validation. On a VForm, form.rawValue exposes the '
                'raw input; form.value exposes the transformed result.\n\n'
                'Try typing "  USER@Email.com  " in the email field — the '
                'validation passes because trim+toLowerCase run first, and '
                'form.value shows the clean version.',
              ),
              const SizedBox(height: 24),
              VTextField(
                field: _email,
                label: 'Email',
                hint: 'Try leading/trailing spaces and UPPERCASE',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _name,
                label: 'Name',
                hint: 'Try leading/trailing spaces',
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: _form.listenable,
                builder: (context, _) => _buildPreview(),
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

  Widget _buildPreview() {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget row(String label, Object? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: variant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '"$value"',
                  style: TextStyle(fontFamily: 'monospace', color: variant),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('rawValue vs value'),
          const SizedBox(height: 8),
          Text('form.rawValue:',
              style: TextStyle(fontWeight: FontWeight.w600, color: variant)),
          row('email', _form.rawValue['email']),
          row('name', _form.rawValue['name']),
          const SizedBox(height: 8),
          Text('form.value (transformed):',
              style: TextStyle(fontWeight: FontWeight.w600, color: variant)),
          row('email', _form.value['email']),
          row('name', _form.value['name']),
        ],
      ),
    );
  }
}
