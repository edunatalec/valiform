import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../utils.dart';
import '../widgets/widgets.dart';

class ReactiveFormPage extends StatefulWidget {
  const ReactiveFormPage({super.key});

  @override
  State<ReactiveFormPage> createState() => _ReactiveFormPageState();
}

class _ReactiveFormPageState extends State<ReactiveFormPage> {
  late final VForm<Map<String, dynamic>> _form;
  String _jsonPreview = '{}';

  Map<String, dynamic>? _result;
  Map<String, String>? _errors;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'name': V.string().min(2),
      'email': V.string().email(),
    }).form(
      onValueChanged: (value) {
        setState(() {
          _jsonPreview = prettyJson(value);
        });
      },
    );
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _email => _form.field('email');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reactive Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoCard(
              'Reactive features of VForm. The onValueChanged callback fires '
              'whenever any field value changes, providing a live JSON '
              'preview below the form. ListenableBuilder with a field\'s '
              'listenable tracks individual field changes, such as the '
              'character count for the name field.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _form.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VTextField(
                    field: _name,
                    hint: 'Name',
                  ),
                  const SizedBox(height: 4),
                  ListenableBuilder(
                    listenable: _name.listenable,
                    builder: (context, _) {
                      final length = _name.value?.length ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          '$length character${length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _email,
                    hint: 'Email',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_form.validate()) {
                              _result = _form.value;
                              _errors = null;
                            } else {
                              _result = null;
                              _errors = _form.errors();
                            }
                          });
                        },
                        child: const Text('Validate'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _form.reset();
                          setState(() {
                            _result = null;
                            _errors = null;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.success(data: _result!),
                  ] else if (_errors != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.failure(errors: _errors!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Live JSON Preview'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Text(
                _jsonPreview,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
