import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

enum Priority { low, medium, high, critical }

class MultiTypeFormPage extends StatefulWidget {
  const MultiTypeFormPage({super.key});

  @override
  State<MultiTypeFormPage> createState() => _MultiTypeFormPageState();
}

class _MultiTypeFormPageState extends State<MultiTypeFormPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();
    _form = V.map({
      'title': V.string().min(3),
      'description': V.string().min(10),
      'maxParticipants': V.int().min(1),
      'rating': V.double().min(0).max(5),
      'isPublic': V.bool(),
      'eventDate': V.date(),
      'priority': V.enm<Priority>(Priority.values),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  VField<String> get _title => _form.field('title');
  VField<String> get _description => _form.field('description');
  VField<int> get _maxParticipants => _form.field('maxParticipants');
  VField<double> get _rating => _form.field('rating');
  VField<bool> get _isPublic => _form.field('isPublic');
  VField<DateTime> get _eventDate => _form.field('eventDate');
  VField<Priority> get _priority => _form.field('priority');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _eventDate.set(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi Type Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'This form combines all supported field types: VString, VInt, '
                'VDouble, VBool, VDate, and VEnum. Each type integrates with '
                'a different Flutter widget. Non-string fields use set() to '
                'update values programmatically since they cannot use onChanged '
                'directly with TextFormField.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: _title.onChanged,
                validator: _title.validator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onChanged: _description.onChanged,
                validator: _description.validator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Max Participants'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) _maxParticipants.set(parsed);
                },
                validator: (_) =>
                    _maxParticipants.validator(_maxParticipants.value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Rating (0.0 - 5.0)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) _rating.set(parsed);
                },
                validator: (_) => _rating.validator(_rating.value),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _isPublic.listenable,
                builder: (context, _) {
                  return SwitchListTile(
                    title: const Text('Public Event'),
                    subtitle: Text(
                      _isPublic.value == true
                          ? 'Visible to everyone'
                          : 'Private',
                    ),
                    value: _isPublic.value ?? false,
                    onChanged: (val) => _isPublic.set(val),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _eventDate.listenable,
                builder: (context, _) {
                  final date = _eventDate.value;
                  return FormField<DateTime>(
                    validator: (_) => _eventDate.validator(_eventDate.value),
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Event Date'),
                            subtitle: Text(
                              date != null
                                  ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                                  : 'Tap to select a date',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _pickDate,
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
                  );
                },
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _priority.listenable,
                builder: (context, _) {
                  return DropdownButtonFormField<Priority>(
                    decoration: const InputDecoration(labelText: 'Priority'),
                    initialValue: _priority.value,
                    items: Priority.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.name[0].toUpperCase() + p.name.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => _priority.set(val),
                    validator: (_) => _priority.validator(_priority.value),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_form.validate()) {
                    final values = _form.value;
                    printJson({
                      'title': values['title'],
                      'description': values['description'],
                      'maxParticipants': values['maxParticipants'],
                      'rating': values['rating'],
                      'isPublic': values['isPublic'],
                      'eventDate': values['eventDate']?.toString(),
                      'priority': _priority.value?.name,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event created!')),
                    );
                  }
                },
                child: const Text('Create Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
