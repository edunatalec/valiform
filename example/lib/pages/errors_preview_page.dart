import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../utils.dart';
import '../widgets/widgets.dart';

class ErrorsPreviewPage extends StatefulWidget {
  const ErrorsPreviewPage({super.key});

  @override
  State<ErrorsPreviewPage> createState() => _ErrorsPreviewPageState();
}

class _ErrorsPreviewPageState extends State<ErrorsPreviewPage> {
  late final VForm<Map<String, dynamic>> _smallForm;
  late final VForm<Map<String, dynamic>> _singleForm;
  late final VForm<Map<String, dynamic>> _largeForm;

  Map<String, dynamic>? _smallResult;
  Map<String, dynamic>? _largeResult;

  @override
  void initState() {
    super.initState();

    _smallForm = V.map({
      'email': V.string().email(),
      'password': V.string().password(),
    }).form();

    _singleForm = V.map({
      'username': V.string().min(4).max(20),
    }).form();

    _largeForm = V.map({
      'firstName': V.string().min(2),
      'lastName': V.string().min(2),
      'email': V.string().email(),
      'age': V.int().min(18).max(120),
      'phone': V.string().min(10),
    }).form();
  }

  @override
  void dispose() {
    _smallForm.dispose();
    _singleForm.dispose();
    _largeForm.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Errors Preview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoCard(
              'form.errors() returns a Map<String, String>? with every field '
              'that currently fails validation (null when all pass). '
              'field.error returns the message for a single field. Both are '
              'read-only — no consumption of one-shot manual errors, no UI '
              'side effects. Use them for live previews, debug panels, or '
              'custom error summaries.',
            ),
            const SizedBox(height: 24),
            _buildSmallFormSection(),
            const Divider(height: 48),
            _buildSingleFieldSection(),
            const Divider(height: 48),
            _buildLargeFormSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFormSection() {
    final email = _smallForm.field<String>('email');
    final password = _smallForm.field<String>('password');

    return Form(
      key: _smallForm.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Live form.errors() — 2 fields'),
          const SizedBox(height: 8),
          const InfoCard(
            'Type in each field and watch the errors map update live. '
            'Empty → required error; invalid → field-specific message. '
            'When both pass, errors() returns null.',
          ),
          const SizedBox(height: 16),
          VTextField(
            field: email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          VTextField(field: password, label: 'Password', obscureText: true),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _smallForm.listenable,
            builder: (context, _) =>
                _ErrorsPreview(errors: _smallForm.errors()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _smallResult = _smallForm.validate() ? _smallForm.value : null;
              });
            },
            child: const Text('Submit'),
          ),
          ResultFeedback(data: _smallResult),
        ],
      ),
    );
  }

  Widget _buildSingleFieldSection() {
    final username = _singleForm.field<String>('username');

    return Form(
      key: _singleForm.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Per-field error via field.error'),
          const SizedBox(height: 8),
          const InfoCard(
            'field.error is read-only — use it to build a custom error '
            'display (inline banner, tooltip, badge). The TextFormField '
            'still shows the error the standard way; this example mirrors '
            'it into a custom pill below to illustrate the API.',
          ),
          const SizedBox(height: 16),
          VTextField(field: username, label: 'Username (4-20 chars)'),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: username.listenable,
            builder: (context, _) {
              final err = username.error;
              if (err == null) return const SizedBox.shrink();
              final colorScheme = Theme.of(context).colorScheme;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        err,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLargeFormSection() {
    final firstName = _largeForm.field<String>('firstName');
    final lastName = _largeForm.field<String>('lastName');
    final email = _largeForm.field<String>('email');
    final age = _largeForm.field<int>('age');
    final phone = _largeForm.field<String>('phone');

    return Form(
      key: _largeForm.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Errors summary — 5 fields'),
          const SizedBox(height: 8),
          const InfoCard(
            'Larger forms benefit from a consolidated error summary. The '
            'list below renders every failing field with its message, '
            'updating live as you type.',
          ),
          const SizedBox(height: 16),
          VTextField(field: firstName, label: 'First name'),
          const SizedBox(height: 12),
          VTextField(field: lastName, label: 'Last name'),
          const SizedBox(height: 12),
          VTextField(
            field: email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Age (18-120)'),
            keyboardType: TextInputType.number,
            onChanged: (value) => age.onChanged(int.tryParse(value)),
            validator: (_) => age.validator(age.value),
          ),
          const SizedBox(height: 12),
          VTextField(
            field: phone,
            label: 'Phone',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _largeForm.listenable,
            builder: (context, _) =>
                _ErrorsSummary(errors: _largeForm.errors()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _largeResult = _largeForm.validate() ? _largeForm.value : null;
              });
            },
            child: const Text('Submit'),
          ),
          ResultFeedback(data: _largeResult),
        ],
      ),
    );
  }
}

class _ErrorsPreview extends StatelessWidget {
  final Map<String, String>? errors;

  const _ErrorsPreview({required this.errors});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errors == null
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'form.errors():',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errors == null ? 'null (all valid)' : prettyJson(errors),
            style: TextStyle(
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorsSummary extends StatelessWidget {
  final Map<String, String>? errors;

  const _ErrorsSummary({required this.errors});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (errors == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'All fields valid',
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${errors!.length} field(s) need attention',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          ...errors!.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                  Text(
                    '${e.key}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
