import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../utils.dart';
import '../widgets/widgets.dart';

/// Two ways to customize the error shown when a required field is left
/// untouched:
///
/// 1. **`V.bool(message: ...)`** — overrides the built-in `required`
///    message (new in validart). Single source of truth, applies to both
///    the null case and any later null-related check.
///
/// 2. **`.preprocess((v) => v ?? false)`** — normalizes the untouched
///    value so `isTrue`'s own message always fires. Useful when you want
///    the same message for "untouched" and "explicitly false".
class RequiredMessagePage extends StatefulWidget {
  const RequiredMessagePage({super.key});

  @override
  State<RequiredMessagePage> createState() => _RequiredMessagePageState();
}

class _RequiredMessagePageState extends State<RequiredMessagePage> {
  late final VForm<Map<String, dynamic>> _requiredMessageForm;
  late final VForm<Map<String, dynamic>> _preprocessForm;

  @override
  void initState() {
    super.initState();

    // Approach 1: customize the required error message directly on the
    // type constructor. Validart propagates `_message` through
    // `_resolveNull`, so null inputs surface this text instead of the
    // default translation.
    _requiredMessageForm = V.map({
      'acceptTerms': V.bool(message: 'You must accept the terms to continue')
          .isTrue(message: 'You must accept the terms to continue'),
    }).form();

    // Approach 2: preprocess null → false so `isTrue` always runs and
    // owns the message. The type stays required (non-nullable), but the
    // null branch is neutralized before validation starts.
    _preprocessForm = V.map({
      'acceptTerms': V.bool()
          .preprocess((v) => v ?? false)
          .isTrue(message: 'You must accept the terms to continue'),
    }).form();
  }

  @override
  void dispose() {
    _requiredMessageForm.dispose();
    _preprocessForm.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Required Message')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoCard(
              'A required checkbox that the user never touches stores '
              '`null`, not `false`. The default `required` message is a '
              'generic translation — often not what you want. Here are two '
              'ways to surface a custom message in that scenario.',
            ),
            const SizedBox(height: 24),
            _Demo(
              title: 'Approach 1 — V.bool(message: ...)',
              description:
                  'Pass the custom message to the constructor. It overrides '
                  'the required/null error. Pair with isTrue so both untouched '
                  'and explicitly-false show the same text.',
              schemaSnippet: "V.bool(message: '...').isTrue(message: '...')",
              form: _requiredMessageForm,
            ),
            const Divider(height: 48),
            _Demo(
              title: 'Approach 2 — preprocess((v) => v ?? false)',
              description:
                  'Coerce null into false before validation. isTrue then '
                  'always fires and owns the message. Only one message to '
                  'maintain, but the field technically becomes "always '
                  'checkable" (no required error ever fires).',
              schemaSnippet:
                  "V.bool().preprocess((v) => v ?? false).isTrue(message: '...')",
              form: _preprocessForm,
            ),
          ],
        ),
      ),
    );
  }
}

class _Demo extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final field = form.field<bool>('acceptTerms');

    return Form(
      key: form.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title),
          const SizedBox(height: 8),
          InfoCard(description),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              schemaSnippet,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          FormField<bool>(
            initialValue: field.value ?? false,
            validator: (_) => field.validator(field.value),
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    title: const Text('I accept the terms and conditions'),
                    value: field.value ?? false,
                    onChanged: (val) {
                      field.set(val);
                      state.didChange(val);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (form.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Submitted: ${prettyJson(form.value)}'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
