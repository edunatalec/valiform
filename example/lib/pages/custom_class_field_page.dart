import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

import '../main.dart';

class Category {
  final int id;
  final String name;

  const Category(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => name;
}

const categories = [
  Category(1, 'Technology'),
  Category(2, 'Science'),
  Category(3, 'Design'),
  Category(4, 'Business'),
  Category(5, 'Health'),
];

class CustomClassFieldPage extends StatefulWidget {
  const CustomClassFieldPage({super.key});

  @override
  State<CustomClassFieldPage> createState() => _CustomClassFieldPageState();
}

class _CustomClassFieldPageState extends State<CustomClassFieldPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();
    _form = V.map({
      'title': V.string().min(3),
      'description': V.string().min(10),
      'category': V.object<Category>(),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  VField<String> get _title => _form.field('title');
  VField<String> get _description => _form.field('description');
  VField<Category> get _category => _form.field('category');

  void _submit() {
    if (_form.validate()) {
      final cat = _category.value!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Form Submitted'),
          content: Text(
            'Title: ${_title.value}\n'
            'Description: ${_description.value}\n'
            'Category: ${cat.name} (id: ${cat.id})',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Class Field')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                'This example uses V.object<Category>() inside a VMap schema. '
                'The field is correctly typed as VField<Category> thanks to '
                'mapType. A custom ChipFormField<T> wraps ChoiceChips into a '
                'FormField, integrating with Flutter\'s form validation system.',
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
              const SizedBox(height: 24),
              ChipFormField<Category>(
                label: 'Category',
                items: categories,
                labelBuilder: (c) => c.name,
                field: _category,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChipFormField<T> extends FormField<T> {
  ChipFormField({
    super.key,
    required String label,
    required List<T> items,
    required String Function(T) labelBuilder,
    required VField<T> field,
  }) : super(
          initialValue: field.value,
          validator: (_) => field.validator(field.value),
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: field.listenable,
                  builder: (context, _) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items.map((item) {
                        return ChoiceChip(
                          label: Text(labelBuilder(item)),
                          selected: field.value == item,
                          onSelected: (selected) {
                            field.set(selected ? item : null);
                            state.didChange(selected ? item : null);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(state.context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}
