import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

/// Demonstrates the classic out-of-order race condition you get when an
/// async `refineAsync` is fired on every keystroke without any guard
/// against late responses overwriting newer ones.
///
/// Both fields share the same schema: `V.string().min(1).refineAsync(...)`
/// where the refineAsync is the fake "is this username taken?" check. The
/// trick is the latency is intentionally INVERTED — short inputs are SLOW
/// (1-2s), longer ones are FAST (200ms). So if you type "a" then "ab", the
/// response for "ab" comes back BEFORE the response for "a".
///
/// The validator side: `field.validator` (sync) cannot await — it only
/// runs sync extras. To surface the async verdict in the UI, the
/// onChanged handler calls `field.computeAsyncError()`, which runs the
/// full async pipeline (including refineAsync) and returns the error
/// message (or null). The handler then mirrors that into the field via
/// `setError` / `clearError` so the attached FormField rebuilds.
///
/// The left field uses that pattern straight — no guard, so a late
/// response for "a" can land AFTER the response for "abcd" and overwrite
/// it. The right field tags every dispatch with a monotonic token and
/// drops the result if a newer keystroke has overtaken it.
class AsyncRacePage extends StatefulWidget {
  const AsyncRacePage({super.key});

  @override
  State<AsyncRacePage> createState() => _AsyncRacePageState();
}

class _AsyncRacePageState extends State<AsyncRacePage> {
  late final VForm<Map<String, dynamic>> _naiveForm;
  late final VForm<Map<String, dynamic>> _guardedForm;

  final List<_LogEntry> _log = [];
  int _seq = 0;

  // Token guard for the right field. Bumped every time onChanged fires;
  // the async callback only applies its result if its captured token
  // still equals this value.
  int _guardToken = 0;

  static const Set<String> _taken = {'admin', 'root', 'a', 'ab', 'abc'};

  @override
  void initState() {
    super.initState();

    final naiveSchema = V.map({
      'username': V.string().min(1).refineAsync(
            _checkAvailability,
            message: 'Username already taken',
          ),
    });

    final guardedSchema = V.map({
      'username': V.string().min(1).refineAsync(
            _checkAvailability,
            message: 'Username already taken',
          ),
    });

    _naiveForm = naiveSchema.form();
    _guardedForm = guardedSchema.form();
  }

  @override
  void dispose() {
    _naiveForm.dispose();
    _guardedForm.dispose();

    super.dispose();
  }

  /// Fake "is this username taken?" call with deliberately inverted
  /// latency so the race is reproducible on every keystroke.
  Future<bool> _checkAvailability(String? value) async {
    final input = value ?? '';
    final id = ++_seq;

    // Inverted latency: short = slow, long = fast.
    final latencyMs = input.length <= 1
        ? 2000
        : input.length <= 2
            ? 1200
            : 200;

    _addLog(
      _LogEntry(
        id: id,
        input: input,
        startedAt: DateTime.now(),
        latencyMs: latencyMs,
        status: _LogStatus.pending,
      ),
    );

    await Future.delayed(Duration(milliseconds: latencyMs));

    final available = !_taken.contains(input);

    _updateLog(
      id,
      (e) => e.copyWith(
        finishedAt: DateTime.now(),
        status: available ? _LogStatus.available : _LogStatus.taken,
      ),
    );

    return available;
  }

  void _addLog(_LogEntry entry) {
    setState(() => _log.insert(0, entry));
  }

  void _updateLog(int id, _LogEntry Function(_LogEntry) update) {
    final i = _log.indexWhere((e) => e.id == id);
    if (i == -1) return;
    setState(() => _log[i] = update(_log[i]));
  }

  /// Naïve handler: pushes the value into the field, then runs the full
  /// async pipeline via `computeAsyncError` and writes whatever result
  /// lands back via `setError` / `clearError`. No coordination — the
  /// LAST response to arrive wins, regardless of which keystroke fired
  /// it. With inverted latency, the slow "a" response overwrites the
  /// fast "abcd" one.
  Future<void> _onNaiveChanged(String? value) async {
    final field = _naiveForm.field<String>('username');
    field.onChanged(value);

    // computeAsyncError runs the schema's full async pipeline (sync
    // extras + refineAsync). Returns the error message or null.
    final error = await field.computeAsyncError();
    if (!mounted) return;

    if (error == null) {
      field.clearError();
    } else {
      field.setError(error, persist: true);
    }
  }

  /// Guarded handler: same flow, but every dispatch captures the current
  /// `_guardToken`. By the time `await` resumes, if another keystroke
  /// has happened, `_guardToken` has been bumped — we drop the late
  /// response on the floor.
  Future<void> _onGuardedChanged(String? value) async {
    final field = _guardedForm.field<String>('username');
    field.onChanged(value);

    final myToken = ++_guardToken;

    final error = await field.computeAsyncError();
    if (!mounted) return;

    // Stale response — newer keystroke has already taken over.
    if (myToken != _guardToken) return;

    if (error == null) {
      field.clearError();
    } else {
      field.setError(error, persist: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Race Condition')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InfoCard(
            'Each keystroke fires an async "is this username taken?" check. '
            'Latency is INVERTED — short inputs (1-2 chars) take 1-2s, '
            'longer ones take 200ms.\n\n'
            'Try typing "a" then quickly "ab" then "abcd". On the left '
            '(naïve), the slow response for "a" arrives AFTER the response '
            'for "abcd" and overwrites it — error toggles backwards.\n\n'
            'Taken: admin, root, a, ab, abc. "abcd" is free.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _naiveForm.key,
            child: _FieldCard(
              title: 'Naïve (no guard)',
              subtitle: 'setError fires with whatever response lands',
              child: TextFormField(
                key: _naiveForm.field<String>('username').key,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Type "a" then quickly "abcd"',
                ),
                onChanged: _onNaiveChanged,
                validator: _naiveForm.field<String>('username').validator,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _guardedForm.key,
            child: _FieldCard(
              title: 'Guarded (request token)',
              subtitle: 'Late responses are dropped if a newer keystroke '
                  'has overtaken them',
              child: TextFormField(
                key: _guardedForm.field<String>('username').key,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Same typing, correct end state',
                ),
                onChanged: _onGuardedChanged,
                validator: _guardedForm.field<String>('username').validator,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const SectionTitle('Async call log'),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
                onPressed: () => setState(_log.clear),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_log.isEmpty)
            Text(
              'Type in either field above to see entries here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ..._log.map((e) => _LogTile(entry: e)),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FieldCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: variant, fontSize: 12)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final _LogEntry entry;

  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final variant = scheme.onSurfaceVariant;

    final Color statusColor;
    final IconData icon;
    final String statusLabel;

    switch (entry.status) {
      case _LogStatus.pending:
        statusColor = scheme.tertiary;
        icon = Icons.hourglass_top;
        statusLabel = 'pending';
        break;
      case _LogStatus.available:
        statusColor = Colors.green.shade700;
        icon = Icons.check_circle;
        statusLabel = 'available';
        break;
      case _LogStatus.taken:
        statusColor = scheme.error;
        icon = Icons.block;
        statusLabel = 'taken';
        break;
    }

    final elapsed =
        entry.finishedAt?.difference(entry.startedAt).inMilliseconds;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${entry.id}  "${entry.input}"  →  $statusLabel',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                Text(
                  'latency: ${entry.latencyMs}ms'
                  '${elapsed == null ? '' : ' · finished in ${elapsed}ms'}',
                  style: TextStyle(fontSize: 11, color: variant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _LogStatus { pending, available, taken }

class _LogEntry {
  final int id;
  final String input;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int latencyMs;
  final _LogStatus status;

  const _LogEntry({
    required this.id,
    required this.input,
    required this.startedAt,
    this.finishedAt,
    required this.latencyMs,
    required this.status,
  });

  _LogEntry copyWith({DateTime? finishedAt, _LogStatus? status}) {
    return _LogEntry(
      id: id,
      input: input,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      latencyMs: latencyMs,
      status: status ?? this.status,
    );
  }
}
