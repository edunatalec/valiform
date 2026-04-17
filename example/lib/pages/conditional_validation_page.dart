import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

class ConditionalValidationPage extends StatefulWidget {
  const ConditionalValidationPage({super.key});

  @override
  State<ConditionalValidationPage> createState() =>
      _ConditionalValidationPageState();
}

class _ConditionalValidationPageState extends State<ConditionalValidationPage> {
  late final VForm<Map<String, dynamic>> _formA;
  late final VForm<Map<String, dynamic>> _formB;

  @override
  void initState() {
    super.initState();

    // Example A: Different fields based on condition
    _formA = V.map({
      'type': V.string(),
      'name': V.string().min(3),
      'cnpj': V.string().nullable(),
      'cpf': V.string().nullable(),
    }).when('type', equals: 'company', then: {
      'cnpj': V.string().min(14),
    }).when('type', equals: 'person', then: {
      'cpf': V.string().min(11),
    }).form(initialValues: {'type': 'person'});

    // Example B: Same field, different validation
    _formB = V.map({
      'contactType': V.string(),
      'contact': V.string(),
    }).when('contactType', equals: 'email', then: {
      'contact': V.string().email(),
    }).when('contactType', equals: 'url', then: {
      'contact': V.string().url(),
    }).when('contactType', equals: 'phone', then: {
      'contact': V.string().phone(),
    }).form(initialValues: {'contactType': 'email'});
  }

  @override
  void dispose() {
    _formA.dispose();
    _formB.dispose();
    super.dispose();
  }

  // Form A fields
  VField<String> get _type => _formA.field('type');
  VField<String> get _name => _formA.field('name');
  VField<String> get _cnpj => _formA.field('cnpj');
  VField<String> get _cpf => _formA.field('cpf');

  // Form B fields
  VField<String> get _contactType => _formB.field('contactType');
  VField<String> get _contact => _formB.field('contact');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditional Validation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDifferentFieldsSection(),
            const Divider(height: 48),
            _buildSameFieldSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDifferentFieldsSection() {
    return Form(
      key: _formA.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Different Fields',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const InfoCard(
            'The .when() method shows/hides fields based on a condition. '
            'When type is "company", CNPJ is required (14 chars). '
            'When type is "person", CPF is required (11 chars). '
            'The inactive field stays nullable.',
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _type.listenable,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Type'),
                    initialValue: _type.value,
                    items: const [
                      DropdownMenuItem(
                        value: 'person',
                        child: Text('Person'),
                      ),
                      DropdownMenuItem(
                        value: 'company',
                        child: Text('Company'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) _type.set(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: _name.onChanged,
                    validator: _name.validator,
                  ),
                  const SizedBox(height: 16),
                  if (_type.value == 'person')
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        hintText: 'Required for person (11 chars)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _cpf.onChanged,
                      validator: _cpf.validator,
                    ),
                  if (_type.value == 'company')
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        hintText: 'Required for company (14 chars)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _cnpj.onChanged,
                      validator: _cnpj.validator,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formA.validate()) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Form Submitted'),
                    content: Text(
                      'Type: ${_type.value}\n'
                      'Name: ${_name.value}\n'
                      'CPF: ${_cpf.value ?? "(not required)"}\n'
                      'CNPJ: ${_cnpj.value ?? "(not required)"}',
                    ),
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
    );
  }

  Widget _buildSameFieldSection() {
    return Form(
      key: _formB.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Same Field, Different Rules',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const InfoCard(
            'The same "contact" field changes its validation based on the '
            'selected contact type. When "email" is selected, it validates '
            'as an email. When "url", as a URL. When "phone", as a phone '
            'number. The field itself stays visible — only its rules change.',
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _contactType.listenable,
            builder: (context, _) {
              final type = _contactType.value ?? 'email';
              final hints = {
                'email': 'Enter a valid email',
                'url': 'Enter a valid URL (https://...)',
                'phone': 'Enter a valid phone number',
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Contact Type'),
                    initialValue: _contactType.value,
                    items: const [
                      DropdownMenuItem(
                        value: 'email',
                        child: Text('Email'),
                      ),
                      DropdownMenuItem(value: 'url', child: Text('URL')),
                      DropdownMenuItem(
                        value: 'phone',
                        child: Text('Phone'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) _contactType.set(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Contact',
                      hintText: hints[type],
                    ),
                    onChanged: _contact.onChanged,
                    validator: _contact.validator,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formB.validate()) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Form Submitted'),
                    content: Text(
                      'Contact Type: ${_contactType.value}\n'
                      'Contact: ${_contact.value}',
                    ),
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
    );
  }
}
