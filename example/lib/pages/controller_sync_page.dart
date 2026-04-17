import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

class ControllerSyncPage extends StatefulWidget {
  const ControllerSyncPage({super.key});

  @override
  State<ControllerSyncPage> createState() => _ControllerSyncPageState();
}

class _ControllerSyncPageState extends State<ControllerSyncPage> {
  // Section 1: With controller, no initial value
  late final VForm<Map<String, dynamic>> _syncForm;
  late final TextEditingController _syncController;

  // Section 2: Without controller, no initial value
  late final VForm<Map<String, dynamic>> _noSyncForm;

  // Section 3: With controller + initial value
  late final VForm<Map<String, dynamic>> _syncInitForm;
  late final TextEditingController _syncInitController;

  // Section 4: Without controller + initial value
  late final VForm<Map<String, dynamic>> _noSyncInitForm;

  @override
  void initState() {
    super.initState();

    _syncForm = V.map({'name': V.string().min(2)}).form();
    _syncController = TextEditingController();
    _syncForm.field<String>('name').attachTextController(_syncController);

    _noSyncForm = V.map({'name': V.string().min(2)}).form();

    _syncInitForm = V.map({'name': V.string().min(2)}).form(
      initialValues: {'name': 'John'},
    );
    _syncInitController = TextEditingController(text: 'John');
    _syncInitForm
        .field<String>('name')
        .attachTextController(_syncInitController);

    _noSyncInitForm = V.map({'name': V.string().min(2)}).form(
      initialValues: {'name': 'Jane'},
    );
  }

  @override
  void dispose() {
    _syncController.dispose();
    _syncForm.dispose();
    _noSyncForm.dispose();
    _syncInitController.dispose();
    _syncInitForm.dispose();
    _noSyncInitForm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controller Sync')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SyncSection(
              title: 'With Controller',
              description: 'attachTextController creates bidirectional sync. '
                  'Calling set() or reset() updates the text field. '
                  'Typing updates the VField value.',
              form: _syncForm,
              field: _syncForm.field('name'),
              controller: _syncController,
            ),
            const Divider(height: 48),
            _SyncSection(
              title: 'Without Controller',
              description: 'Without a controller, set()/reset() update the '
                  'VField value but NOT the widget text. The ListenableBuilder '
                  'below shows the real VField value.',
              form: _noSyncForm,
              field: _noSyncForm.field('name'),
            ),
            const Divider(height: 48),
            _SyncSection(
              title: 'With Controller + Initial Value',
              description: 'initialValues sets the initial VField value. The '
                  'TextEditingController is created with the same text. '
                  'Reset restores to the initial value in both.',
              form: _syncInitForm,
              field: _syncInitForm.field('name'),
              controller: _syncInitController,
            ),
            const Divider(height: 48),
            _SyncSection(
              title: 'Without Controller + Initial Value',
              description: 'initialValues sets the VField value to "Jane". '
                  'initialValue on TextFormField shows it in the widget. '
                  'But without a controller, set()/reset() only update the '
                  'VField — the widget text stays unchanged.',
              form: _noSyncInitForm,
              field: _noSyncInitForm.field('name'),
              initialValue: 'Jane',
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncSection extends StatelessWidget {
  final String title;
  final String description;
  final VForm<Map<String, dynamic>> form;
  final VField<String> field;
  final TextEditingController? controller;
  final String? initialValue;

  const _SyncSection({
    required this.title,
    required this.description,
    required this.form,
    required this.field,
    this.controller,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InfoCard(description),
          const SizedBox(height: 16),
          if (controller != null)
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: field.validator,
              onChanged: field.onChanged,
            )
          else
            TextFormField(
              initialValue: initialValue,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: field.validator,
              onChanged: field.onChanged,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => field.set('Hello'),
                child: const Text('Set "Hello"'),
              ),
              FilledButton.tonal(
                onPressed: () => field.set(null),
                child: const Text('Set null'),
              ),
              FilledButton.tonal(
                onPressed: () => field.reset(),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: field.listenable,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  'VField value: "${field.value ?? "null"}"',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
