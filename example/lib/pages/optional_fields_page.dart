import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

class OptionalFieldsPage extends StatefulWidget {
  const OptionalFieldsPage({super.key});

  @override
  State<OptionalFieldsPage> createState() => _OptionalFieldsPageState();
}

class _OptionalFieldsPageState extends State<OptionalFieldsPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();
    _form = V.map({
      'name': V.string().min(3),
      'nickname': V.string().min(2).nullable(),
      'bio': V.string().min(10).nullable(),
      'website': V.string().url().nullable(),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _nickname => _form.field('nickname');
  VField<String> get _bio => _form.field('bio');
  VField<String> get _website => _form.field('website');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Optional Fields')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'Fields marked with .nullable() are optional. They accept '
                'empty values without error. Try typing something in an '
                'optional field and then clearing it — it should remain '
                'valid. Only when you type something that violates the '
                'rule (e.g. less than 2 chars for nickname) does it show '
                'an error.',
              ),
              const SizedBox(height: 24),
              Text(
                'Required',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'At least 3 characters',
                ),
                onChanged: _name.onChanged,
                validator: _name.validator,
              ),
              const SizedBox(height: 24),
              Text(
                'Optional',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  hintText: 'Optional, at least 2 characters if provided',
                ),
                onChanged: _nickname.onChanged,
                validator: _nickname.validator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Optional, at least 10 characters if provided',
                ),
                maxLines: 3,
                onChanged: _bio.onChanged,
                validator: _bio.validator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'Optional, must be a valid URL if provided',
                ),
                keyboardType: TextInputType.url,
                onChanged: _website.onChanged,
                validator: _website.validator,
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: _form.listenable,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current values:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'name: ${_name.value ?? "null"}\n'
                          'nickname: ${_nickname.value ?? "null"}\n'
                          'bio: ${_bio.value ?? "null"}\n'
                          'website: ${_website.value ?? "null"}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_form.validate()) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Form Submitted'),
                        content: Text(
                          'name: ${_name.value}\n'
                          'nickname: ${_nickname.value ?? "(not provided)"}\n'
                          'bio: ${_bio.value ?? "(not provided)"}\n'
                          'website: ${_website.value ?? "(not provided)"}',
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
