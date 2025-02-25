import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';

final v = Validart();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      theme: ThemeData(
        useMaterial3: false,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        appBarTheme: AppBarTheme(elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            elevation: WidgetStatePropertyAll(0),
            fixedSize: WidgetStatePropertyAll(Size(double.maxFinite, 56)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final VForm _form;

  @override
  void initState() {
    super.initState();

    _form = v.map({
      'email': v.string().email(),
      'password': v.string().password(),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _email => _form.field('email');
  VField<String> get _password => _form.field('password');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form.key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ExampleWidget(
                'In this example, we use .form() on v.map, defining two fields: email and password, both of type String. To simplify form field handling, we created a reusable TextFormFieldWidget, which only requires the corresponding VField<String>. At the end, we call .dispose() on the form to ensure proper resource cleanup.',
              ),
              const SizedBox(height: 16),
              TextFormFieldWidget(hint: 'Email', field: _email),
              const SizedBox(height: 8),
              TextFormFieldWidget(hint: 'Password', field: _password),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Don\'t have an account? ',
                  children: [
                    TextSpan(
                      text: 'Create one',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.indigo,
                        decorationColor: Colors.indigo,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SignUpPage(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_form.validate()) {
                    printJson(_form.value);
                  }
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final VForm _form;

  @override
  void initState() {
    super.initState();

    _form = v.form(
      v.map({
        'name': v.string().email(),
        'email': v.string().email(),
        'password': v.string().password(),
        'confirmPassword': v.string().password(),
      }).refine(
        (data) => data['password'] == data['confirmPassword'],
        path: 'confirmPassword',
      ),
    );
  }

  @override
  void dispose() {
    _form.dispose();

    super.dispose();
  }

  VField<String> get _name => _form.field('name');
  VField<String> get _email => _form.field('email');
  VField<String> get _password => _form.field('password');
  VField<String> get _confirmPassword => _form.field('confirmPassword');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _form.key,
          child: Column(
            children: [
              ExampleWidget(
                'In this example, we use .form() on v.map to create a VForm with four fields: name, email, password, and confirmPassword, all of type String. This form ensures that users provide valid credentials before signing up.\n\n'
                'Additionally, we use .refine() to validate that the password and confirmPassword fields match. If they do not, a custom error message is assigned to the confirmPassword field, guiding users to enter the correct confirmation password.\n\n'
                'To simplify the form field handling, we reuse the TextFormFieldWidget, which only requires the corresponding VField<String>. At the end, we call .dispose() on the form to ensure proper resource cleanup.',
              ),
              const SizedBox(height: 16),
              TextFormFieldWidget(hint: 'Name', field: _name),
              const SizedBox(height: 8),
              TextFormFieldWidget(hint: 'Email', field: _email),
              const SizedBox(height: 8),
              TextFormFieldWidget(hint: 'Password', field: _password),
              const SizedBox(height: 8),
              TextFormFieldWidget(
                hint: 'Confirm password',
                field: _confirmPassword,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_form.validate()) {
                    printJson(_form.value);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextFormFieldWidget extends StatelessWidget {
  final VField<String> field;
  final String hint;

  const TextFormFieldWidget({
    super.key,
    required this.field,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(hintText: hint),
      validator: field.validator,
      onChanged: field.onChanged,
    );
  }
}

class ExampleWidget extends StatelessWidget {
  final String text;

  const ExampleWidget(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Text(
        text,
        style: TextStyle(
          letterSpacing: 1.5,
          color: Colors.grey[800],
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
