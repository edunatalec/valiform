import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../utils.dart';
import '../widgets/widgets.dart';

class VErrorsPage extends StatefulWidget {
  const VErrorsPage({super.key});

  @override
  State<VErrorsPage> createState() => _VErrorsPageState();
}

class _VErrorsPageState extends State<VErrorsPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'title': V.string().min(5),
      'email': V.string().email(),
      'tags': V.array<String>(V.string().min(3)).min(2),
    }).form(
      initialValues: {
        'title': 'Hi',
        'email': 'not-an-email',
        'tags': ['ok', 'a', 'go', 'b'],
      },
    );

    // Attach TextEditingControllers so programmatic field.set() (e.g. from
    // the "Fix all" button) also updates the widget text — otherwise the
    // inputs stay stale while the VField value and vErrors panel change.
    _title.attachTextController(TextEditingController(text: _title.value));
    _email.attachTextController(TextEditingController(text: _email.value));

    // FormState exists only after the first build — defer validate() so the
    // inline FormField errors paint on mount together with the vErrors panel.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _form.validate());
    });
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _title => _form.field('title');
  VField<String> get _email => _form.field('email');
  VField<List<String>> get _tags => _form.field('tags');

  void _fixAll() {
    _title.set('Valid title');
    _email.set('user@example.com');
    _tags.set(['alpha', 'beta', 'gamma']);
    setState(() => _form.validate());
  }

  void _removeTag(int index) {
    final current = List<String>.from(_tags.value ?? const []);
    current.removeAt(index);
    _tags.set(current);
    setState(() => _form.validate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('vErrors')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'form.vErrors() returns Map<String, List<VError>>? where each '
                'VError exposes code (machine-readable), message, and path '
                '(list of keys and indices). Use it for i18n, programmatic '
                'error handling, and nested structures — arrays surface one '
                'VError per failing item, each carrying its index in the path.',
              ),
              const SizedBox(height: 16),
              const InfoCard.highlight(
                'This form is pre-seeded with invalid initialValues and '
                'validate() runs on mount — so the panel below shows the '
                'errors immediately. Edit any field to watch vErrors update '
                'live.',
              ),
              const SizedBox(height: 24),
              VTextField(field: _title, label: 'Title (min 5)'),
              const SizedBox(height: 16),
              VTextField(
                field: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tags (each min 3 chars, at least 2 tags)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _tags.listenable,
                builder: (context, _) {
                  final tags = _tags.value ?? const <String>[];
                  if (tags.isEmpty) {
                    return Text(
                      'No tags',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(tags.length, (i) {
                      return InputChip(
                        label: Text('[$i] ${tags[i]}'),
                        onDeleted: () => _removeTag(i),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 24),
              const SectionTitle('Live vErrors()'),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _form.listenable,
                builder: (context, _) {
                  return _VErrorPanel(vErrors: _form.vErrors());
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _fixAll,
                    child: const Text('Fix all'),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      _form.reset();
                      // reset() is synchronous; re-validate so the panel
                      // shows the seeded-invalid state again.
                      setState(() => _form.validate());
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VErrorPanel extends StatelessWidget {
  final Map<String, List<VError>>? vErrors;

  const _VErrorPanel({required this.vErrors});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String body;
    final Color background;
    final Color foreground;

    if (vErrors == null) {
      body = 'null';
      background = colorScheme.secondaryContainer;
      foreground = colorScheme.onSecondaryContainer;
    } else {
      // Serialize VError as a plain map so prettyJson renders each field
      // (code, path, message) explicitly — reveals the real shape the dev
      // gets from form.vErrors().
      final serializable = vErrors!.map(
        (key, errors) => MapEntry(
          key,
          errors
              .map((e) => {
                    'code': e.code,
                    'path': e.path,
                    'message': e.message,
                  })
              .toList(),
        ),
      );
      body = prettyJson(serializable);
      background = colorScheme.errorContainer;
      foreground = colorScheme.onErrorContainer;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'form.vErrors():',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
