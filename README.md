[![pub package](https://img.shields.io/pub/v/valiform.svg)](https://pub.dev/packages/valiform)
[![package publisher](https://img.shields.io/pub/publisher/valiform.svg)](https://pub.dev/packages/valiform/publisher)

# Valiform

**Valiform** is a package for managing and validating forms in Flutter, built on top of **validart**. It provides a simple interface for handling form states, validation, and integration with `FormState`.

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
import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';

final v = Validart();

void main() {
  final form = v.map({
    'name': VString(minLength: 3),
    'age': VInt(min: 18),
  }).form();
}
```

### Using the Form's Listenable for Reactivity

You can use the `listenable` property of the form or individual fields to reactively update the UI:

```dart
class ExampleWidget extends StatelessWidget {
  final VForm form;

  const ExampleWidget({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return ObserverWidget(
      listenable: form.listenable,
      builder: (context) {
        return Text("Current Form Value: ${form.value}");
      },
    );
  }
}

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
      builder: (context, __) => builder(context),
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
