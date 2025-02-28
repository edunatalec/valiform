[![pub package](https://img.shields.io/pub/v/valiform.svg)](https://pub.dev/packages/valiform)
[![package publisher](https://img.shields.io/pub/publisher/valiform.svg)](https://pub.dev/packages/valiform/publisher)

# Valiform

**Valiform** is a package for managing and validating forms in Flutter, built on top of **validart**. It provides a simple interface for handling form states, validation, and integration with `FormState`.

For more details and a complete example, visit the [official example](https://pub.dev/packages/valiform/example) on pub.dev.

## Installation

Add **valiform** to your project:

```sh
flutter pub add valiform
```

This will add a line like this to your project's `pubspec.yaml`:

```yaml
dependencies:
  valiform: <version>
```

## Basic Usage

```dart
// Use a global instance
final v = Validart();

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
              TextFormField(
                decoration: InputDecoration(hintText: 'Email'),
                validator: _email.validator,
                onChanged: _email.onChanged,
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(hintText: 'Password'),
                validator: _password.validator,
                onChanged: _password.onChanged,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_form.validate()) {
                    // Code
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Using the Form's Listenable for Reactivity

You can use the `listenable` property of the form or individual fields to reactively update the UI:

```dart
Form(
  key: _form.key,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      TextFormField(
        decoration: InputDecoration(hintText: 'Email'),
        validator: _email.validator,
        onChanged: _email.onChanged,
      ),
      const SizedBox(height: 4),
      ObserverWidget(
        listenable: _email.listenable,
        builder: (_) => Text(_email.value ?? ''),
      ),
      const SizedBox(height: 8),
      TextFormField(
        decoration: InputDecoration(hintText: 'Password'),
        validator: _password.validator,
        onChanged: _password.onChanged,
      ),
      const SizedBox(height: 4),
      ObserverWidget(
        listenable: _email.listenable,
        builder: (_) => Text(_password.value ?? ''),
      ),
      // or
      // ObserverWidget(
      //  listenable: _form.listenable,
      //  builder: (_) => Text(_password.value),
      //),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () {
          if (_form.validate()) {
            // Code
          }
        },
        child: const Text('Continue'),
      ),
    ],
  ),
)

class ObserverWidget extends StatelessWidget {
  final Listenable listenable;
  final WidgetBuilder builder;

  const ObserverWidget({
    super.key,
    required this.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) => builder(context),
    );
  }
}
```

### Using Default Values

You can provide default values to the form and access them in `initialValue` for `TextFormField` or by using a controller:

```dart
final form = v.map({
  'email': v.string().email()
}).form(defaultValues: {'email': 'example@email.com'});
```

Using `initialValue` in a `TextFormField`:

```dart
TextFormField(
  initialValue: form.field('email').value,
)
```

Or using the field's controller:

```dart
TextFormField(
  controller: form.field('email').controller,
)
```
