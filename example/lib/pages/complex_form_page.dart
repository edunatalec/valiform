import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../utils.dart';
import '../widgets/widgets.dart';

enum Role { admin, user, guest }

class ComplexFormPage extends StatefulWidget {
  const ComplexFormPage({super.key});

  @override
  State<ComplexFormPage> createState() => _ComplexFormPageState();
}

class _ComplexFormPageState extends State<ComplexFormPage> {
  late final VForm<Map<String, dynamic>> _form;
  bool _submitting = false;
  Map<String, dynamic>? _validData;
  Map<String, String>? _validationErrors;

  // Fake remote check used by the .when('member') async rule.
  static const _takenUsernames = {'admin', 'root'};

  @override
  void initState() {
    super.initState();

    _form = V
        .map({
          'name': V.string().min(1),
          'age': V.int().between(0, 150),
          'height': V.double().positive(),
          'active': V.bool().isTrue(),
          'joined': V.date().before(DateTime(2030)),
          'tags': V.string().min(2).array().min(1).unique(),
          'address': V.map({
            'zip': V.string().min(5),
            'country': V.literal('US'),
          }),
          // Explicit <Role> is required here — Dart can't infer the enum
          // generic inside a V.map({...}) literal (raw context), so without
          // it you'd get VField<Enum> and form.field<Role>('role') would
          // throw an ArgumentError.
          'role': V.enm<Role>(Role.values),
          // V.coerce.int() lets the union accept a raw string and convert
          // it to int internally — no manual parse in the widget.
          'id': V.union([V.string().uuid(), V.coerce.int().min(1)]),
          'confirmation': V.string(),
          'type': V.string(),
          'username': V.string().nullable(),
        })
        // Cross-field: confirmation must match name.
        .refineFormField(
          (data) => data['name'] == data['confirmation'],
          path: 'confirmation',
          message: 'must match name',
        )
        // Conditional SYNC: person ≥ 18.
        .when(
          'type',
          equals: 'person',
          then: {
            'age': V.int().min(18, message: (_) => 'person must be 18+'),
          },
        )
        // Conditional ASYNC: member username must not be taken.
        .when(
          'type',
          equals: 'member',
          then: {
            'username': V.string().min(3).refineAsync(
              (v) async {
                await Future<void>.delayed(
                  const Duration(milliseconds: 400),
                );
                return !_takenUsernames.contains(v.toLowerCase());
              },
              message: 'username taken',
            ),
          },
        )
        .form(
          initialValues: {
            'name': 'Alice',
            'age': 30,
            'height': 1.72,
            'active': true,
            'joined': DateTime(2024, 6, 1),
            'tags': <String>['dart', 'flutter'],
            'address': {'zip': '12345', 'country': 'US'},
            'role': Role.admin,
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'confirmation': 'Alice',
            'type': 'person',
            'username': null,
          },
        );
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<int> get _age => _form.field('age');
  VField<double> get _height => _form.field('height');
  VField<bool> get _active => _form.field('active');
  VField<DateTime> get _joined => _form.field('joined');
  VField<List<String>> get _tags => _form.field('tags');
  VField<Map<String, dynamic>> get _address => _form.field('address');
  VField<Role> get _role => _form.field('role');
  VField<Object> get _id => _form.field('id');
  VField<String> get _confirmation => _form.field('confirmation');
  VField<String> get _type => _form.field('type');
  VField<String> get _username => _form.field('username');

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final valid = await _form.validateAsync();
    if (!mounted) return;

    final data = valid ? await _form.valueAsync : null;
    final errors = valid ? null : await _form.errorsAsync();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _validData = data;
      _validationErrors = errors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complex Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'Combines every primitive + array (unique) + nested map + '
                'enum + union + literal + refineFormField + two .when() '
                'rules (one sync, one async). hasAsync is true because the '
                'member-username branch uses refineAsync, so form.validate() '
                'would throw — submit runs form.validateAsync() and then '
                'form.valueAsync for the parsed result.',
              ),
              const SizedBox(height: 16),
              const SectionTitle('Personal'),
              VTextField(field: _name, label: 'Name'),
              const SizedBox(height: 12),
              _IntField(field: _age, label: 'Age'),
              const SizedBox(height: 12),
              _DoubleField(field: _height, label: 'Height (m)'),
              const SizedBox(height: 12),
              _BoolField(field: _active, label: 'Accept terms'),
              const SizedBox(height: 12),
              _DateField(field: _joined, label: 'Joined'),
              const SizedBox(height: 24),
              const SectionTitle('Profile'),
              _TagsField(field: _tags),
              const SizedBox(height: 12),
              _RoleField(field: _role),
              const SizedBox(height: 12),
              _UnionField(field: _id),
              const SizedBox(height: 24),
              const SectionTitle('Address'),
              const InfoCard(
                'Nested V.map({...}) — wired to the composite field by '
                'rebuilding the sub-map on each change. country uses '
                'V.literal(\'US\'), so anything else fails validation.',
              ),
              const SizedBox(height: 12),
              _AddressFields(field: _address),
              const SizedBox(height: 24),
              const SectionTitle('Conditional rules'),
              const InfoCard(
                'type = person → age must be ≥ 18 (sync). '
                'type = member → username must not be "admin" or "root" '
                '(async, 400ms fake network).',
              ),
              const SizedBox(height: 12),
              _TypeField(field: _type),
              const SizedBox(height: 12),
              VTextField(
                field: _username,
                label: 'Username (required when type = member)',
              ),
              const SizedBox(height: 24),
              const SectionTitle('Cross-field'),
              const InfoCard(
                'Confirmation must equal Name (refineFormField).',
              ),
              const SizedBox(height: 12),
              VTextField(field: _confirmation, label: 'Confirm name'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit (validateAsync)'),
              ),
              if (_validData != null) ...[
                const SizedBox(height: 16),
                _ResultBox.success(data: _validData!),
              ] else if (_validationErrors != null) ...[
                const SizedBox(height: 16),
                _ResultBox.failure(errors: _validationErrors!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- helper widgets ---------------------------------------------------------

class _IntField extends StatelessWidget {
  final VField<int> field;
  final String label;
  const _IntField({required this.field, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: field.key,
      initialValue: field.value?.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (raw) => field.validator(int.tryParse(raw ?? '')),
      onChanged: (raw) => field.onChanged(int.tryParse(raw)),
    );
  }
}

class _DoubleField extends StatelessWidget {
  final VField<double> field;
  final String label;
  const _DoubleField({required this.field, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: field.key,
      initialValue: field.value?.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (raw) => field.validator(double.tryParse(raw ?? '')),
      onChanged: (raw) => field.onChanged(double.tryParse(raw)),
    );
  }
}

class _BoolField extends StatelessWidget {
  final VField<bool> field;
  final String label;
  const _BoolField({required this.field, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: field.listenable,
      builder: (_, __) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: field.value ?? false,
        onChanged: field.onChanged,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final VField<DateTime> field;
  final String label;
  const _DateField({required this.field, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: field.listenable,
      builder: (context, __) => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime(2029, 12, 31),
            initialDate: field.value ?? DateTime.now(),
          );
          if (picked != null) field.set(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(
            field.value != null
                ? field.value!.toIso8601String().substring(0, 10)
                : 'Pick a date',
          ),
        ),
      ),
    );
  }
}

class _TagsField extends StatelessWidget {
  final VField<List<String>> field;
  const _TagsField({required this.field});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return ListenableBuilder(
      listenable: field.listenable,
      builder: (_, __) {
        final tags = field.value ?? const <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Tag (press + to add)',
                suffixIcon: Icon(Icons.add),
              ),
              onSubmitted: (v) {
                final t = v.trim();
                if (t.isEmpty) return;
                field.set([...tags, t]);
                controller.clear();
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (int i = 0; i < tags.length; i++)
                  InputChip(
                    label: Text(tags[i]),
                    onDeleted: () {
                      final next = [...tags]..removeAt(i);
                      field.set(next);
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RoleField extends StatelessWidget {
  final VField<Role> field;
  const _RoleField({required this.field});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: field.listenable,
      builder: (_, __) => DropdownButtonFormField<Role>(
        initialValue: field.value,
        decoration: const InputDecoration(labelText: 'Role'),
        items: [
          for (final r in Role.values)
            DropdownMenuItem(value: r, child: Text(r.name)),
        ],
        onChanged: field.onChanged,
      ),
    );
  }
}

/// Thanks to `V.coerce.int()` inside the union schema, the widget can stay
/// dumb: pass the raw string to the field, let the schema try uuid first
/// and then coerce to int. Invalid input bubbles up as a coherent
/// `invalidUnion` error instead of the confusing "Required" we'd get if
/// we parsed in the widget and fed `null` to the field.
class _UnionField extends StatelessWidget {
  final VField<Object> field;
  const _UnionField({required this.field});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: field.key,
      initialValue: field.value?.toString(),
      decoration: const InputDecoration(labelText: 'id (uuid or int)'),
      validator: (raw) => field.validator(raw),
      onChanged: field.onChanged,
    );
  }
}

class _AddressFields extends StatelessWidget {
  final VField<Map<String, dynamic>> field;
  const _AddressFields({required this.field});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: field.listenable,
      builder: (_, __) {
        final current = field.value ?? const {};
        final zip = current['zip']?.toString() ?? '';
        final country = current['country']?.toString() ?? 'US';
        return Column(
          children: [
            TextFormField(
              initialValue: zip,
              decoration: const InputDecoration(labelText: 'ZIP (min 5)'),
              onChanged: (v) => field.set({...current, 'zip': v}),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: country,
              decoration: const InputDecoration(
                labelText: 'Country (must be "US")',
              ),
              onChanged: (v) => field.set({...current, 'country': v}),
            ),
          ],
        );
      },
    );
  }
}

class _TypeField extends StatelessWidget {
  final VField<String> field;
  const _TypeField({required this.field});

  @override
  Widget build(BuildContext context) {
    const options = ['person', 'member', 'other'];
    return ListenableBuilder(
      listenable: field.listenable,
      builder: (_, __) => DropdownButtonFormField<String>(
        initialValue: field.value,
        decoration: const InputDecoration(labelText: 'Type'),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: field.onChanged,
      ),
    );
  }
}

/// Translucent coloured box that shows either the parsed form value (green,
/// on success) or the validation errors (red, on failure).
class _ResultBox extends StatelessWidget {
  final String title;
  final String body;
  final MaterialColor color;

  const _ResultBox._({
    required this.title,
    required this.body,
    required this.color,
  });

  factory _ResultBox.success({required Map<String, dynamic> data}) {
    return _ResultBox._(
      title: 'Form is valid',
      body: prettyJson(data),
      color: Colors.green,
    );
  }

  factory _ResultBox.failure({required Map<String, String> errors}) {
    return _ResultBox._(
      title: 'Form has errors',
      body: prettyJson(errors),
      color: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}
