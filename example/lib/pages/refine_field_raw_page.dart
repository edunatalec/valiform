import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

/// Demonstrates the practical difference between `refineField` (parsed)
/// and `refineFieldRaw` (raw) — same callback, different verdicts when a
/// field has a transform.
///
/// Both forms have a `code` field with `.trim().toUpperCase()`. Both
/// schemas register the same predicate "code must be exactly 8
/// characters". The left form uses `refineField`, the right uses
/// `refineFieldRaw`. Type `'  abcdefgh  '` (10 chars raw, 8 chars after
/// trim) and watch:
///
///  - `refineField` (parsed) sees `'ABCDEFGH'` (8 chars) → passes.
///  - `refineFieldRaw` (raw) sees `'  abcdefgh  '` (10 chars) → fails.
class RefineFieldRawPage extends StatefulWidget {
  const RefineFieldRawPage({super.key});

  @override
  State<RefineFieldRawPage> createState() => _RefineFieldRawPageState();
}

class _RefineFieldRawPageState extends State<RefineFieldRawPage> {
  late final VForm<Map<String, dynamic>> _parsedForm;
  late final VForm<Map<String, dynamic>> _rawForm;

  Map<String, dynamic>? _parsedResult;
  Map<String, String>? _parsedErrors;
  Map<String, dynamic>? _rawResult;
  Map<String, String>? _rawErrors;

  @override
  void initState() {
    super.initState();

    _parsedForm = V.map({'code': V.string().trim().toUpperCase()}).refineField(
      (data) {
        final code = data['code'] as String?;
        return code != null && code.length == 8;
      },
      path: 'code',
      message: 'code must be exactly 8 chars (parsed)',
    ).form(initialValues: {'code': '  abcdefgh  '});

    _rawForm = V.map({'code': V.string().trim().toUpperCase()}).refineFieldRaw(
      (data) {
        final code = data['code'] as String?;
        return code != null && code.length == 8;
      },
      path: 'code',
      message: 'code must be exactly 8 chars (raw)',
    ).form(initialValues: {'code': '  abcdefgh  '});
  }

  @override
  void dispose() {
    _parsedForm.dispose();
    _rawForm.dispose();

    super.dispose();
  }

  void _submitParsed() {
    setState(() {
      if (_parsedForm.validate()) {
        _parsedResult = _parsedForm.value;
        _parsedErrors = null;
      } else {
        _parsedResult = null;
        _parsedErrors = _parsedForm.errors();
      }
    });
  }

  void _submitRaw() {
    setState(() {
      if (_rawForm.validate()) {
        _rawResult = _rawForm.value;
        _rawErrors = null;
      } else {
        _rawResult = null;
        _rawErrors = _rawForm.errors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('refineField vs refineFieldRaw')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoCard(
              'Both forms have the same field (`code` with .trim().toUpperCase()) '
              'and the same rule: code length must be 8. The difference is when '
              'the rule fires.',
            ),
            const SizedBox(height: 24),
            const SectionTitle(
                '1. refineField (parsed) — passes for 8 chars after trim'),
            const SizedBox(height: 8),
            const InfoCard(
              'refineField sees the post-pipeline value: the trim shaves the '
              "spaces, so '  abcdefgh  ' (10 chars raw) becomes 'ABCDEFGH' "
              '(8 chars). Length matches → passes.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _parsedForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VTextField(
                    field: _parsedForm.field<String>('code'),
                    label: 'Code',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitParsed,
                    child: const Text('Submit (parsed)'),
                  ),
                  ResultFeedback(
                    data: _parsedResult,
                    errors: _parsedErrors,
                  ),
                ],
              ),
            ),
            const Divider(height: 48),
            const SectionTitle(
                '2. refineFieldRaw (raw) — fails because 10 chars > 8'),
            const SizedBox(height: 8),
            const InfoCard(
              'refineFieldRaw sees the input as the user typed it: '
              "'  abcdefgh  ' is 10 chars, the rule requires 8 → fails. "
              'Use this when the rule must catch the original input shape, '
              'before transforms normalize it away.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _rawForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VTextField(
                    field: _rawForm.field<String>('code'),
                    label: 'Code',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitRaw,
                    child: const Text('Submit (raw)'),
                  ),
                  ResultFeedback(data: _rawResult, errors: _rawErrors),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const InfoCard.highlight(
              'Rule of thumb: prefer refineField. Reach for refineFieldRaw '
              'only when the rule depends on the input as the user typed it '
              '(original casing, whitespace, pre-coercion shape).',
            ),
          ],
        ),
      ),
    );
  }
}
