import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class RootErrorsPage extends StatefulWidget {
  const RootErrorsPage({super.key});

  @override
  State<RootErrorsPage> createState() => _RootErrorsPageState();
}

class _RootErrorsPageState extends State<RootErrorsPage> {
  late final VForm<Map<String, dynamic>> _form;

  Map<String, dynamic>? _result;
  Map<String, String>? _errors;

  @override
  void initState() {
    super.initState();

    // refine(..., dependsOn: {...}) keeps the cross-field rule running
    // even when sibling fields fail individually, which is exactly when
    // the rootErrors banner shines: name is too short AND the date range
    // is wrong → both errors aggregate (field-keyed + root-level).
    _form = V.map({
      'name': V.string().min(3),
      'startDate': V.date(),
      'endDate': V.date(),
    }).refine(
      (m) => (m['endDate'] as DateTime).isAfter(m['startDate'] as DateTime),
      message: 'endDate must be after startDate',
      dependsOn: const {'startDate', 'endDate'},
    ).form(
      initialValues: {
        'name': '',
        'startDate': DateTime(2026, 5, 1),
        'endDate': DateTime(2026, 4, 1),
      },
    );
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  void _submit() {
    setState(() {
      // form.validate() now considers schema-level rules (refine,
      // equalFields, dependsOn) on top of per-field validators, so a
      // single call is enough. Field-keyed errors land in form.errors();
      // root errors land in form.rootErrors and the banner above renders
      // them — they do NOT show up under any FormField.
      if (_form.validate()) {
        _result = _form.value;
        _errors = null;
      } else {
        _result = null;
        _errors = _form.errors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Root Errors')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'A schema-level refine() with no path emits a root-level '
                'error. Render it as a banner above the form via '
                'form.rootErrors. dependsOn lets the rule keep running even '
                'when other fields fail, so the banner and the field errors '
                'aggregate instead of masking each other.',
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _form.listenable,
                builder: (context, _) {
                  final root = _form.rootErrors;
                  if (root.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RootErrorBanner(messages: root),
                  );
                },
              ),
              VTextField(
                field: _form.field<String>('name'),
                label: 'Name',
              ),
              const SizedBox(height: 8),
              _DateField(
                label: 'Start date',
                field: _form.field<DateTime>('startDate'),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: 'End date',
                field: _form.field<DateTime>('endDate'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
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

/// Same throwaway date input used by `object_validation_page.dart` —
/// duplicated here to keep each page self-contained for copy/paste.
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
