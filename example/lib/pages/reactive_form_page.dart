import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

class ReactiveFormPage extends StatefulWidget {
  const ReactiveFormPage({super.key});

  @override
  State<ReactiveFormPage> createState() => _ReactiveFormPageState();
}

class _ReactiveFormPageState extends State<ReactiveFormPage> {
  late final VForm<Map<String, dynamic>> _form;
  String _jsonPreview = '{}';

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'name': V.string().min(2),
      'email': V.string().email(),
    }).form(
      onValueChanged: (value) {
        setState(() {
          _jsonPreview = _encoder.convert(value);
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: Text(
                'This page demonstrates reactive features of VForm. The '
                'onValueChanged callback fires whenever any field value changes, '
                'providing a live JSON preview below the form. ListenableBuilder '
                'with a field\'s listenable tracks individual field changes, '
                'such as the character count for the name field.',
                style: TextStyle(
                  letterSpacing: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _form.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Name'),
                    validator: _name.validator,
                    onChanged: _name.onChanged,
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
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Email'),
                    validator: _email.validator,
                    onChanged: _email.onChanged,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_form.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Form is valid!')),
                            );
                          }
                        },
                        child: const Text('Validate'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _name.clear();
                          _email.clear();
                        },
                        child: const Text('Clear'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _name.reset();
                          _email.reset();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Live JSON Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
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
