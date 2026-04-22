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
  late final VForm<Map<String, dynamic>> _syncForm;
  late final VForm<Map<String, dynamic>> _noSyncForm;
  late final VForm<Map<String, dynamic>> _syncInitForm;
  late final VForm<Map<String, dynamic>> _noSyncInitForm;
  late final VForm<Map<String, dynamic>> _counterForm;

  @override
  void initState() {
    super.initState();

    _syncForm = V.map({'name': V.string().min(2)}).form();
    _syncField.attachTextController(TextEditingController());

    _noSyncForm = V.map({'name': V.string().min(2)}).form();

    _syncInitForm = V.map({'name': V.string().min(2)}).form(
      initialValues: {'name': 'John'},
    );
    _syncInitField.attachTextController(
      TextEditingController(text: _syncInitField.value),
    );

    _noSyncInitForm = V.map({'name': V.string().min(2)}).form(
      initialValues: {'name': 'Jane'},
    );

    _counterForm = V.map({'count': V.int().min(0).max(10)}).form(
      initialValues: {'count': 0},
    );
    _counterField.attachController(ValueNotifier<int?>(_counterField.value));
  }

  @override
  void dispose() {
    _syncForm.dispose();
    _noSyncForm.dispose();
    _syncInitForm.dispose();
    _noSyncInitForm.dispose();
    _counterForm.dispose();

    super.dispose();
  }

  VField<String> get _syncField => _syncForm.field('name');
  VField<String> get _noSyncField => _noSyncForm.field('name');
  VField<String> get _syncInitField => _syncInitForm.field('name');
  VField<String> get _noSyncInitField => _noSyncInitForm.field('name');
  VField<int> get _counterField => _counterForm.field<int>('count');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controller Sync')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoCard.highlight(
              'Reset buttons here call field.reset(), not form.reset(). '
              'Without a controller attached, only the VField value resets '
              '— the widget text stays. Check the preview under each '
              'section for the real VField value.',
            ),
            const SizedBox(height: 16),
            _SyncSection(
              title: 'With Controller',
              description: 'attachTextController creates bidirectional sync. '
                  'Calling set() or reset() updates the text field. '
                  'Typing updates the VField value. The controller is owned '
                  'by the field and disposed when form.dispose() runs.',
              form: _syncForm,
              field: _syncField,
            ),
            const Divider(height: 48),
            _SyncSection(
              title: 'Without Controller',
              description: 'Without a controller, set()/reset() update the '
                  'VField value but NOT the widget text. The ListenableBuilder '
                  'below shows the real VField value.',
              form: _noSyncForm,
              field: _noSyncField,
            ),
            const Divider(height: 48),
            _SyncSection(
              title: 'With Controller + Initial Value',
              description: 'initialValues sets the initial VField value. The '
                  'TextEditingController is created with the same text. '
                  'Reset restores to the initial value in both.',
              form: _syncInitForm,
              field: _syncInitField,
            ),
            const Divider(height: 48),
            _SyncSection(
              title: 'Without Controller + Initial Value',
              description: 'initialValues sets the VField value to "Jane". '
                  'VTextField uses field.value as the widget\'s initialValue, '
                  'so "Jane" appears on screen. But without a controller, '
                  'set()/reset() only update the VField — the widget text '
                  'stays unchanged.',
              form: _noSyncInitForm,
              field: _noSyncInitField,
            ),
            const Divider(height: 48),
            _CounterSection(
              form: _counterForm,
              field: _counterField,
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

  const _CounterSection({required this.form, required this.field});

  @override
  Widget build(BuildContext context) {
    final notifier = field.controller!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('With ValueNotifier (non-text field)'),
        const SizedBox(height: 8),
        const InfoCard(
          'attachController works with any ValueNotifier<T?>, not just '
          'TextEditingController. Here a ValueNotifier<int?> drives a '
          'counter field. Mutating notifier.value (via +/− buttons) flows '
          'into the VField — and VField.set flows back into the notifier. '
          'The notifier is recovered via field.controller, owned by the '
          'field, and disposed when form.dispose() runs.',
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
                final errs = form.errors();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  const _SyncSection({
    required this.title,
    required this.description,
    required this.form,
    required this.field,
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
          VTextField(field: field, label: 'Name'),
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
                onPressed: field.reset,
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
