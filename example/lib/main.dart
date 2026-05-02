import 'package:flutter/material.dart';
import 'pages/array_field_page.dart';
import 'pages/async_validation_page.dart';
import 'pages/basic_map_form_page.dart';
import 'pages/complex_form_page.dart';
import 'pages/conditional_validation_page.dart';
import 'pages/object_form_page.dart';
import 'pages/object_validation_page.dart';
import 'pages/password_match_page.dart';
import 'pages/root_errors_page.dart';
import 'pages/controller_sync_page.dart';
import 'pages/reactive_form_page.dart';
import 'pages/required_message_page.dart';
import 'pages/checkbox_form_page.dart';
import 'pages/dropdown_enum_page.dart';
import 'pages/custom_class_field_page.dart';
import 'pages/default_value_page.dart';
import 'pages/locale_page.dart';
import 'pages/multi_type_form_page.dart';
import 'pages/errors_preview_page.dart';
import 'pages/manual_error_page.dart';
import 'pages/optional_fields_page.dart';
import 'pages/preprocess_page.dart';
import 'pages/refine_field_raw_page.dart';
import 'pages/transforms_page.dart';
import 'pages/v_errors_page.dart';
import 'pages/when_matches_page.dart';

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
    const examples = <_Example>[
      _Example(
        title: 'Basic Map Form',
        subtitle: 'Simple login form using VMap and .form()',
        page: BasicMapFormPage(),
      ),
      _Example(
        title: 'Object Form',
        subtitle: 'Typed form with VObject returning a User instance',
        page: ObjectFormPage(),
      ),
      _Example(
        title: 'Object Validation',
        subtitle:
            'VObject equalFields, when, refineField — typed cross-field rules',
        page: ObjectValidationPage(),
      ),
      _Example(
        title: 'Password Match',
        subtitle: 'Cross-field validation with refineField',
        page: PasswordMatchPage(),
      ),
      _Example(
        title: 'refineField vs refineFieldRaw',
        subtitle: 'Same rule, different verdicts when a field has a transform',
        page: RefineFieldRawPage(),
      ),
      _Example(
        title: 'Root Errors',
        subtitle: 'form.rootErrors banner via refine + dependsOn aggregation',
        page: RootErrorsPage(),
      ),
      _Example(
        title: 'Controller Sync',
        subtitle: 'TextEditingController integration with attachController',
        page: ControllerSyncPage(),
      ),
      _Example(
        title: 'Reactive Form',
        subtitle: 'Live preview updated via value change listeners',
        page: ReactiveFormPage(),
      ),
      _Example(
        title: 'Checkbox Form',
        subtitle: 'Boolean validation with checkbox fields',
        page: CheckboxFormPage(),
      ),
      _Example(
        title: 'Required Message',
        subtitle:
            'Two ways to customize the required error on an untouched checkbox',
        page: RequiredMessagePage(),
      ),
      _Example(
        title: 'Dropdown Enum',
        subtitle: 'Enum fields with dropdown selection',
        page: DropdownEnumPage(),
      ),
      _Example(
        title: 'Custom Class Field',
        subtitle: 'Custom type fields beyond primitives',
        page: CustomClassFieldPage(),
      ),
      _Example(
        title: 'Optional Fields',
        subtitle: 'Nullable fields that stay valid when cleared',
        page: OptionalFieldsPage(),
      ),
      _Example(
        title: 'Default Value',
        subtitle:
            'defaultValue vs initialValues — resolution order, reset, required semantics',
        page: DefaultValuePage(),
      ),
      _Example(
        title: 'Conditional Validation',
        subtitle: 'Show/hide fields based on another field value with .when()',
        page: ConditionalValidationPage(),
      ),
      _Example(
        title: 'whenMatches',
        subtitle:
            'Predicate-based conditional rules — combine fields, use >/>=/oneOf',
        page: WhenMatchesPage(),
      ),
      _Example(
        title: 'Multi Language',
        subtitle: 'Switch locale to change error messages',
        page: LocalePage(),
      ),
      _Example(
        title: 'Array Field',
        subtitle: 'List of tags with VArray validation',
        page: ArrayFieldPage(),
      ),
      _Example(
        title: 'Async Validation',
        subtitle: 'refineAsync + form.validateAsync() — remote username check',
        page: AsyncValidationPage(),
      ),
      _Example(
        title: 'Complex Form',
        subtitle:
            'All types + array + nested map + enum + union + when sync/async + refineField',
        page: ComplexFormPage(),
      ),
      _Example(
        title: 'Multi Type Form',
        subtitle: 'All field types combined in a single form',
        page: MultiTypeFormPage(),
      ),
      _Example(
        title: 'Manual Error',
        subtitle:
            'Imperative setError/clearError for backend and business rule errors',
        page: ManualErrorPage(),
      ),
      _Example(
        title: 'Transforms',
        subtitle: 'Pipeline transforms (trim, toLowerCase) — rawValue vs value',
        page: TransformsPage(),
      ),
      _Example(
        title: 'Preprocess',
        subtitle:
            'Container vs field preprocess — cross-field rewrites for VMap and VObject',
        page: PreprocessPage(),
      ),
      _Example(
        title: 'Errors Preview',
        subtitle: 'form.errors() and field.error for live previews',
        page: ErrorsPreviewPage(),
      ),
      _Example(
        title: 'vErrors',
        subtitle:
            'Structured errors with code + path — great for arrays and i18n',
        page: VErrorsPage(),
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
