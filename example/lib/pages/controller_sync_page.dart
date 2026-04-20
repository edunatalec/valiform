import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

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

  // Section 5: ValueNotifier<int?> for a non-text field
  late final VForm<Map<String, dynamic>> _counterForm;
  late final ValueNotifier<int?> _counterNotifier;

  @override
  void initState() {
    super.initState();

    _syncForm = V.map({'name': V.string().min(2)}).form();
    _syncController = TextEditingController();
    _syncForm
        .field<String>('name')
        .attachTextController(_syncController, owns: false);

    _noSyncForm = V.map({'name': V.string().min(2)}).form();

    _syncInitForm = V.map({'name': V.string().min(2)}).form(
      initialValues: {'name': 'John'},
    );

    _syncInitController = TextEditingController(text: 'John');
    _syncInitForm
        .field<String>('name')
        .attachTextController(_syncInitController, owns: false);

    _noSyncInitForm = V.map({'name': V.string().min(2)}).form(
      initialValues: {'name': 'Jane'},
    );

    _counterForm = V.map({'count': V.int().min(0).max(10)}).form(
      initialValues: {'count': 0},
    );

    _counterNotifier = ValueNotifier<int?>(0);
    _counterForm
        .field<int>('count')
        .attachController(_counterNotifier, owns: false);
  }

  @override
  void dispose() {
    _syncController.dispose();
    _syncForm.dispose();
    _noSyncForm.dispose();

    _syncInitController.dispose();
    _syncInitForm.dispose();
    _noSyncInitForm.dispose();

    _counterNotifier.dispose();
    _counterForm.dispose();

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
              description: 'attachController creates bidirectional sync. '
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
            const Divider(height: 48),
            _CounterSection(
              form: _counterForm,
              field: _counterForm.field<int>('count'),
              notifier: _counterNotifier,
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterSection extends StatelessWidget {
  final VForm<Map<String, dynamic>> form;
  final VField<int> field;
  final ValueNotifier<int?> notifier;

  const _CounterSection({
    required this.form,
    required this.field,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('With ValueNotifier (non-text field)'),
        const SizedBox(height: 8),
        const InfoCard(
          'attachController works with any ValueNotifier<T?>, not just '
          'TextEditingController. Here a ValueNotifier<int?> drives a '
          'counter field. Typing into the notifier (via the +/− buttons '
          'mutating notifier.value) flows into the VField — and VField.set '
          'flows back into the notifier.',
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: notifier,
          builder: (context, _) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      notifier.value = (notifier.value ?? 0) - 1;
                    },
                  ),
                  Text(
                    '${notifier.value ?? "—"}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      notifier.value = (notifier.value ?? 0) + 1;
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: () => field.set(5),
              child: const Text('field.set(5)'),
            ),
            FilledButton.tonal(
              onPressed: () => field.reset(),
              child: const Text('field.reset()'),
            ),
            FilledButton.tonal(
              onPressed: () {
                // No FormField widget wraps this counter — inspect errors
                // directly via form.errors() (headless, no UI).
                final errs = form.errors();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errs == null
                        ? 'Valid: ${field.value}'
                        : 'Errors: $errs'),
                  ),
                );
              },
              child: const Text('Validate'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: field.listenable,
          builder: (context, _) {
            return Text(
              'VField value: ${field.value ?? "null"}  ·  '
              'notifier.value: ${notifier.value ?? "null"}',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ],
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
