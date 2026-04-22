import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class ArrayFieldPage extends StatefulWidget {
  const ArrayFieldPage({super.key});

  @override
  State<ArrayFieldPage> createState() => _ArrayFieldPageState();
}

class _ArrayFieldPageState extends State<ArrayFieldPage> {
  late final VForm<Map<String, dynamic>> _form;
  final _tagController = TextEditingController();

  Map<String, dynamic>? _result;
  Map<String, String>? _errors;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'title': V.string().min(3),
      'tags': V.array<String>(V.string().min(2)).min(2).max(5),
    }).form();
  }

  @override
  void dispose() {
    _tagController.dispose();
    _form.dispose();

    super.dispose();
  }

  VField<String> get _title => _form.field('title');
  VField<List<String>> get _tags => _form.field('tags');

  void _addTag() {
    final text = _tagController.text.trim();
    if (text.isEmpty) return;

    final current = _tags.value ?? <String>[];
    _tags.set([...current, text]);
    _tagController.clear();
  }

  void _removeTag(int index) {
    final current = _tags.value ?? <String>[];
    _tags.set([...current]..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Array Field')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'V.array<String>(V.string().min(2)).min(2).max(5) creates a '
                'VField<List<String>>. Each tag must have at least 2 chars, '
                'and the list requires 2 to 5 tags. Add/remove tags and '
                'submit to see validation in action.',
              ),
              const SizedBox(height: 24),
              VTextField(
                field: _title,
                label: 'Title',
              ),
              const SizedBox(height: 24),
              const Text(
                'Tags',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Type a tag and press Add',
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _addTag,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FormField<List<String>>(
                initialValue: _tags.value ?? [],
                validator: (_) => _tags.validator(_tags.value),
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListenableBuilder(
                        listenable: _tags.listenable,
                        builder: (context, _) {
                          final tags = _tags.value ?? [];
                          if (tags.isEmpty) {
                            return Text(
                              'No tags added yet',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(tags.length, (i) {
                              return InputChip(
                                label: Text(tags[i]),
                                onDeleted: () {
                                  _removeTag(i);
                                  state.didChange(_tags.value);
                                },
                              );
                            }),
                          );
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
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
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _tags.listenable,
                builder: (context, _) {
                  final count = _tags.value?.length ?? 0;
                  return Text(
                    '$count / 5 tags',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
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
