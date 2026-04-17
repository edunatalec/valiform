import 'dart:convert';

import 'package:flutter/material.dart';
import 'pages/array_field_page.dart';
import 'pages/basic_map_form_page.dart';
import 'pages/conditional_validation_page.dart';
import 'pages/object_form_page.dart';
import 'pages/password_match_page.dart';
import 'pages/controller_sync_page.dart';
import 'pages/reactive_form_page.dart';
import 'pages/checkbox_form_page.dart';
import 'pages/dropdown_enum_page.dart';
import 'pages/custom_class_field_page.dart';
import 'pages/locale_page.dart';
import 'pages/multi_type_form_page.dart';
import 'pages/manual_error_page.dart';
import 'pages/optional_fields_page.dart';

void main() {
  runApp(const ValiformExampleApp());
}

class ValiformExampleApp extends StatelessWidget {
  const ValiformExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valiform Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            elevation: const WidgetStatePropertyAll(0),
            fixedSize: const WidgetStatePropertyAll(Size(double.maxFinite, 56)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final examples = <_Example>[
      _Example(
        title: 'Basic Map Form',
        subtitle: 'Simple login form using VMap and .form()',
        page: const BasicMapFormPage(),
      ),
      _Example(
        title: 'Object Form',
        subtitle: 'Typed form with VObject returning a User instance',
        page: const ObjectFormPage(),
      ),
      _Example(
        title: 'Password Match',
        subtitle: 'Cross-field validation with refineFormField',
        page: const PasswordMatchPage(),
      ),
      _Example(
        title: 'Controller Sync',
        subtitle: 'TextEditingController integration with attachTextController',
        page: const ControllerSyncPage(),
      ),
      _Example(
        title: 'Reactive Form',
        subtitle: 'Live preview updated via value change listeners',
        page: const ReactiveFormPage(),
      ),
      _Example(
        title: 'Checkbox Form',
        subtitle: 'Boolean validation with checkbox fields',
        page: const CheckboxFormPage(),
      ),
      _Example(
        title: 'Dropdown Enum',
        subtitle: 'Enum fields with dropdown selection',
        page: const DropdownEnumPage(),
      ),
      _Example(
        title: 'Custom Class Field',
        subtitle: 'Custom type fields beyond primitives',
        page: const CustomClassFieldPage(),
      ),
      _Example(
        title: 'Optional Fields',
        subtitle: 'Nullable fields that stay valid when cleared',
        page: const OptionalFieldsPage(),
      ),
      _Example(
        title: 'Conditional Validation',
        subtitle: 'Show/hide fields based on another field value with .when()',
        page: const ConditionalValidationPage(),
      ),
      _Example(
        title: 'Multi Language',
        subtitle: 'Switch locale to change error messages',
        page: const LocalePage(),
      ),
      _Example(
        title: 'Array Field',
        subtitle: 'List of tags with VArray validation',
        page: const ArrayFieldPage(),
      ),
      _Example(
        title: 'Multi Type Form',
        subtitle: 'All field types combined in a single form',
        page: const MultiTypeFormPage(),
      ),
      _Example(
        title: 'Manual Error',
        subtitle:
            'Imperative setError/clearError for backend and business rule errors',
        page: const ManualErrorPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Valiform Examples'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: examples.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final example = examples[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(example.title),
            subtitle: Text(example.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => example.page),
              );
            },
          );
        },
      ),
    );
  }
}

class _Example {
  final String title;
  final String subtitle;
  final Widget page;

  const _Example({
    required this.title,
    required this.subtitle,
    required this.page,
  });
}

class InfoCard extends StatelessWidget {
  final String text;

  const InfoCard(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

void printJson(Object? value) {
  if (value == null) return;
  debugPrint(_encoder.convert(value));
}
