import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

/// Demonstrates the three "set from code" entry points and how each
/// widget shape reflects (or doesn't) the model update:
///
/// - `field.set(value)` — per-field programmatic update.
/// - `form.set(Map)` — bulk update across many fields at once. Partial:
///   absent keys are untouched, unknown keys ignored.
/// - `form.set(T)` — typed form (`VForm.object`) accepts a `T` instance
///   too, decomposed via `VObject.extract`.
///
/// The widget reflection rules (a frequent source of confusion):
///
/// - `TextFormField` with `attachTextController` → reflects (two-way bind).
/// - `TextFormField` without controller → does NOT reflect; widget owns
///   its `FormFieldState` text.
/// - `DropdownButtonFormField` wrapped in `ListenableBuilder` → reflects
///   (builder reruns on `field.listenable`).
/// - `DropdownButtonFormField` without the builder → does NOT reflect;
///   the `value:` prop is captured at build time.
///
/// Tap the buttons under each section to mutate fields from code and
/// watch which widgets follow vs which stay put.
class ProgrammaticUpdatesPage extends StatefulWidget {
  const ProgrammaticUpdatesPage({super.key});

  @override
  State<ProgrammaticUpdatesPage> createState() =>
      _ProgrammaticUpdatesPageState();
}

class _ProgrammaticUpdatesPageState extends State<ProgrammaticUpdatesPage> {
  late final VForm<_Profile> _form;

  @override
  void initState() {
    super.initState();

    _form = V
        .object<_Profile>()
        .field('name', (p) => p.name, V.string().min(1))
        .field('email', (p) => p.email, V.string().email().nullable())
        .field('country', (p) => p.country, V.enm<_Country>(_Country.values))
        .form(
      builder: _Profile.fromMap,
      // Partial Map seed — only the fields we actually want pre-filled.
      // `name` and `email` start as null (no placeholder needed even
      // though `name` is required by the schema).
      initialValues: {'country': _Country.br},
    );

    // attachTextController so field.set / form.set are reflected on screen
    // for `name`. `email` intentionally has NO controller so you can see
    // the contrast — programmatic updates change the model but not the
    // widget's displayed text.
    _form.field<String>('name').attachTextController(TextEditingController());
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _email => _form.field('email');
  VField<_Country> get _country => _form.field('country');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programmatic Updates')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'form.set and field.set mutate the model — whether the widget '
                'on screen also updates depends on how each one is wired. '
                'Name uses attachTextController (reflects). Email is wired '
                'with onChanged only (does NOT reflect — try the buttons). '
                'Country is wrapped in a ListenableBuilder (reflects).',
              ),
              const SizedBox(height: 24),
              const SectionTitle('Name — TextFormField + attachTextController'),
              const SizedBox(height: 8),
              TextFormField(
                key: _name.key,
                controller: _name.textController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _name.validator,
              ),
              const SizedBox(height: 12),
              _ButtonRow(
                buttons: [
                  ('field.set("Alice")', () => _name.set('Alice')),
                  ('field.set("Bob")', () => _name.set('Bob')),
                  ('clear', () => _name.set(null)),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle(
                'Email — TextFormField with onChanged only (no controller)',
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: _email.key,
                initialValue: _email.initialValue,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Programmatic set updates the model, not this '
                      'widget. Use attachTextController to reflect.',
                ),
                validator: _email.validator,
                onChanged: _email.onChanged,
              ),
              const SizedBox(height: 12),
              _ButtonRow(
                buttons: [
                  (
                    'field.set("a@b.com")',
                    () => _email.set('a@b.com'),
                  ),
                  ('clear', () => _email.set(null)),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle(
                'Country — DropdownButtonFormField wrapped in ListenableBuilder',
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _country.listenable,
                builder: (context, _) => DropdownButtonFormField<_Country>(
                  key: _country.key,
                  initialValue: _country.value,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: _Country.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ))
                      .toList(),
                  onChanged: (val) => _country.set(val),
                  validator: (_) => _country.validator(_country.value),
                ),
              ),
              const SizedBox(height: 12),
              _ButtonRow(
                buttons: [
                  ('field.set(BR)', () => _country.set(_Country.br)),
                  ('field.set(US)', () => _country.set(_Country.us)),
                  ('field.set(PT)', () => _country.set(_Country.pt)),
                ],
              ),
              const SizedBox(height: 32),
              const SectionTitle('Bulk updates — form.set(...)'),
              const SizedBox(height: 8),
              _ButtonRow(
                buttons: [
                  (
                    'form.set(Map) partial',
                    () => _form.set({
                          'name': 'Carol',
                          'country': _Country.us,
                          // email omitted — stays whatever was last
                          'unknown_key': 'ignored',
                        }),
                  ),
                  (
                    'form.set(T) typed instance',
                    () => _form.set(const _Profile(
                          name: 'Diana',
                          email: 'd@example.com',
                          country: _Country.pt,
                        )),
                  ),
                  ('form.reset()', () => _form.reset()),
                ],
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: _form.listenable,
                builder: (context, _) => _LiveModel(form: _form),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveModel extends StatelessWidget {
  final VForm<_Profile> form;

  const _LiveModel({required this.form});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('form.rawValue (live)'),
          const SizedBox(height: 8),
          Text(
            form.rawValue.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
            style: TextStyle(
              fontFamily: 'monospace',
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  final List<(String, VoidCallback)> buttons;

  const _ButtonRow({required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons
          .map(
            (b) => SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: b.$2,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(b.$1),
              ),
            ),
          )
          .toList(),
    );
  }
}

enum _Country {
  br('Brazil'),
  us('United States'),
  pt('Portugal');

  final String label;
  const _Country(this.label);
}

class _Profile {
  final String name;
  final String? email;
  final _Country country;

  const _Profile({
    required this.name,
    required this.email,
    required this.country,
  });

  factory _Profile.fromMap(Map<String, dynamic> data) => _Profile(
        name: data['name'] ?? '',
        email: data['email'] as String?,
        country: data['country'] as _Country? ?? _Country.br,
      );
}
