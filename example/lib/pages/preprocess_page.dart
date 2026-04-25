import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class Profile {
  final String country;
  final String state;
  final String name;
  final String email;

  const Profile({
    required this.country,
    required this.state,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'country': country,
        'state': state,
        'name': name,
        'email': email,
      };
}

class PreprocessPage extends StatefulWidget {
  const PreprocessPage({super.key});

  @override
  State<PreprocessPage> createState() => _PreprocessPageState();
}

class _PreprocessPageState extends State<PreprocessPage> {
  late final VForm<Map<String, dynamic>> _mapForm;
  late final VForm<Profile> _objectForm;

  Map<String, dynamic>? _mapResult;
  Map<String, dynamic>? _objectResult;

  @override
  void initState() {
    super.initState();

    // Section 1 — VMap container preprocess.
    //
    // Cross-field rewrite: when country == 'US', state is uppercased.
    // Per-field 'name' uses field-level preprocess to trim. Both reach the
    // per-field validator and parsedValue, mirroring validart's
    // safeParse pipeline.
    _mapForm = V.map({
      'country': V.string(),
      'state': V.string().min(2),
      'name': V
          .string()
          .preprocess(
            (v) => v is String ? v.trim() : v,
          )
          .min(2),
    }).preprocess((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      if (m['country'] == 'US' && m['state'] is String) {
        m['state'] = (m['state'] as String).toUpperCase();
      }
      return m;
    }).form(
      initialValues: {
        'country': 'US',
        'state': 'tx',
        'name': '  Alice  ',
      },
    );

    // Section 2 — VObject container preprocess.
    //
    // Same idea but on a typed DTO: container preprocess normalizes the
    // entire Profile instance at once (uppercase state when country=US,
    // trim name, lowercase email). Per-field validators see the normalized
    // values, so what the schema accepts is exactly what the UI accepts.
    _objectForm = V
        .object<Profile>()
        .field('country', (p) => p.country, V.string())
        .field('state', (p) => p.state, V.string().min(2))
        .field('name', (p) => p.name, V.string().min(2))
        .field('email', (p) => p.email, V.string().email())
        .preprocess((raw) {
      if (raw is! Profile) return raw;
      final state = raw.country == 'US' ? raw.state.toUpperCase() : raw.state;
      return Profile(
        country: raw.country,
        state: state,
        name: raw.name.trim(),
        email: raw.email.toLowerCase(),
      );
    }).form(
      builder: (data) => Profile(
        country: data['country'] as String? ?? '',
        state: data['state'] as String? ?? '',
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
      ),
      initialValue: const Profile(
        country: 'US',
        state: 'tx',
        name: '  Alice  ',
        email: 'ALICE@Example.COM',
      ),
    );
  }

  @override
  void dispose() {
    _mapForm.dispose();
    _objectForm.dispose();

    super.dispose();
  }

  void _submitMap() {
    setState(() {
      if (_mapForm.validate()) {
        _mapResult = _mapForm.value;
      } else {
        _mapResult = null;
      }
    });
  }

  void _submitObject() {
    setState(() {
      if (_objectForm.validate()) {
        _objectResult = _objectForm.value.toJson();
      } else {
        _objectResult = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preprocess')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('1. VMap container preprocess'),
            const SizedBox(height: 8),
            const InfoCard(
              "Cross-field rewrite: when country == 'US', state is "
              "uppercased before validation. The 'name' field also has a "
              'field-level preprocess that trims. Watch raw vs parsed: each '
              "field's parsedValue reflects the post-pipeline value, even "
              'though field.value (the raw) stays untouched.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _mapForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CountryDropdown(
                    field: _mapForm.field<String>('country'),
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _mapForm.field<String>('state'),
                    label: 'State',
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _mapForm.field<String>('name'),
                    label: 'Name (will be trimmed)',
                  ),
                  const SizedBox(height: 16),
                  _RawVsParsedTable(
                    listenable: _mapForm.listenable,
                    rows: () => [
                      _Row('country', _mapForm.field<String>('country')),
                      _Row('state', _mapForm.field<String>('state')),
                      _Row('name', _mapForm.field<String>('name')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitMap,
                    child: const Text('Submit'),
                  ),
                  if (_mapResult != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.success(data: _mapResult!),
                  ],
                ],
              ),
            ),
            const Divider(height: 48),
            const SectionTitle('2. VObject container preprocess'),
            const SizedBox(height: 8),
            const InfoCard(
              'Same idea, typed DTO: container preprocess rewrites the whole '
              'Profile instance (uppercase state for US, trim name, '
              'lowercase email). Per-field validator and parsedValue stay in '
              'sync with form.value — what the schema accepts is what the '
              'UI accepts.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _objectForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CountryDropdown(
                    field: _objectForm.field<String>('country'),
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _objectForm.field<String>('state'),
                    label: 'State',
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _objectForm.field<String>('name'),
                    label: 'Name (will be trimmed)',
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: _objectForm.field<String>('email'),
                    label: 'Email (will be lowercased)',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _RawVsParsedTable(
                    listenable: _objectForm.listenable,
                    rows: () => [
                      _Row('country', _objectForm.field<String>('country')),
                      _Row('state', _objectForm.field<String>('state')),
                      _Row('name', _objectForm.field<String>('name')),
                      _Row('email', _objectForm.field<String>('email')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitObject,
                    child: const Text('Submit'),
                  ),
                  if (_objectResult != null) ...[
                    const SizedBox(height: 16),
                    ResultBox.success(data: _objectResult!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  final VField<String> field;

  const _CountryDropdown({required this.field});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: field.listenable,
      builder: (context, _) {
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Country'),
          initialValue: field.value ?? 'US',
          items: const [
            DropdownMenuItem(value: 'US', child: Text('US')),
            DropdownMenuItem(value: 'BR', child: Text('BR')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: field.onChanged,
        );
      },
    );
  }
}

/// A single row in the raw-vs-parsed table.
class _Row {
  final String label;
  final VField<String> field;

  const _Row(this.label, this.field);
}

/// Live table that shows, for each field, the current raw value
/// (`field.value`) side-by-side with the post-pipeline value
/// (`field.parsedValue`). Cells with raw != parsed are highlighted to
/// make the preprocess "visible".
class _RawVsParsedTable extends StatelessWidget {
  final Listenable listenable;
  final List<_Row> Function() rows;

  const _RawVsParsedTable({required this.listenable, required this.rows});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final rs = rows();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  _headerCell('Field'),
                  _headerCell('Raw (field.value)'),
                  _headerCell('Parsed (field.parsedValue)'),
                ],
              ),
              for (final r in rs)
                TableRow(
                  children: [
                    _cell(r.label, bold: true),
                    _cell(_renderQuoted(r.field.value)),
                    _cell(
                      _renderQuoted(r.field.parsedValue),
                      changed: r.field.value != r.field.parsedValue,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );

  Widget _cell(
    String text, {
    bool bold = false,
    bool changed = false,
    ColorScheme? colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
          fontFamily: 'monospace',
          color: changed ? colorScheme?.primary : null,
        ),
      ),
    );
  }

  String _renderQuoted(Object? v) {
    if (v == null) return 'null';
    if (v is String) return '"$v"';
    return v.toString();
  }
}
