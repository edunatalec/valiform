import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

class User {
  final String name;
  final String email;
  final int age;

  const User({required this.name, required this.email, required this.age});

  @override
  String toString() => 'User(name: $name, email: $email, age: $age)';

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'age': age};
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

  Map<String, dynamic>? _formResult;
  Map<String, String>? _formErrors;

  Map<String, dynamic>? _defaultFormResult;
  Map<String, String>? _defaultFormErrors;

  @override
  void initState() {
    super.initState();

    _form = _userSchema().form(builder: _buildUser);

    _defaultForm = _userSchema().form(
      builder: _buildUser,
      initialValue: const User(
        name: 'John',
        email: 'john@example.com',
        age: 25,
      ),
    );
  }

  @override
  void dispose() {
    _form.dispose();
    _defaultForm.dispose();

    super.dispose();
  }

  void _submitForm() {
    setState(() {
      if (_form.validate()) {
        _formResult = _form.value.toJson();
        _formErrors = null;
      } else {
        _formResult = null;
        _formErrors = _form.errors();
      }
    });
  }

  void _submitDefaultForm() {
    setState(() {
      if (_defaultForm.validate()) {
        _defaultFormResult = _defaultForm.value.toJson();
        _defaultFormErrors = null;
      } else {
        _defaultFormResult = null;
        _defaultFormErrors = _defaultForm.errors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _form.field<String>('name');
    final email = _form.field<String>('email');
    final age = _form.field<int>('age');

    final defName = _defaultForm.field<String>('name');
    final defEmail = _defaultForm.field<String>('email');
    final defAge = _defaultForm.field<int>('age');

    return Scaffold(
      appBar: AppBar(title: const Text('Object Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _form.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Without Default Value'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'VObject<User> creates a typed form. Instead of returning '
                    'a Map, form.value returns a User instance built by the '
                    'builder function. Each field is defined with a getter '
                    'for extracting the value from the User class.',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: name,
                    label: 'Name',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => age.onChanged(int.tryParse(value)),
                    validator: (_) => age.validator(age.value),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Submit'),
                  ),
                  ResultFeedback(data: _formResult, errors: _formErrors),
                ],
              ),
            ),
            const Divider(height: 48),
            Form(
              key: _defaultForm.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('With Default Value'),
                  const SizedBox(height: 8),
                  const InfoCard(
                    'Pass a typed initialValue to .form(). The User instance '
                    'is decomposed into field values using VObject\'s extract '
                    'method. Calling form.reset() restores the original User '
                    'values.',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: defName,
                    label: 'Name',
                  ),
                  const SizedBox(height: 16),
                  VTextField(
                    field: defEmail,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    initialValue: defAge.value?.toString(),
                    onChanged: (value) => defAge.onChanged(int.tryParse(value)),
                    validator: (_) => defAge.validator(defAge.value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () {
                            _defaultForm.reset();
                            setState(() {
                              _defaultFormResult = null;
                              _defaultFormErrors = null;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitDefaultForm,
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                  ResultFeedback(
                    data: _defaultFormResult,
                    errors: _defaultFormErrors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
