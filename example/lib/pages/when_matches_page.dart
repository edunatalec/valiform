import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

/// Demos for `.whenMatches(...)` — predicate-based conditional validation
/// from validart 2.1.0. Use it whenever `.when(field, equals:, then:)` is
/// not expressive enough: when the trigger needs a comparison other than
/// `==` (`>`, `>=`, `oneOf`, ...) or has to combine values from more than
/// one field.
///
/// Two sections, each isolating one capability:
///   - **Numeric threshold** — `age >= 18` triggers a required license,
///     impossible with `when(equals:)` alone.
///   - **Combined predicate** — `role == 'admin' && level > 5` triggers a
///     required audit token, impossible with `when` because the trigger
///     reads two fields.
class WhenMatchesPage extends StatefulWidget {
  const WhenMatchesPage({super.key});

  @override
  State<WhenMatchesPage> createState() => _WhenMatchesPageState();
}

class _WhenMatchesPageState extends State<WhenMatchesPage> {
  late final VForm<Map<String, dynamic>> _formA;
  late final VForm<Map<String, dynamic>> _formB;

  Map<String, dynamic>? _resultA;
  Map<String, String>? _errorsA;

  Map<String, dynamic>? _resultB;
  Map<String, String>? _errorsB;

  @override
  void initState() {
    super.initState();

    _formA = V.map({
      'age': V.int(),
      'license': V.string().nullable(),
    }).whenMatches(
      (m) => (m['age'] as int? ?? 0) >= 18,
      dependsOn: const {'age'},
      then: {'license': V.string().min(5)},
    ).form(initialValues: {'age': 16});

    _formB = V.map({
      'role': V.string(),
      'level': V.int(),
      'auditToken': V.string().nullable(),
    }).whenMatches(
      (m) => m['role'] == 'admin' && (m['level'] as int? ?? 0) > 5,
      dependsOn: const {'role', 'level'},
      then: {'auditToken': V.string().min(8)},
    ).form(initialValues: {'role': 'user', 'level': 1});
  }

  @override
  void dispose() {
    _formA.dispose();
    _formB.dispose();

    super.dispose();
  }

  VField<int> get _age => _formA.field('age');
  VField<String> get _license => _formA.field('license');

  VField<String> get _role => _formB.field('role');
  VField<int> get _level => _formB.field('level');
  VField<String> get _auditToken => _formB.field('auditToken');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('whenMatches')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNumericThresholdSection(),
            const Divider(height: 48),
            _buildCombinedPredicateSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericThresholdSection() {
    return Form(
      key: _formA.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Numeric Threshold'),
          const SizedBox(height: 8),
          const InfoCard(
            'whenMatches lets the trigger be any predicate, not just '
            '"field equals X". Here, license becomes required (min 5 chars) '
            'as soon as age >= 18. Try setting age to 18 and submit with an '
            'empty license — the field-level error appears inline. Drop age '
            'back below 18 and the rule disappears.',
          ),
          const SizedBox(height: 16),
          _IntField(field: _age, label: 'Age'),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _age.listenable,
            builder: (context, _) {
              final required = (_age.value ?? 0) >= 18;
              return VTextField(
                field: _license,
                label: required ? 'License (required)' : 'License (optional)',
                hint: required ? 'min 5 characters' : '— not required —',
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_formA.validate()) {
                  _resultA = _formA.value;
                  _errorsA = null;
                } else {
                  _resultA = null;
                  _errorsA = _formA.errors();
                }
              });
            },
            child: const Text('Submit'),
          ),
          ResultFeedback(data: _resultA, errors: _errorsA),
        ],
      ),
    );
  }

  Widget _buildCombinedPredicateSection() {
    return Form(
      key: _formB.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Combined-Field Predicate'),
          const SizedBox(height: 8),
          const InfoCard(
            'The predicate reads two fields at once: auditToken (min 8 chars) '
            'is required only when role == "admin" AND level > 5. Neither '
            '.when() nor .equalFields() can express this trigger because '
            'both depend on a single comparison; whenMatches takes any '
            'sync function over the raw map. Set role to admin AND level to '
            'something > 5 to see the rule kick in.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Role'),
            initialValue: _role.value,
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (val) {
              if (val != null) _role.set(val);
            },
          ),
          const SizedBox(height: 16),
          _IntField(field: _level, label: 'Level'),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: Listenable.merge([_role.listenable, _level.listenable]),
            builder: (context, _) {
              final required =
                  _role.value == 'admin' && (_level.value ?? 0) > 5;
              return VTextField(
                field: _auditToken,
                label: required
                    ? 'Audit Token (required)'
                    : 'Audit Token (optional)',
                hint: required ? 'min 8 characters' : '— not required —',
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_formB.validate()) {
                  _resultB = _formB.value;
                  _errorsB = null;
                } else {
                  _resultB = null;
                  _errorsB = _formB.errors();
                }
              });
            },
            child: const Text('Submit'),
          ),
          ResultFeedback(data: _resultB, errors: _errorsB),
        ],
      ),
    );
  }
}

/// Minimal int-typed FormField — same parse-then-set bridge used in other
/// example pages so an `int.tryParse` failure surfaces an explicit error
/// instead of degrading to a misleading `required` from the schema.
class _IntField extends StatelessWidget {
  final VField<int> field;
  final String label;

  const _IntField({required this.field, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: field.key,
      initialValue: field.initialValue?.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (raw) {
        if (raw == null || raw.isEmpty) return field.validator(null);

        final int? parsed = int.tryParse(raw);
        if (parsed == null) return 'Enter a valid integer';

        return field.validator(parsed);
      },
      onChanged: (raw) {
        if (raw.isEmpty) {
          field.set(null);
          return;
        }

        final int? parsed = int.tryParse(raw);
        if (parsed != null) field.set(parsed);
      },
    );
  }
}
