import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../widgets/widgets.dart';

enum Country { brazil, usa, japan, germany, australia }

class DropdownEnumPage extends StatefulWidget {
  const DropdownEnumPage({super.key});

  @override
  State<DropdownEnumPage> createState() => _DropdownEnumPageState();
}

class _DropdownEnumPageState extends State<DropdownEnumPage> {
  late final VForm<Map<String, dynamic>> _form;

  Map<String, dynamic>? _result;
  Map<String, String>? _errors;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      'name': V.string().min(3),
      'email': V.string().email(),
      'country': V.enm<Country>(Country.values),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _email => _form.field('email');
  VField<Country> get _country => _form.field('country');

  void _submit() {
    setState(() {
      if (_form.validate()) {
        _result = _form.value;
        _errors = null;
      } else {
        _result = null;
        _errors = _form.errors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dropdown Enum Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'V.enm<Country>(Country.values) creates an enum-validated field. '
                'The field is correctly typed as VField<Country>. Use '
                'DropdownButtonFormField for the selection UI and '
                'ListenableBuilder to rebuild when the value changes.',
              ),
              const SizedBox(height: 24),
              VTextField(
                field: _name,
                label: 'Name',
              ),
              const SizedBox(height: 16),
              VTextField(
                field: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _country.listenable,
                builder: (context, _) {
                  return DropdownButtonFormField<Country>(
                    decoration: const InputDecoration(labelText: 'Country'),
                    initialValue: _country.value,
                    items: Country.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.name[0].toUpperCase() + c.name.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => _country.set(val),
                    validator: (_) => _country.validator(_country.value),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                ResultBox.success(data: _result!),
              ] else if (_errors != null) ...[
                const SizedBox(height: 16),
                ResultBox.failure(errors: _errors!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
