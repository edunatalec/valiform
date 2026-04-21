import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

/// Demonstrates the three ways to seed a field's initial value and the
/// resolution order in valiform:
///
///   1. `initialValues[key]` in `.form()` — always wins if provided
///      (even when the value is `null`, which is treated as an explicit
///      "opt out" of any default).
///   2. `schema.defaultValue(...)` — used as the fallback initial value
///      when `initialValues` doesn't mention the field.
///   3. `null` — when neither is set.
///
/// Key semantic rule: **a `defaultValue` makes the field "never
/// required"**. The validart pipeline substitutes the default for null
/// *before* any validator runs, so no "required" error is ever produced
/// for that field. Use `initialValues` when you want a pre-filled value
/// that is still subject to validation (e.g., can become empty → error).
class DefaultValuePage extends StatefulWidget {
  const DefaultValuePage({super.key});

  @override
  State<DefaultValuePage> createState() => _DefaultValuePageState();
}

class _DefaultValuePageState extends State<DefaultValuePage> {
  late final VForm<Map<String, dynamic>> _defaultOnlyForm;
  late final VForm<Map<String, dynamic>> _initialOnlyForm;
  late final VForm<Map<String, dynamic>> _bothForm;

  @override
  void initState() {
    super.initState();

    // 1. defaultValue only — pre-fills UI, non-required.
    _defaultOnlyForm = V.map({
      'name': V.string().min(2).defaultValue('Guest'),
    }).form();

    // 2. initialValues only — pre-fills UI, still required.
    _initialOnlyForm = V.map({
      'name': V.string().min(2),
    }).form(initialValues: {'name': 'Alice'});

    // 3. Both — initialValues wins for UI/reset(); defaultValue still
    //    covers the "user cleared the field" scenario.
    _bothForm = V.map({
      'name': V.string().min(2).defaultValue('Guest'),
    }).form(initialValues: {'name': 'Alice'});
  }

  @override
  void dispose() {
    _defaultOnlyForm.dispose();
    _initialOnlyForm.dispose();
    _bothForm.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Default Value')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoCard(
              'Resolution order per field:\n'
              '  1. initialValues[key] (even explicit null wins)\n'
              '  2. schema.defaultValue(...)\n'
              '  3. null\n\n'
              'A defaultValue makes the field NEVER required — the pipeline '
              'substitutes null for the default before any validator runs. '
              'If you need a pre-filled value that must NOT be cleared, use '
              'initialValues instead.',
            ),
            const SizedBox(height: 24),
            _Demo(
              title: '1. defaultValue only',
              description:
                  'UI starts with "Guest". User clears the field → still valid, '
                  'submit sends "Guest". reset() returns to "Guest". No '
                  '`required` error possible.',
              schemaSnippet: "V.string().min(2).defaultValue('Guest')",
              form: _defaultOnlyForm,
            ),
            const Divider(height: 48),
            _Demo(
              title: '2. initialValues only',
              description:
                  'UI starts with "Alice". User clears the field → invalid, '
                  'submit shows `required` (min(2) error). reset() returns to '
                  '"Alice".',
              schemaSnippet:
                  "V.string().min(2)  // form(initialValues: {'name': 'Alice'})",
              form: _initialOnlyForm,
            ),
            const Divider(height: 48),
            _Demo(
              title: '3. Both (initialValues wins the UI)',
              description:
                  'UI starts with "Alice" (explicit wins). reset() returns to '
                  '"Alice". But if user clears the field before submit, the '
                  'defaultValue "Guest" still fills in — so form.value is '
                  'never empty, but the UI shows whatever the user typed.',
              schemaSnippet:
                  "V.string().min(2).defaultValue('Guest')  // + initialValues: {'name': 'Alice'}",
              form: _bothForm,
            ),
          ],
        ),
      ),
    );
  }
}

class _Demo extends StatefulWidget {
  final String title;
  final String description;
  final String schemaSnippet;
  final VForm<Map<String, dynamic>> form;

  const _Demo({
    required this.title,
    required this.description,
    required this.schemaSnippet,
    required this.form,
  });

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  Map<String, dynamic>? _validData;
  Map<String, String>? _errors;

  void _submit() {
    if (widget.form.validate()) {
      setState(() {
        _validData = widget.form.value;
        _errors = null;
      });
    } else {
      setState(() {
        _validData = null;
        _errors = widget.form.errors();
      });
    }
  }

  void _reset() {
    widget.form.reset();
    setState(() {
      _validData = null;
      _errors = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.form.field<String>('name');

    return Form(
      key: widget.form.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(widget.title),
          const SizedBox(height: 8),
          InfoCard(widget.description),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.schemaSnippet,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          VTextField(field: field, label: 'Name'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
          if (_validData != null) ...[
            const SizedBox(height: 12),
            ResultBox.success(data: _validData!),
          ] else if (_errors != null) ...[
            const SizedBox(height: 12),
            ResultBox.failure(errors: _errors!),
          ],
        ],
      ),
    );
  }
}
