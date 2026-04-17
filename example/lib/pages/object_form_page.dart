import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

class User {
  final String name;
  final String email;
  final int age;

  const User({
    required this.name,
    required this.email,
    required this.age,
  });

  @override
  String toString() => 'User(name: $name, email: $email, age: $age)';

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'age': age,
      };
}

VObject<User> _userSchema() => V.object<User>(
      configure: (o) => o
          .field('name', (u) => u.name, V.string().min(3))
          .field('email', (u) => u.email, V.string().email())
          .field('age', (u) => u.age, V.int().min(18)),
    );

User _buildUser(Map<String, dynamic> data) => User(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      age: data['age'] ?? 0,
    );

class ObjectFormPage extends StatefulWidget {
  const ObjectFormPage({super.key});

  @override
  State<ObjectFormPage> createState() => _ObjectFormPageState();
}

class _ObjectFormPageState extends State<ObjectFormPage> {
  late final VForm<User> _form;
  late final VForm<User> _defaultForm;

  @override
  void initState() {
    super.initState();

    _form = _userSchema().form(builder: _buildUser);

    _defaultForm = _userSchema().form(
      builder: _buildUser,
      initialValue:
          const User(name: 'John', email: 'john@example.com', age: 25),
    );
  }

  @override
  void dispose() {
    _form.dispose();
    _defaultForm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBasicSection(),
            const Divider(height: 48),
            _buildDefaultValueSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    final name = _form.field<String>('name');
    final email = _form.field<String>('email');
    final age = _form.field<int>('age');

    return Form(
      key: _form.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Without Default Value',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const InfoCard(
            'VObject<User> creates a typed form. Instead of returning a Map, '
            'form.value returns a User instance built by the builder function. '
            'Each field is defined with a getter for extracting the value from '
            'the User class.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: name.onChanged,
            validator: name.validator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            onChanged: email.onChanged,
            validator: email.validator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) age.set(parsed);
            },
            validator: (_) => age.validator(age.value),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_form.validate()) {
                final user = _form.value;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Type: ${user.runtimeType} — $user'),
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

  Widget _buildDefaultValueSection() {
    final name = _defaultForm.field<String>('name');
    final email = _defaultForm.field<String>('email');
    final age = _defaultForm.field<int>('age');

    return Form(
      key: _defaultForm.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'With Default Value',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const InfoCard(
            'Pass a typed initialValue to .form(). The User instance is '
            'decomposed into field values using VObject\'s extract method. '
            'Calling form.reset() restores the original User values.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Name'),
            initialValue: name.value,
            onChanged: name.onChanged,
            validator: name.validator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            initialValue: email.value,
            onChanged: email.onChanged,
            validator: email.validator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
            initialValue: age.value?.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) age.set(parsed);
            },
            validator: (_) => age.validator(age.value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _defaultForm.reset(),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_defaultForm.validate()) {
                      final user = _defaultForm.value;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Type: ${user.runtimeType} — $user'),
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
