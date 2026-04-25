import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class SignUpDto {
  final String password;
  final String confirmPassword;

  const SignUpDto({required this.password, required this.confirmPassword});

  Map<String, dynamic> toJson() => {
        'password': password,
        'confirmPassword': confirmPassword,
      };
}

class TaxPayer {
  final String country;
  final String? taxId;

  const TaxPayer({required this.country, this.taxId});

  Map<String, dynamic> toJson() => {'country': country, 'taxId': taxId};
}

class Booking {
  final DateTime startDate;
  final DateTime endDate;

  const Booking({required this.startDate, required this.endDate});

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
}

class ObjectValidationPage extends StatefulWidget {
  const ObjectValidationPage({super.key});

  @override
  State<ObjectValidationPage> createState() => _ObjectValidationPageState();
}

class _ObjectValidationPageState extends State<ObjectValidationPage> {
  late final VForm<SignUpDto> _equalForm;
  late final VForm<TaxPayer> _whenForm;
  late final VForm<Booking> _refineFieldForm;

  Map<String, dynamic>? _equalResult;
  Map<String, String>? _equalErrors;

  Map<String, dynamic>? _whenResult;
  Map<String, String>? _whenErrors;

  Map<String, dynamic>? _refineFieldResult;
  Map<String, String>? _refineFieldErrors;

  @override
  void initState() {
    super.initState();

    _equalForm = V
        .object<SignUpDto>()
        .field('password', (d) => d.password, V.string().password())
        .field('confirmPassword', (d) => d.confirmPassword, V.string())
        .equalFields(
          'password',
          'confirmPassword',
          message: 'Passwords must match',
        )
        .form(
          builder: (data) => SignUpDto(
            password: data['password'] ?? '',
            confirmPassword: data['confirmPassword'] ?? '',
          ),
        );

    _whenForm = V
        .object<TaxPayer>()
        .field('country', (t) => t.country, V.string())
        .field('taxId', (t) => t.taxId, V.string().nullable())
        .when(
      'country',
      equals: 'US',
      then: {
        'taxId': V.string().min(9, message: (_) => 'US SSN must be 9 chars'),
      },
    ).form(
      builder: (data) => TaxPayer(
        country: data['country'] ?? '',
        taxId: data['taxId'] as String?,
      ),
      initialValue: const TaxPayer(country: 'BR'),
    );

    _refineFieldForm = V
        .object<Booking>()
        .field('startDate', (b) => b.startDate, V.date())
        .field('endDate', (b) => b.endDate, V.date())
        .refineField(
          (b) => b.endDate.isAfter(b.startDate),
          path: 'endDate',
          message: 'endDate must be after startDate',
        )
        .form(
          builder: (data) => Booking(
            startDate: data['startDate'] as DateTime,
            endDate: data['endDate'] as DateTime,
          ),
          initialValue: Booking(
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 4, 1),
          ),
        );
  }

  @override
  void dispose() {
    _equalForm.dispose();
    _whenForm.dispose();
    _refineFieldForm.dispose();

    super.dispose();
  }

  void _submitEqual() {
    setState(() {
      if (_equalForm.validate() && _equalForm.silentValidate()) {
        _equalResult = _equalForm.value.toJson();
        _equalErrors = null;
      } else {
        _equalResult = null;
        // equalFields is root-level — the banner above the fields renders it.
        _equalErrors = _equalForm.errors();
      }
    });
  }

  void _submitWhen() {
    setState(() {
      if (_whenForm.validate()) {
        _whenResult = _whenForm.value.toJson();
        _whenErrors = null;
      } else {
        _whenResult = null;
        _whenErrors = _whenForm.errors();
      }
    });
  }

  void _submitRefineField() {
    setState(() {
      if (_refineFieldForm.validate()) {
        _refineFieldResult = _refineFieldForm.value.toJson();
        _refineFieldErrors = null;
      } else {
        _refineFieldResult = null;
        _refineFieldErrors = _refineFieldForm.errors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final equalPassword = _equalForm.field<String>('password');
    final equalConfirm = _equalForm.field<String>('confirmPassword');

    final taxId = _whenForm.field<String>('taxId');

    return Scaffold(
      appBar: AppBar(title: const Text('Object Validation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _equalForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('1. equalFields on VObject'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'VObject<SignUpDto>().equalFields(\'password\', '
                    '\'confirmPassword\') is the typed-DTO equivalent of '
                    'the VMap shortcut. It emits a root-level error — '
                    'render it via form.rootErrors as a banner.',
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _equalForm.listenable,
                    builder: (context, _) {
                      final root = _equalForm.rootErrors;
                      if (root.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RootErrorBanner(messages: root),
                      );
                    },
                  ),
                  VTextField(
                    field: equalPassword,
                    hint: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  VTextField(
                    field: equalConfirm,
                    hint: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitEqual,
                    child: const Text('Submit'),
                  ),
                  ResultFeedback(data: _equalResult, errors: _equalErrors),
                ],
              ),
            ),
            const Divider(height: 48),
            Form(
              key: _whenForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('2. .when() on VObject'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'When country == US, taxId is validated as a 9-char SSN. '
                    'For other countries, taxId is optional. The conditional '
                    'rule is wired into the per-field validator so the error '
                    'shows up inline.',
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _whenForm.listenable,
                    builder: (context, _) {
                      final country = _whenForm.field<String>('country').value;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Country'),
                        initialValue: country ?? 'BR',
                        items: const [
                          DropdownMenuItem(value: 'US', child: Text('US')),
                          DropdownMenuItem(value: 'BR', child: Text('BR')),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) =>
                            _whenForm.field<String>('country').onChanged(v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  VTextField(field: taxId, hint: 'Tax ID'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitWhen,
                    child: const Text('Submit'),
                  ),
                  ResultFeedback(data: _whenResult, errors: _whenErrors),
                ],
              ),
            ),
            const Divider(height: 48),
            Form(
              key: _refineFieldForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('3. .refineField() on VObject'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'refineField receives the entire instance but pins the '
                    'error to a specific field path. Useful when the rule '
                    'depends on more than one field but the message belongs '
                    'on just one of them (e.g. endDate after startDate).',
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    label: 'Start date',
                    field: _refineFieldForm.field<DateTime>('startDate'),
                  ),
                  const SizedBox(height: 8),
                  _DateField(
                    label: 'End date',
                    field: _refineFieldForm.field<DateTime>('endDate'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitRefineField,
                    child: const Text('Submit'),
                  ),
                  ResultFeedback(
                    data: _refineFieldResult,
                    errors: _refineFieldErrors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small text-based date input used only by this page so we can demo
/// `refineField` without pulling in a calendar dependency.
class _DateField extends StatelessWidget {
  final String label;
  final VField<DateTime> field;

  const _DateField({required this.label, required this.field});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: field.key,
      initialValue: field.initialValue?.toIso8601String().substring(0, 10),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'YYYY-MM-DD',
      ),
      keyboardType: TextInputType.datetime,
      validator: (_) => field.validator(field.value),
      onChanged: (value) {
        final parsed = DateTime.tryParse(value);
        field.onChanged(parsed);
      },
    );
  }
}
