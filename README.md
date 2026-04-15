[![pub package](https://img.shields.io/pub/v/valiform.svg)](https://pub.dev/packages/valiform)
[![package publisher](https://img.shields.io/pub/publisher/valiform.svg)](https://pub.dev/packages/valiform/publisher)

# Valiform

**Valiform** is a Flutter form validation library built on top of [Validart](https://pub.dev/packages/validart). It provides reactive form state management, typed field validation, and seamless integration with Flutter's `Form` widget.

## Installation

```sh
flutter pub add valiform validart
```

> **Note:** Import both packages — valiform handles forms, validart handles schemas.

## Quick Start

```dart
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();
    _form = V.map({
      'email': V.string().email(),
      'password': V.string().password(),
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
    return Form(
      key: _form.key,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Email'),
            validator: _email.validator,
            onChanged: _email.onChanged,
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: _password.validator,
            onChanged: _password.onChanged,
          ),
          ElevatedButton(
            onPressed: () {
              if (_form.validate()) {
                print(_form.value); // {email: '...', password: '...'}
              }
            },
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
```

## Typed Forms with VObject

Return a typed object instead of a `Map`:

```dart
class User {
  final String name;
  final String email;
  const User({required this.name, required this.email});
}

final form = V.object<User>(
  configure: (o) => o
    .field('name', (u) => u.name, V.string().min(3))
    .field('email', (u) => u.email, V.string().email()),
).form(
  builder: (data) => User(name: data['name'], email: data['email']),
  defaultValue: User(name: 'John', email: 'john@example.com'),
);

final user = form.value; // User instance
```

## Controller Sync

Attach a `TextEditingController` for bidirectional synchronization:

```dart
final controller = TextEditingController();
final email = form.field<String>('email');

email.attachTextController(controller);
// Now: controller.text ↔ email.value stay in sync
// set(), clear(), reset() update the text field
// Typing updates the VField value

// For non-text fields, use ValueNotifier:
final notifier = ValueNotifier<int?>(null);
form.field<int>('age').attachController(notifier);
```

> The caller is responsible for disposing the controller.

## Cross-Field Validation

### refineFormField

Shows errors directly on the target field:

```dart
final form = V.map({
  'password': V.string().password(),
  'confirmPassword': V.string().password(),
}).refineFormField(
  (data) => data['password'] == data['confirmPassword'],
  path: 'confirmPassword',
  message: 'Passwords must match',
).form();
```

### equalFields

Validates at the VMap pipeline level (use with `silentValidate`):

```dart
final form = V.map({
  'password': V.string().password(),
  'confirmPassword': V.string().password(),
}).equalFields('password', 'confirmPassword').form();

if (!form.silentValidate()) {
  // Handle error
}
```

## Reactive Features

### onValueChanged

```dart
// Via form()
final form = V.map({...}).form(
  onValueChanged: (value) => print(value),
);

// Or add/remove later
form.addValueChangedListener((value) => print(value));
form.removeValueChangedListener(listener);
```

### ListenableBuilder

```dart
ListenableBuilder(
  listenable: _email.listenable,
  builder: (context, _) {
    return Text('${_email.value?.length ?? 0} characters');
  },
)
```

## Transforms

Pipeline transforms (trim, toLowerCase, etc.) are applied to `form.value` and `parsedValue`:

```dart
final form = V.map({
  'name': V.string().trim().min(3),
}).form();

form.field<String>('name').set('  hello  ');

form.rawValue['name'];   // '  hello  ' (raw)
form.value['name'];      // 'hello' (transformed)
```

## Custom Types

Enums and custom classes are fully typed:

```dart
final form = V.map({
  'name': V.string().min(3),
  'country': V.enm<Country>(Country.values),
  'category': V.object<Category>(),
}).form();

final country = form.field<Country>('country');   // VField<Country>
final category = form.field<Category>('category'); // VField<Category>
```

## Default Values

```dart
// VMap form
final form = V.map({
  'email': V.string().email(),
}).form(defaultValues: {'email': 'user@example.com'});

// VObject form — pass a typed instance
final form = V.object<User>(...).form(
  builder: (data) => User(...),
  defaultValue: User(name: 'John', email: 'john@example.com'),
);
```

## API Reference

### VField\<T\>

| Member | Description |
|--------|-------------|
| `value` | Current raw value |
| `parsedValue` | Value after pipeline transforms |
| `set(T?)` | Update value programmatically |
| `onChanged(T)` | Handle widget change events |
| `onSaved(T?)` | Handle form save callbacks |
| `validator(T?)` | Returns error message or null |
| `validate()` | Returns true if current value is valid |
| `clear()` | Set value to null |
| `reset()` | Restore initial value |
| `listenable` | Listenable for reactive UI |
| `attachController(ValueNotifier<T?>)` | Bidirectional sync |
| `attachTextController(TextEditingController)` | Text field sync |
| `detachController()` | Remove sync listeners |
| `dispose()` | Clean up resources |

### VForm\<T\>

| Member | Description |
|--------|-------------|
| `key` | GlobalKey\<FormState\> for Form widget |
| `value` | Parsed form value (T) |
| `rawValue` | Raw field values as Map |
| `field<F>(key)` | Type-safe field access |
| `validate()` | Validate with UI errors |
| `silentValidate()` | Validate without UI |
| `save()` | Trigger FormState save |
| `reset()` | Restore initial values |
| `clear()` | Clear all fields |
| `listenable` | Combined listenable |
| `addValueChangedListener(fn)` | Listen to changes |
| `removeValueChangedListener(fn)` | Remove listener |
| `dispose()` | Clean up all fields |

## Examples

For complete examples covering all features, see the [example app](https://github.com/edunatalec/valiform/tree/master/example).
