# Valiform

[![pub package](https://img.shields.io/pub/v/valiform.svg)](https://pub.dev/packages/valiform)
[![package publisher](https://img.shields.io/pub/publisher/valiform.svg)](https://pub.dev/packages/valiform/publisher)

A Flutter form validation library built on top of [Validart](https://pub.dev/packages/validart). It provides reactive form state management, typed field validation, and seamless integration with Flutter's `Form` widget.

- **Schema-first** — define every field once with `V.map()` or `V.object<T>()`.
- **Fully typed** — `VField<T>` for each field; with `VObject<T>`, `form.value` returns a typed `T` instance instead of a `Map`.
- **Imperative errors** — push errors into fields programmatically with `setError()` (backend rejections, async checks, business rules).
- **Reactive** — `ValueNotifier`-based state, wire to any widget.
- **UI-agnostic** — works with `TextFormField` or any custom `FormField`.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Initial Values](#initial-values)
  - [`defaultValue` vs `initialValues` — pick the right one](#defaultvalue-vs-initialvalues--pick-the-right-one)
  - [Binding widgets' `initialValue`](#binding-widgets-initialvalue)
- [Typed Forms (VObject)](#typed-forms-vobject)
- [Field Types](#field-types)
- [Transforms](#transforms)
  - [Pipeline order — container preprocess vs field preprocess](#pipeline-order--container-preprocess-vs-field-preprocess)
- [Optional Fields](#optional-fields)
- [Conditional Validation (`.when()`)](#conditional-validation)
  - [Predicate-based: `whenMatches`](#predicate-based-whenmatches)
- [Cross-Field Validation](#cross-field-validation)
- [Controller Sync](#controller-sync)
  - [`attachController(ValueNotifier<T?>)`](#attachcontrollervaluenotifiert)
  - [`attachTextController(TextEditingController)`](#attachtextcontrollertexteditingcontroller-extension-on-vfieldstring)
  - [Ownership](#ownership)
  - [Cursor behavior](#cursor-behavior)
  - [`onValueChanged` — bridge for non-ValueNotifier state](#onvaluechanged--bridge-for-non-valuenotifier-state)
- [Imperative Errors](#imperative-errors)
  - [Via VForm](#via-vform)
  - [Via VField](#via-vfield)
  - [Options](#options)
  - [Single-field refresh](#single-field-refresh)
- [Inspecting Errors](#inspecting-errors)
  - [Detailed errors with path — `vError` / `vErrors()`](#detailed-errors-with-path--verror--verrors)
- [Form-level (root) errors](#form-level-root-errors)
- [Async Validation](#async-validation)
- [Validation Modes](#validation-modes)
- [Reactive Features](#reactive-features)
  - [Form-level value changes](#form-level-value-changes)
  - [Per-field reactive UI](#per-field-reactive-ui)
- [Disposing Resources](#disposing-resources)
- [More from Validart](#more-from-validart)
  - [Validation Rules](#validation-rules)
  - [Internationalization (i18n)](#internationalization-i18n)
- [API Reference](#api-reference)
  - [`VField<T>`](#vfieldt)
  - [`VForm<T>`](#vformt)
- [Example App](#example-app)
- [License](#license)

## Installation

Both packages are required — valiform handles forms, validart handles schemas.

```sh
flutter pub add valiform validart
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  valiform: ^2.2.1
  validart: ^2.2.0
```

## Quick Start

Full working page: [`example/lib/pages/basic_map_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/basic_map_form_page.dart).

```dart
import 'package:flutter/material.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final VForm<Map<String, dynamic>> _form;

  @override
  void initState() {
    super.initState();

    _form = V.map({
      // Schema (V.string(), .email(), .password(), ...) comes from validart;
      // .form() is valiform's bridge into a Flutter `Form`.
      'email': V.string().email(),
      'password': V.string().password(),
    }).form();
  }

  @override
  void dispose() {
    _form.dispose(); // disposes every VField and any owned controllers

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
            decoration: const InputDecoration(labelText: 'Email'),
            validator: _email.validator,
            onChanged: _email.onChanged,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
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
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
```

## Initial Values

Each field's starting value resolves in this order:

1. **`initialValues[key]`** in `.form()` — always wins when provided (even an explicit `null`).
2. **`schema.defaultValue(...)`** — fallback when `initialValues` doesn't mention the field.
3. **`null`** — otherwise.

```dart
// VMap form
final form = V.map({
  'email': V.string().email(),
}).form(initialValues: {'email': 'user@example.com'});

// VObject form — pass a typed instance
final form = V
    .object<User>()
    .field('name', (u) => u.name, V.string())
    .field('email', (u) => u.email, V.string().email())
    .form(
      builder: (data) => User(name: data['name'], email: data['email']),
      initialValue: const User(name: 'John', email: 'john@example.com'),
    );
```

In the widget, bind **`field.initialValue`** (not `field.value`) to the widget's `initialValue` parameter so `FormField.reset()` targets the true starting point:

```dart
final email = form.field<String>('email');

TextFormField(
  initialValue: email.initialValue, // stable across rebuilds
  validator: email.validator,
  onChanged: email.onChanged,
);
```

Full rationale in [Binding widgets' `initialValue`](#binding-widgets-initialvalue).

`form.reset()` restores each field to its resolved initial value.

### `defaultValue` vs `initialValues` — pick the right one

Both pre-fill a field, but they mean different things. Demo: [`default_value_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/default_value_page.dart).

|                     | `defaultValue()` on the schema                                 | `initialValues` on `.form()`                               |
| ------------------- | -------------------------------------------------------------- | ---------------------------------------------------------- |
| Appears in the UI   | Yes (auto-populated)                                           | Yes                                                        |
| Target of `reset()` | Yes                                                            | Yes (wins when both set)                                   |
| Field is required?  | **No** — default is substituted for null before validators run | Yes — clearing the field can trigger `required`/`min`/etc. |
| Lives on            | Schema                                                         | Form instance                                              |

> **Key rule:** `defaultValue` makes the field **never required**. If you want a pre-filled value that the user can still invalidate by clearing it, use `initialValues`. Combine both when you want "pre-fill Alice, but fall back to Guest if the user empties the field".

```dart
// Pre-filled + non-required: submit never errors on this field.
V.string().min(2).defaultValue('Guest')

// Pre-filled but still required: clearing triggers the error.
V.string().min(2)  // + .form(initialValues: {'name': 'Alice'})

// Pre-filled with Alice, but empty submit falls back to Guest.
V.string().min(2).defaultValue('Guest')
  // + .form(initialValues: {'name': 'Alice'})
```

### Binding widgets' `initialValue`

When you pass a `VField`'s value to a widget's `initialValue` parameter (e.g. `TextFormField.initialValue`), use **`field.initialValue`**, not `field.value`. Flutter's `FormField.reset()` re-reads `widget.initialValue` from the last build — if it's pointing at `field.value`, any rebuild during typing (from `onValueChanged`, submit's `setState`, etc.) recaptures the current text as "initial" and a later `reset()` restores the stale value instead of clearing. `field.initialValue` is stable across rebuilds, so reset always targets the true starting point.

```dart
TextFormField(
  initialValue: field.initialValue,   // stable — reset() targets this
  validator: field.validator,
  onChanged: field.onChanged,
);
```

## Typed Forms (VObject)

Return a typed object instead of a `Map`. Full example: [`object_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/object_form_page.dart).

```dart
class User {
  final String name;
  final String email;

  const User({required this.name, required this.email});
}

final form = V
    .object<User>()
    .field('name', (u) => u.name, V.string().min(3))
    .field('email', (u) => u.email, V.string().email())
    .form(
      builder: (data) => User(name: data['name'], email: data['email']),
    );

final user = form.value; // User instance
```

> **`form.value` is optimistic — it does not validate first.** It calls your builder with whatever is currently in the fields (empty fields come through as `null`). If `User` has non-nullable parameters, passing `null` to the constructor throws `TypeError` at runtime. **This is specific to `VObject` forms** — a `VMap` form returns a `Map<String, dynamic>` directly, so `null`s fit and nothing breaks.
>
> Note: the crash is exclusive to `form.value`. **`form.validate()` and `form.silentValidate()` themselves never invoke your builder on a partial form** — they fall back to per-field iteration whenever the builder can't construct `T`, so the canonical "validate first" pattern below is always safe.
>
> Three ways to stay safe on a `VObject` form:
>
> 1. **Validate first** (idiomatic) — read `form.value` only inside a validated branch:
>    ```dart
>    if (form.validate()) {
>      final user = form.value; // guaranteed safe
>    }
>    ```
> 2. **Null-guard inside the builder** — let the builder fall back when a field is empty:
>    ```dart
>    builder: (data) => User(
>      name: data['name'] ?? '',
>      email: data['email'] ?? '',
>    ),
>    ```
> 3. **Read raw values instead of building `T`** — `form.rawValue` returns `Map<String, dynamic>` (not `T`) and is null-tolerant, and `form.field<String>('name').value` reads a single field without touching the builder.

## Field Types

Every validart type maps to a correctly-typed `VField<T>`. Demos: [`multi_type_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/multi_type_form_page.dart), [`checkbox_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/checkbox_form_page.dart), [`dropdown_enum_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/dropdown_enum_page.dart), [`custom_class_field_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/custom_class_field_page.dart).

```dart
final form = V.map({
  'name':      V.string().min(3),
  'age':       V.int().min(18),
  'score':     V.double().min(0).max(10),
  'active':    V.bool(),
  'birthday':  V.date(),
  'country':   V.enm<Country>(Country.values),
  'category':  V.object<Category>(),
  'tags':      V.array<String>(V.string().min(2)).min(1).max(5),
}).form();

final name     = form.field<String>('name');       // VField<String>
final age      = form.field<int>('age');           // VField<int>
final score    = form.field<double>('score');      // VField<double>
final active   = form.field<bool>('active');       // VField<bool>
final birthday = form.field<DateTime>('birthday'); // VField<DateTime>
final country  = form.field<Country>('country');   // VField<Country>
final category = form.field<Category>('category'); // VField<Category>
final tags     = form.field<List<String>>('tags'); // VField<List<String>>
```

> **Note on `V.enm`:** always pass the enum type explicitly inside a `V.map({...})` literal — `V.enm<Country>(Country.values)`, not `V.enm(Country.values)`. The Dart analyzer can't infer the generic when the map context is raw and falls back to the upper bound (`Enum`), which then makes `form.field<Country>('country')` throw `Invalid argument: The field "country" is of type VField<Enum>, not VField<Country>`.

## Transforms

Pipeline transforms (`trim`, `toLowerCase`, `preprocess`) run **before** validation — regardless of the order you chain them. `form.rawValue` exposes the raw input; `form.value` exposes the transformed result.

Live preview: [`transforms_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/transforms_page.dart).

```dart
final form = V.map({
  // order-independent: trim at the end runs before email() anyway.
  'email': V.string().toLowerCase().email().trim(),
}).form();

form.field<String>('email').set('  USER@Email.com  ');

form.rawValue['email']; // '  USER@Email.com  '
form.value['email'];    // 'user@email.com'
```

### Pipeline order — container preprocess vs field preprocess

`VForm` runs validart's pipeline as-is. The full ordering — container preprocess, per-field preprocess, validators, transforms, async stages, and how preprocessors compose with `nullable()` / `defaultValue()` — is documented in the validart README:

- [Pipeline order — primitives](https://pub.dev/packages/validart#pipeline-order--primitives)
- [Pipeline order — containers (`VMap` / `VObject`)](https://pub.dev/packages/validart#pipeline-order--containers-vmap--vobject)
- [Preprocess](https://pub.dev/packages/validart#preprocess) and [Transform](https://pub.dev/packages/validart#transform)

**Valiform-specific note:** `field.validator(value)` and `form.parsedValue` honor the **container** preprocess too, not just the field's own pipeline. So a `V.map({...}).preprocess(rewriteCrossField)` reaches the per-field validator and stays in sync with `form.silentValidate()`. The only exception is when the container uses `preprocessAsync` — Flutter's sync `FormField.validator` cannot `await`, so it falls through; use `form.validateAsync` / `form.parsedValueAsync` for the full async path.

Live demo of cross-field rewrites: [`preprocess_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/preprocess_page.dart).

## Optional Fields

Use `.nullable()` for fields that can be empty. All types supported: [`optional_fields_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/optional_fields_page.dart).

```dart
final form = V.map({
  'name':  V.string().min(3),              // required
  'phone': V.string().phone().nullable(),  // optional — empty = null
  'age':   V.int().min(0).nullable(),      // optional
}).form();
```

For nullable `VField<String>`, empty strings are normalized to `null` automatically.

## Conditional Validation

Apply different validation rules based on another field's value. Live demo with CPF/CNPJ and email/url/phone: [`conditional_validation_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/conditional_validation_page.dart).

```dart
// Same field, different rules
final form = V.map({
  'contactType': V.string(),
  'contact': V.string(),
}).when('contactType', equals: 'email', then: {
  'contact': V.string().email(),
}).when('contactType', equals: 'url', then: {
  'contact': V.string().url(),
}).form();
```

```dart
// Different fields required based on condition
final form = V.map({
  'type': V.string(),
  'cpf':  V.string().nullable(),
  'cnpj': V.string().nullable(),
}).when('type', equals: 'person',  then: {'cpf':  V.string().min(11)})
  .when('type', equals: 'company', then: {'cnpj': V.string().min(14)})
  .form();
```

Errors from `.when()` rules surface directly on the target fields.

### Predicate-based: `whenMatches`

When the trigger needs more than equality — `>`, `>=`, `oneOf`, or a combination of multiple fields — reach for `whenMatches`. The predicate receives the raw input map (or the typed `T` for `VObject`); when it returns `true`, every validator in `then` is applied to the corresponding field. Live demo: [`when_matches_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/when_matches_page.dart).

```dart
// Numeric threshold — impossible with .when(equals:).
final form = V.map({
  'age': V.int(),
  'license': V.string().nullable(),
}).whenMatches(
  (m) => (m['age'] as int? ?? 0) >= 18,
  dependsOn: const {'age'},
  then: {'license': V.string().min(5)},
).form();
```

```dart
// Combined-field predicate — auditToken required only for senior admins.
final form = V.map({
  'role': V.string(),
  'level': V.int(),
  'auditToken': V.string().nullable(),
}).whenMatches(
  (m) => m['role'] == 'admin' && (m['level'] as int? ?? 0) > 5,
  dependsOn: const {'role', 'level'},
  then: {'auditToken': V.string().min(8)},
).form();
```

`dependsOn` is required by validart so subsequent `refine(dependsOn: {...})` rules can reference the same fields without tripping the schema's known-keys assertion. The predicate itself is always synchronous; the validators inside `then` may be sync or async (an async target opts the form into async mode, same as `when`). Errors surface inline on the target field through the same channel as `when`.

## Cross-Field Validation

Every cross-field primitive lives in validart — `refineField`, `refineFieldRaw`, `equalFields`, and `refine(..., dependsOn:)`. `VForm` passes them through unchanged; the only thing the form layer adds is **error demuxing**: path-keyed errors surface inline under the target field, path-empty errors land in [`form.rootErrors`](#form-level-root-errors).

For the full semantics of each primitive — when each callback runs, what it receives, how `dependsOn` controls aggregation — read the canonical docs in the validart README:

- [Cross-Field Validation on `VMap`](https://pub.dev/packages/validart#cross-field-validation) and [on `VObject`](https://pub.dev/packages/validart#cross-field-validation-1)
- [`refineField` (parsed) and `refineFieldRaw` (raw)](https://pub.dev/packages/validart#custom-field-validation)
- [`refine` with `dependsOn` for error aggregation](https://pub.dev/packages/validart#refine-with-dependson-for-error-aggregation-on-vmap--vobject)
- [Root-level errors via `rootMessages()`](https://pub.dev/packages/validart#root-level-errors-via-rootmessages)

**TL;DR — when to reach for which:**

| Primitive                          | Error path | Where the UI shows it                                                                                  |
| ---------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------ |
| `refineField(check, path: 'x')`    | `[x]`      | inline under `x` (use this by default)                                                                 |
| `refineFieldRaw(check, path: 'x')` | `[x]`      | inline under `x` — callback sees raw input (use only when casing/whitespace matters before transforms) |
| `equalFields(a, b)`                | `[]`       | banner via `form.rootErrors`                                                                           |
| `refine(check, dependsOn: {...})`  | `[]`       | banner via `form.rootErrors`                                                                           |

Live demos: [`password_match_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/password_match_page.dart), [`refine_field_raw_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/refine_field_raw_page.dart), [`object_validation_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/object_validation_page.dart), [`root_errors_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/root_errors_page.dart).

## Controller Sync

Two bidirectional-sync paths, both with typed getters — no casts. Full walkthrough of ownership and `ValueNotifier<int?>` counter: [`controller_sync_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/controller_sync_page.dart).

### `attachController(ValueNotifier<T?>)`

For plain `ValueNotifier` or any custom controller that extends it (e.g. `LuneSelectFieldController<T>`):

```dart
final country = form.field<Country>('country');
country.attachController(LuneSelectFieldController<Country>());

// retrieve typed:
final ctrl = country.controller; // ValueNotifier<Country?>?
```

### `attachTextController(TextEditingController)` (extension on `VField<String>`)

Use a controller whenever the widget needs to be externally controlled — set/clear text from code, prepend a prefix, drive a custom keyboard. Once attached, the bridge is **two-way**: what the user types updates the field, and `field.set(...)` updates both the field and the controller.

```dart
final email = form.field<String>('email');
email.attachTextController(TextEditingController());

// in build():
TextFormField(
  controller: email.textController,
  validator: email.validator,
);

// later, a programmatic update propagates to both sides:
email.set('new@example.com'); // field.value AND textController.text update
```

> If you don't need external control of the `TextFormField`, skip `attachTextController` entirely — wire `onChanged: email.onChanged` + `validator: email.validator` and the field owns the value by itself.

### Ownership

Both `attachController` and `attachTextController` take **ownership by default** — the controller is disposed together with the field (and together with the form via `form.dispose()`):

```dart
// Inline: field disposes the controller when form.dispose() runs.
email.attachTextController(TextEditingController());
```

Pass `owns: false` when you manage the controller's lifecycle yourself — **you are then responsible for calling `dispose()` on it**, otherwise it leaks:

```dart
final shared = TextEditingController(); // you own it
email.attachTextController(shared, owns: false);

// later, in your State.dispose():
@override
void dispose() {
  shared.dispose(); // you must call this — field.dispose() won't
  _form.dispose();
  super.dispose();
}
```

### Cursor behavior

When the user types, the cursor stays where they placed it — valiform only reads `controller.text` in the sync listener and never writes back during user input (the internal `_syncing` flag + equality check prevent cascading updates).

When you call `field.set('new value')` programmatically, Flutter's `TextEditingController.text` setter resets the cursor to the end of the text (`offset: -1`). That's Flutter's default behavior for the text setter — use `controller.value = TextEditingValue(text: ..., selection: ...)` directly if you need to preserve a custom cursor position on a programmatic update.

### `onValueChanged` — bridge for non-ValueNotifier state

When the external state isn't a `ValueNotifier<T?>` (analytics, a custom data store, anything):

```dart
final dispose = email.onValueChanged((value) {
  analytics.log('email', value);
});
// later: dispose();
```

The callback receives the typed value on every change and returns a dispose function. It is cleaned up automatically on `field.dispose()`.

## Imperative Errors

Force validation errors programmatically — backend rejections, async checks, external business rules. Full demo with 3 fields, 6 buttons: [`manual_error_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/manual_error_page.dart).

### Via VForm

```dart
// Single field
form.setError('email', 'Email already taken');

// Batch (typical API response)
form.setErrors({
  'email': 'Invalid domain',
  'cpf':   'Already registered',
});

// Clearing
form.clearError('email');
form.clearErrors();
```

### Via VField

```dart
final email = form.field<String>('email');
email.setError('Email already taken');
email.clearError();
```

### Options

| Flag                       | Behaviour                                                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `persist: false` (default) | **One-shot** — consumed on the next validation, even when a standard error wins precedence. No ghost errors later. |
| `persist: true`            | Keeps the error across validations until `clearError()`.                                                           |
| `force: false` (default)   | Standard validators win — manual error only shows when the field is otherwise valid.                               |
| `force: true`              | Overrides standard precedence — manual error shows regardless.                                                     |

Combine `persist: true, force: true` for server-side blocks (e.g. "Account suspended") that stay visible until cleared.

### Single-field refresh

Attach `field.key` to your `TextFormField` (or any `FormField`) so `setError` revalidates only that field — other fields aren't touched:

```dart
final email = form.field<String>('email');

TextFormField(
  key: email.key,
  validator: email.validator,
  onChanged: email.onChanged,
);

// later:
email.setError('Email already taken'); // only the email field refreshes
```

## Inspecting Errors

Read-only access to the current validation state — useful for live error summaries, debug panels, or custom error displays. Live panels in [`errors_preview_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/errors_preview_page.dart).

```dart
// All current errors across the form (null when all fields pass)
final errors = form.errors();
// { 'email': 'Invalid email', 'age': 'Must be at least 18' }

// Single field's current error
final emailError = form.field<String>('email').error;
// 'Invalid email' or null
```

Both are **non-consuming** — they don't clear one-shot manual errors and don't trigger any UI refresh. Safe to call from a `ListenableBuilder` that rebuilds on every keystroke.

```dart
ListenableBuilder(
  listenable: form.listenable,
  builder: (context, _) {
    final errors = form.errors();
    if (errors == null) return const Text('All good ✓');
    return Column(
      children: errors.entries
          .map((e) => Text('${e.key}: ${e.value}'))
          .toList(),
    );
  },
)
```

### Detailed errors with path — `vError` / `vErrors()`

When you need more than the first message — array element indices, validator codes, custom error rendering — use `field.vError` / `form.vErrors()`. They return the full validart `List<VError>` with `code`, `path`, and `message`. Live demo: [`v_errors_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/v_errors_page.dart).

```dart
final form = V.map({
  'emails': V.array<String>(V.string().email()).min(1),
}).form();

form.field<List<String>>('emails').set(['a@b.com', 'bad']);

form.errors();
// {'emails': 'Invalid email address'}  ← just the message

form.vErrors();
// {'emails': [VError(code: 'string.email', path: [1], message: 'Invalid email address')]}
//                                                 ^^^^^^^ index of the invalid element
```

Cross-field validators and imperative errors (which are produced outside validart) are wrapped as `VError(code: VCode.custom, message: ...)`.

Typical use: render an array with the failing index highlighted.

```dart
final arrayErrors = form.vErrors()?['emails'] ?? const [];
final badIndexes = arrayErrors
    .where((e) => e.path.length == 1 && e.path.first is int)
    .map((e) => e.path.first as int)
    .toSet();
// paint list items whose index is in badIndexes
```

> **Reading messages correctly:** always use `e.message` — it holds the exact text (your `setError` message, or the localized text resolved when the VError was created). `e.code` is a machine identifier (`VStringCode.email`, `VCode.custom`, ...) for filtering/logic, not for translation at read time. Calling `V.t(e.code)` on a `VCode.custom` error pulls the generic `'custom'` entry from the active locale, not the message you passed to `setError`.

## Form-level (root) errors

`form.errors()` is field-keyed: it answers _"which fields are wrong, and why?"_. Some validation rules don't belong to any single field — date ranges, totals, "a and b must differ". Those emit **root errors** (errors with no field path).

> **⚠️ Important — root errors do NOT show up under any FormField automatically.** They are not wired into Flutter's per-field `FormField.validator` channel (a field path is needed to know where to render). You must render them yourself — typically as a banner above the form. `form.validate()` does include root errors in its return value (so the submit gate is correct), but the visual feedback is on you.

> **Recommendation — prefer rules with a path when you can.** Path-pinned rules surface inline under the offending field automatically. Reach for root errors only when the rule genuinely belongs to the form as a whole.

### Which schema constructs emit root vs field-keyed errors

| Construct                                                               | Path               | Where it shows up                          |
| ----------------------------------------------------------------------- | ------------------ | ------------------------------------------ |
| Per-field validators (`V.string().email()`, `.min(3)`, ...)             | `[fieldName, ...]` | inline under the field                     |
| `.when(field, equals:, then: {target: ...})`                            | `[target]`         | inline under `target`                      |
| `VMap.refineField(check, path: 'x')`                                    | `[x]`              | inline under `x`                           |
| `VObject<T>.refineField(check, path: 'x')`                              | `[x]`              | inline under `x`                           |
| `VMap.refineFieldRaw(check, path: 'x')`                                 | `[x]`              | inline under `x` (callback sees raw input) |
| `VObject<T>.refineFieldRaw(check, path: 'x')`                           | `[x]`              | inline under `x` (callback sees raw input) |
| **`VMap.refine(check)` / `.refine(check, dependsOn: {...})` (no path)** | `[]` (empty)       | **`form.rootErrors` only — no inline UI**  |
| **`VObject<T>.refine(check, dependsOn: {...})`**                        | `[]` (empty)       | **`form.rootErrors` only — no inline UI**  |
| **`.equalFields(a, b)` on `VMap` / `VObject<T>`**                       | `[]` (empty)       | **`form.rootErrors` only — no inline UI**  |

VForm demuxes the validart `VFailure` for you: errors with a non-empty top-level path land on the corresponding `VField` (so they reach `field.error`, `form.errors()`, and `FormField.validator`), and errors with an empty path land in `form.rootErrors`. This means **`refineField` / `refineFieldRaw` get inline rendering for free** — you don't have to wire anything per-field.

If you can express the rule with a `path:` argument, do that — the user gets inline feedback for free. Use root errors only for cross-field or form-wide invariants that don't have a single "target" field.

### Rendering root errors

```dart
final form = V.map({
  'startDate': V.date(),
  'endDate':   V.date(),
}).refine(
  (m) => (m['endDate'] as DateTime).isAfter(m['startDate'] as DateTime),
  message: 'endDate must be after startDate',
  dependsOn: const {'startDate', 'endDate'},
).form();

ListenableBuilder(
  listenable: form.listenable,
  builder: (context, _) {
    final root = form.rootErrors;
    if (root.isEmpty) return const SizedBox.shrink();
    return RootErrorBanner(messages: root);
  },
)
```

Live demo: [`root_errors_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/root_errors_page.dart).

`rootErrors` is **self-contained** — each access re-runs the schema-level `safeParse` against the current parsed values, so the banner stays in sync with what the user types without you having to call `silentValidate()` first. `form.validate()` also re-runs the schema, so its return value is correct even when the only failure is at root level.

For async schemas the sync getter throws `VAsyncRequiredException`; use `form.rootErrorsAsync` (also self-contained — awaits each field's async pipeline before re-running `safeParseAsync`). `form.validateAsync()` already incorporates root errors into its return value too.

## Async Validation

When a schema contains async steps (`refineAsync`, `preprocessAsync`, `transformAsync` from validart 1.1+), use the `*Async` methods. Sync inspection methods throw `VAsyncRequiredException` — this mirrors validart's own contract and prevents a form from silently submitting before the async check ran. The only sync method that stays tolerant is `VField.validator(T?)` (the required adapter for Flutter's sync `FormField.validator`; it is also the channel `validateAsync` uses to paint errors through `setError`). Full demo: [`async_validation_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/async_validation_page.dart).

```dart
final form = V.map({
  'username': V.string().min(3).refineAsync(
    (value) async {
      final available = await api.checkUsername(value);
      return available;
    },
    message: 'Username already taken',
    timeout: const Duration(seconds: 2),
  ),
}).form();

// Sync rules (min 3) fire automatically as the user types.
// Run the async check on submit:
Future<void> onSubmit() async {
  if (await form.validateAsync()) {
    final data = await form.valueAsync;
    print(data);
  }
}
```

`form.validateAsync()` runs the full pipeline for every field and propagates async errors through the same UI channel as sync validation — no extra wiring needed on your `FormField`s. Afterwards, read `form.valueAsync` to get the parsed value (transforms applied).

| Method                             |               Triggers UI               | Returns                              |
| ---------------------------------- | :-------------------------------------: | ------------------------------------ |
| `form.validateAsync()`             | ✓ (via persistent errors + `FormState`) | `Future<bool>`                       |
| `form.silentValidateAsync()`       |                    ✗                    | `Future<bool>`                       |
| `form.errorsAsync()`               |                    ✗                    | `Future<Map<String, String>?>`       |
| `form.vErrorsAsync()`              |                    ✗                    | `Future<Map<String, List<VError>>?>` |
| `form.valueAsync`                  |                    ✗                    | `Future<T>`                          |
| `form.hasAsync` / `field.hasAsync` |                    ✗                    | `bool`                               |
| `field.validateAsync()`            |                    ✗                    | `Future<bool>`                       |
| `field.errorAsync`                 |                    ✗                    | `Future<String?>`                    |
| `field.vErrorAsync`                |                    ✗                    | `Future<List<VError>?>`              |
| `field.parsedValueAsync`           |                    ✗                    | `Future<T?>`                         |

Mixed sync/async schemas: individual sync fields still surface their own errors via `field.validator` (that's what Flutter's `TextFormField` calls while typing). The form-level sync methods (`form.validate`, `silentValidate`, `errors`, `vErrors`, `value`) throw `VAsyncRequiredException` — run `validateAsync` on submit.

## Validation Modes

Valiform exposes several ways to validate — pick based on whether you want UI side-effects and whether you want state mutation.

| Method                  |               Triggers UI                | Consumes one-shot manual errors | Includes schema-level rules (`refine`, `equalFields`, `dependsOn`) | Returns                      |
| ----------------------- | :--------------------------------------: | :-----------------------------: | :----------------------------------------------------------------: | ---------------------------- |
| `form.validate()`       | ✓ (via Flutter's `FormState.validate()`) |                ✓                |                                 ✓                                  | `bool`                       |
| `form.silentValidate()` |                    ✗                     |                ✓                |                                 ✓                                  | `bool`                       |
| `form.errors()`         |                    ✗                     |                ✗                |                      only field-keyed errors                       | `Map<String, String>?`       |
| `form.vErrors()`        |                    ✗                     |                ✗                |                      only field-keyed errors                       | `Map<String, List<VError>>?` |
| `form.rootErrors`       |                    ✗                     |                ✗                |              only schema-level errors with empty path              | `List<String>`               |
| `field.validator(v)`    |            depends on widget             |                ✓                |             only via `when` rules targeting this field             | `String?`                    |
| `field.validate()`      |                    ✗                     |                ✗                |                           per-field only                           | `bool`                       |
| `field.error`           |                    ✗                     |                ✗                |                           per-field only                           | `String?`                    |
| `field.vError`          |                    ✗                     |                ✗                |                           per-field only                           | `List<VError>?`              |

**Rule of thumb:**

- Submit button → `form.validate()`. It now covers per-field AND schema-level rules — no need to combine with `silentValidate()`.
- Business logic / debouncing / analytics → `form.silentValidate()` or `form.errors()`.
- Custom error UIs → `form.errors()` (field-keyed) + `form.rootErrors` (form-level banner) + `field.error`.

## Reactive Features

Live JSON preview of a form as you type: [`reactive_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/reactive_form_page.dart).

### Form-level value changes

```dart
// At construction time
final form = V.map({...}).form(
  onValueChanged: (value) => print(value),
);

// Or later, dynamically
void listener(Map<String, dynamic> value) => print(value);
form.addValueChangedListener(listener);
// later:
form.removeValueChangedListener(listener);
```

The callback always receives `Map<String, dynamic>` with the raw field values, even for forms created from `V.object<T>(...)`. A field change does not imply the form is valid enough for the `builder` to construct `T` — emitting raw values keeps the listener safe against partial state. Use `form.value` (or `form.valueAsync`) **after** `form.validate()` returns `true` when you need the typed `T`; alternatively guard the `builder` with `??` defaults or nullable parameters. Same callback shape works on sync and async schemas.

### Per-field reactive UI

```dart
final email = form.field<String>('email');

ListenableBuilder(
  listenable: email.listenable,
  builder: (context, _) => Text('${email.value?.length ?? 0} chars'),
);
```

## Disposing Resources

Both `VForm` and `VField` hold listeners and (optionally) own controllers — always dispose them.

```dart
// Typical: dispose the whole form in your State.dispose()
@override
void dispose() {
  _form.dispose(); // disposes every VField + any owned controllers
  super.dispose();
}
```

```dart
// Standalone VField (rare — usually the form manages fields for you)
final field = VField<String>(type: V.string(), validators: []);
// ...
field.dispose();
```

If you attached a controller with `owns: false`, you are responsible for its `dispose()` — the field won't touch it.

## More from Validart

Valiform handles form state and UI wiring; the validation rules and localized messages come from [Validart](https://pub.dev/packages/validart). Anything valid in a Validart schema works inside `V.map({...}).form()` or `V.object<T>(...).form()`.

### Validation Rules

For the full catalog of built-in validators — `email()`, `password()`, `regex()`, `cpf()`, `cnpj()`, type coercions, `refine` / `refineAsync`, `preprocess` / `transform`, custom messages — read the [Validart documentation](https://pub.dev/packages/validart). Valiform forwards every rule unchanged; this README focuses on the Flutter/form layer on top.

### Internationalization (i18n)

Error messages are localized through Validart's locale system — switch locale globally or customize individual messages at the schema level. See [Validart's i18n guide](https://pub.dev/packages/validart#i18n-internationalization) for the full locale catalog and override patterns, and [`locale_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/locale_page.dart) for a live runtime-switch demo.

## API Reference

### `VField<T>`

| Member                                                | Description                                                                                                                                                        |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `value`                                               | Raw value                                                                                                                                                          |
| `initialValue`                                        | Stable initial value (resolved at construction). Prefer over `value` when binding to widget `initialValue` parameters so `reset()` targets the true starting point |
| `parsedValue`                                         | Value after pipeline transforms (trim, toLowerCase, ...)                                                                                                           |
| `set(T?)`                                             | Update value programmatically                                                                                                                                      |
| `onChanged(T?)`                                       | Wire to widget `onChanged` callbacks                                                                                                                               |
| `onSaved(T?)`                                         | Wire to widget `onSaved` callbacks                                                                                                                                 |
| `reset()`                                             | Restore initial value                                                                                                                                              |
| `listenable`                                          | `Listenable` for reactive UI                                                                                                                                       |
| `hasAsync`                                            | `true` when the field depends on any async step                                                                                                                    |
| `validator(T?)`                                       | Returns error or `null` — **consumes** one-shot manual errors (for Flutter's `FormField` pipeline)                                                                 |
| `validate()`                                          | Returns `true` if valid — read-only, non-consuming. Throws when `hasAsync` is true                                                                                 |
| `validateAsync()`                                     | Async variant — runs full pipeline including `refineAsync`                                                                                                         |
| `error` / `errorAsync`                                | Current error message or `null` (sync throws when `hasAsync`, async always safe)                                                                                   |
| `vError` / `vErrorAsync`                              | Current errors as `List<VError>?` (sync throws when `hasAsync`, async always safe)                                                                                 |
| `parsedValueAsync`                                    | Future with pipeline-transformed value (includes async preprocessors)                                                                                              |
| `manualError`                                         | Current imperative error or `null`                                                                                                                                 |
| `setError(message, {persist, force})`                 | Set an imperative error                                                                                                                                            |
| `clearError()`                                        | Remove imperative error                                                                                                                                            |
| `key`                                                 | `GlobalKey<FormFieldState<T>>` — attach to `FormField` for single-field refresh                                                                                    |
| `attachController(ValueNotifier<T?>, {owns})`         | Bidirectional sync with a `ValueNotifier<T?>` (or subclass). Owned by default.                                                                                     |
| `attachTextController(TextEditingController, {owns})` | (extension on `VField<String>`) Bidirectional sync with a text controller                                                                                          |
| `controller`                                          | Attached `ValueNotifier<T?>?`                                                                                                                                      |
| `textController`                                      | (extension on `VField<String>`) Attached `TextEditingController?`                                                                                                  |
| `detachController()`                                  | Remove sync listeners (does not dispose)                                                                                                                           |
| `onValueChanged(callback)`                            | Bridge for external state — returns a dispose function                                                                                                             |
| `dispose()`                                           | Release resources (disposes owned controllers)                                                                                                                     |

### `VForm<T>`

| Member                                                           | Description                                                                 |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `key`                                                            | `GlobalKey<FormState>` for the Flutter `Form` widget                        |
| `value` / `valueAsync`                                           | Parsed form value (typed `T`) — `valueAsync` awaits async pipelines         |
| `rawValue`                                                       | Raw field values as `Map<String, dynamic>`                                  |
| `hasAsync`                                                       | `true` when any field needs async validation                                |
| `field<F>(key)`                                                  | Type-safe field access                                                      |
| `listenable`                                                     | Combined `Listenable` across all fields                                     |
| `validate()`                                                     | Validate all fields with UI errors                                          |
| `validateAsync()`                                                | Async variant — full pipeline, surfaces errors via persistent manual errors |
| `silentValidate()` / `silentValidateAsync()`                     | Validate without touching the UI (sync / async)                             |
| `errors()` / `errorsAsync()`                                     | Map of current error messages — read-only (sync / async)                    |
| `vErrors()` / `vErrorsAsync()`                                   | Map of `List<VError>` per field (preserves `code`, `path`, `message`)       |
| `rootErrors` / `rootErrorsAsync`                                 | Form-level error messages from schema `refine(..., dependsOn:)` — banner    |
| `save()`                                                         | Trigger `FormState.save()`                                                  |
| `reset()`                                                        | Restore initial values                                                      |
| `setError(field, message, {persist, force})`                     | Set error on a specific field                                               |
| `setErrors(errors, {persist, force})`                            | Batch set errors across fields                                              |
| `clearError(field)`                                              | Clear error on a specific field                                             |
| `clearErrors()`                                                  | Clear all imperative errors                                                 |
| `addValueChangedListener(fn)` / `removeValueChangedListener(fn)` | Dynamic form-level listeners                                                |
| `dispose()`                                                      | Release all resources (each field + owned controllers)                      |

## Example App

Every feature in this README has a page in the [example app](https://github.com/edunatalec/valiform/tree/master/example). Run it to interact with each pattern live:

```sh
cd example
flutter create .   # generate platform folders the first time
flutter run
```

| Page                                                                                                                                        | What it shows                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [`basic_map_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/basic_map_form_page.dart)                 | Simplest VMap form + initial values                                                                  |
| [`object_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/object_form_page.dart)                       | `VObject<User>` returning a typed class                                                              |
| [`object_validation_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/object_validation_page.dart)           | `VObject` `equalFields`, `when`, `refineField` — typed cross-field rules                             |
| [`multi_type_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/multi_type_form_page.dart)               | All field types combined                                                                             |
| [`checkbox_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/checkbox_form_page.dart)                   | `V.bool().isTrue()` with a checkbox                                                                  |
| [`dropdown_enum_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/dropdown_enum_page.dart)                   | `V.enm<Country>` with dropdown                                                                       |
| [`custom_class_field_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/custom_class_field_page.dart)         | `V.object<Category>()` inside VMap                                                                   |
| [`array_field_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/array_field_page.dart)                       | `V.array<String>()` with tag input                                                                   |
| [`optional_fields_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/optional_fields_page.dart)               | Every type with `.nullable()`                                                                        |
| [`default_value_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/default_value_page.dart)                   | `defaultValue` vs `initialValues` — resolution & semantics                                           |
| [`required_message_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/required_message_page.dart)             | `V.bool(message: ...)` vs `preprocess` for custom required error                                     |
| [`transforms_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/transforms_page.dart)                         | Live `rawValue` vs `value` preview                                                                   |
| [`preprocess_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/preprocess_page.dart)                         | Container vs field preprocess — cross-field rewrite for VMap and VObject, raw vs parsed in real time |
| [`conditional_validation_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/conditional_validation_page.dart) | `.when()` conditional rules                                                                          |
| [`when_matches_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/when_matches_page.dart)                     | `.whenMatches()` predicate-based rules — numeric thresholds and combined-field triggers              |
| [`password_match_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/password_match_page.dart)                 | `refineField` vs `equalFields`                                                                       |
| [`refine_field_raw_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/refine_field_raw_page.dart)             | `refineField` (parsed) vs `refineFieldRaw` (raw) — same rule, different verdicts under a transform   |
| [`root_errors_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/root_errors_page.dart)                       | `form.rootErrors` banner from `refine(..., dependsOn:)` — form-level error aggregation               |
| [`controller_sync_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/controller_sync_page.dart)               | `TextEditingController` + `ValueNotifier<int?>` counter                                              |
| [`async_validation_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/async_validation_page.dart)             | `refineAsync` + `form.validateAsync()` with loading state                                            |
| [`complex_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/complex_form_page.dart)                     | Kitchen-sink: all types + nested map + array + enum + union + `.when()` sync/async + `refineField`   |
| [`manual_error_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/manual_error_page.dart)                     | `setError`, `persist`, `force`, batch                                                                |
| [`errors_preview_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/errors_preview_page.dart)                 | Live `form.errors()` / `field.error` panels                                                          |
| [`v_errors_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/v_errors_page.dart)                             | Structured `vErrors()` with `code` + `path` — array indices, i18n-ready error codes                  |
| [`reactive_form_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/reactive_form_page.dart)                   | Live JSON preview via `onValueChanged`                                                               |
| [`locale_page.dart`](https://github.com/edunatalec/valiform/tree/master/example/lib/pages/locale_page.dart)                                 | `VLocale` switching at runtime                                                                       |

## License

See [LICENSE](LICENSE) for details.
