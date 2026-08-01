import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

/// Demonstrates exactly how the schema pipeline behaves while the user is
/// typing in a `TextFormField` (`AutovalidateMode.always`).
///
/// The schema piles every transform stage on a single field to make the
/// ordering visible at each keystroke:
///   1. `.preprocess` rewrites `@` to `_at_` before anything else runs.
///   2. `.trim()` strips leading/trailing whitespace.
///   3. `.toLowerCase()` normalises casing.
///   4. `.min(5)` validates the post-pipeline value.
///   5. `.transform` prefixes `user:` after validation succeeds.
///
/// While the user types, the live preview shows:
///   - **You typed** — raw `field.value` (what is sitting in the controller).
///   - **Pipeline sees** — `field.parsedValue` (everything above 1→5 applied).
///   - **Error** — `field.error` (auto-re-evaluated on every change).
class LivePipelinePage extends StatefulWidget {
  const LivePipelinePage({super.key});

  @override
  State<LivePipelinePage> createState() => _LivePipelinePageState();
}

class _LivePipelinePageState extends State<LivePipelinePage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'username': V
          .string()
          .preprocess((v) => v is String ? v.replaceAll('@', '_at_') : v)
          .trim()
          .toLowerCase()
          .min(5, message: (n) => 'Pipeline result must have at least $n chars')
          // Explicit <String>: inside `V.map({...})` Dart otherwise infers the
          // transform's output as `dynamic`, which then degrades the field to
          // `VField<dynamic>` and breaks `form.field<String>('username')`.
          .transform<String>((v) => 'user:$v'),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _username => _form.field('username');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Pipeline')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'Schema: V.string()\n'
                '  .preprocess((v) => v.replaceAll("@", "_at_"))\n'
                '  .trim()\n'
                '  .toLowerCase()\n'
                '  .min(5)\n'
                '  .transform((v) => "user:\$v")\n\n'
                'AutovalidateMode.always re-runs field.validator on every '
                'keystroke. The text in the input does NOT change — what you '
                'see is always what you typed. The pipeline only affects what '
                '`field.parsedValue` returns and what the validator checks '
                'against. Try typing "  AB@C  " slowly.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: _username.key,
                initialValue: _username.initialValue,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Try "  AB@C  " — pipeline becomes "ab_at_c"',
                ),
                validator: _username.validator,
                onChanged: _username.onChanged,
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _username.listenable,
                builder: (context, _) => _PipelineTrace(field: _username),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PipelineTrace extends StatelessWidget {
  final VField<String> field;

  const _PipelineTrace({required this.field});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    final error = Theme.of(context).colorScheme.error;

    final raw = field.value ?? '';
    // Walk the pipeline manually so each intermediate stage is visible.
    final afterPreprocess = raw.replaceAll('@', '_at_');
    final afterTrim = afterPreprocess.trim();
    final afterLowerCase = afterTrim.toLowerCase();
    // field.parsedValue already runs the full pipeline — including the
    // final .transform — so it doubles as the final result.
    final parsed = field.parsedValue ?? '';
    final currentError = field.error;

    Widget step(String label, String value, {bool monospace = true}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: variant),
            ),
          ),
          Expanded(
            child: Text(
              '"$value"',
              style: TextStyle(
                fontFamily: monospace ? 'monospace' : null,
                color: variant,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Pipeline trace (per keystroke)'),
          const SizedBox(height: 8),
          step('1. You typed (raw)', raw),
          step('2. After .preprocess', afterPreprocess),
          step('3. After .trim()', afterTrim),
          step('4. After .toLowerCase()', afterLowerCase),
          step('5. After .transform (final)', parsed),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: Text(
                  'field.error',
                  style: TextStyle(fontWeight: FontWeight.w600, color: variant),
                ),
              ),
              Expanded(
                child: Text(
                  currentError ?? '(none)',
                  style: TextStyle(
                    color: currentError == null ? variant : error,
                    fontWeight: currentError == null
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
