import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

enum Color { red, green, blue, yellow }

class Address {
  final String city;
  final String country;

  const Address({required this.city, required this.country});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address && city == other.city && country == other.country;

  @override
  int get hashCode => city.hashCode ^ country.hashCode;

  @override
  String toString() => '$city, $country';
}

const _addresses = [
  Address(city: 'São Paulo', country: 'Brazil'),
  Address(city: 'New York', country: 'USA'),
  Address(city: 'Tokyo', country: 'Japan'),
];

class OptionalFieldsPage extends StatefulWidget {
  const OptionalFieldsPage({super.key});

  @override
  State<OptionalFieldsPage> createState() => _OptionalFieldsPageState();
}

class _OptionalFieldsPageState extends State<OptionalFieldsPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();
    _form = V.map({
      // Required
      'name': V.string().min(3),
      // Optional strings
      'nickname': V.string().min(2).nullable(),
      'website': V.string().url().nullable(),
      // Optional number
      'age': V.int().min(0).max(150).nullable(),
      'score': V.double().min(0).max(10).nullable(),
      // Optional bool
      'newsletter': V.bool().nullable(),
      // Optional date
      'birthdate': V.date().nullable(),
      // Optional enum
      'favoriteColor': V.enm<Color>(Color.values).nullable(),
      // Optional custom class
      'address': V.object<Address>().nullable(),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _nickname => _form.field('nickname');
  VField<String> get _website => _form.field('website');
  VField<int> get _age => _form.field('age');
  VField<double> get _score => _form.field('score');
  VField<bool> get _newsletter => _form.field('newsletter');
  VField<DateTime> get _birthdate => _form.field('birthdate');
  VField<Color> get _favoriteColor => _form.field('favoriteColor');
  VField<Address> get _address => _form.field('address');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate.value ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) _birthdate.set(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Optional Fields')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'All fields except "Name" use .nullable() and are optional. '
                'They accept empty/null values without error. This example '
                'covers every type: String, int, double, bool, DateTime, '
                'enum, and a custom class. Try filling some and leaving '
                'others empty.',
              ),
              const SizedBox(height: 24),
              _sectionTitle('Required'),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'At least 3 characters',
                ),
                onChanged: _name.onChanged,
                validator: _name.validator,
              ),
              const SizedBox(height: 24),
              _sectionTitle('Optional Strings'),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  hintText: 'At least 2 chars if provided',
                ),
                onChanged: _nickname.onChanged,
                validator: _nickname.validator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'Valid URL if provided',
                ),
                keyboardType: TextInputType.url,
                onChanged: _website.onChanged,
                validator: _website.validator,
              ),
              const SizedBox(height: 24),
              _sectionTitle('Optional Numbers'),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: '0-150 if provided',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) {
                    _age.set(null);
                  } else {
                    final parsed = int.tryParse(value);
                    if (parsed != null) _age.set(parsed);
                  }
                },
                validator: (_) => _age.validator(_age.value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Score',
                  hintText: '0.0-10.0 if provided',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  if (value.isEmpty) {
                    _score.set(null);
                  } else {
                    final parsed = double.tryParse(value);
                    if (parsed != null) _score.set(parsed);
                  }
                },
                validator: (_) => _score.validator(_score.value),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Optional Bool'),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _newsletter.listenable,
                builder: (context, _) {
                  return CheckboxListTile(
                    title: const Text('Subscribe to newsletter'),
                    subtitle: Text(
                      _newsletter.value == null
                          ? 'Not selected (null)'
                          : _newsletter.value!
                              ? 'Yes'
                              : 'No',
                    ),
                    value: _newsletter.value,
                    tristate: true,
                    onChanged: (val) => _newsletter.set(val),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle('Optional DateTime'),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _birthdate.listenable,
                builder: (context, _) {
                  final date = _birthdate.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Birthdate'),
                    subtitle: Text(
                      date != null
                          ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                          : 'Not selected (null)',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (date != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _birthdate.set(null),
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle('Optional Enum'),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _favoriteColor.listenable,
                builder: (context, _) {
                  return DropdownButtonFormField<Color?>(
                    decoration:
                        const InputDecoration(labelText: 'Favorite Color'),
                    initialValue: _favoriteColor.value,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...Color.values.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                              c.name[0].toUpperCase() + c.name.substring(1)),
                        ),
                      ),
                    ],
                    onChanged: (val) => _favoriteColor.set(val),
                    validator: (_) =>
                        _favoriteColor.validator(_favoriteColor.value),
                  );
                },
              ),
              const SizedBox(height: 24),
              _sectionTitle('Optional Custom Class'),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _address.listenable,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('None'),
                            selected: _address.value == null,
                            onSelected: (_) => _address.set(null),
                          ),
                          ..._addresses.map(
                            (a) => ChoiceChip(
                              label: Text(a.toString()),
                              selected: _address.value == a,
                              onSelected: (selected) =>
                                  _address.set(selected ? a : null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selected: ${_address.value?.toString() ?? "null"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildValuePreview(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_form.validate()) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Form Submitted'),
                        content: Text(_formatValues()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildValuePreview() {
    return ListenableBuilder(
      listenable: _form.listenable,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current values:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatValues(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatValues() {
    final date = _birthdate.value;
    final dateStr = date != null
        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : 'null';

    return 'name: ${_name.value ?? "null"}\n'
        'nickname: ${_nickname.value ?? "null"}\n'
        'website: ${_website.value ?? "null"}\n'
        'age: ${_age.value ?? "null"}\n'
        'score: ${_score.value ?? "null"}\n'
        'newsletter: ${_newsletter.value ?? "null"}\n'
        'birthdate: $dateStr\n'
        'favoriteColor: ${_favoriteColor.value?.name ?? "null"}\n'
        'address: ${_address.value?.toString() ?? "null"}';
  }
}
