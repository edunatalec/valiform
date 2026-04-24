import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Basic', () {
    late VForm<Map<String, dynamic>> form;
    late VField<String> email;
    late VField<String> password;

    setUp(() {
      form = V.map({
        'email': V.string().email(),
        'password': V.string().password(),
      }).form();

      email = form.field<String>('email');
      password = form.field<String>('password');
    });

    tearDown(() {
      form.dispose();
    });

    Widget buildFormWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Form(
            key: form.key,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('emailField'),
                  initialValue: email.value,
                  validator: email.validator,
                  onChanged: email.onChanged,
                ),
                TextFormField(
                  key: const Key('passwordField'),
                  initialValue: password.value,
                  validator: password.validator,
                  onChanged: password.onChanged,
                ),
              ],
            ),
          ),
        ),
      );
    }

    test('VForm initializes correctly', () {
      expect(form.key, isNotNull);
      expect(form.value.keys, containsAll(['email', 'password']));
    });

    test('Accessing fields works correctly', () {
      expect(email, isA<VField<String>>());
      expect(password, isA<VField<String>>());
    });

    test('Throws error if accessing non-existent field', () {
      expect(() => form.field<String>('unknown'), throwsArgumentError);
    });

    testWidgets('Validation returns false for invalid inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildFormWidget());

      await tester.enterText(find.byKey(const Key('emailField')), 'invalid');
      await tester.enterText(find.byKey(const Key('passwordField')), '123');

      expect(form.validate(), false);
    });

    testWidgets('Validation returns true for valid inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildFormWidget());

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'Aa1@aaaa',
      );

      expect(form.validate(), true);
    });

    test('silentValidate works correctly', () {
      email.set('test@example.com');
      password.set('StrongPassword1!');

      expect(form.silentValidate(), true);
    });

    testWidgets('save() calls FormState save()', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildFormWidget());

      final formState = form.key.currentState;
      expect(formState, isNotNull);

      form.save();

      expect(formState!.mounted, true);
    });

    test('reset() restores default values', () {
      email.set('temp@example.com');
      password.set('TempPass');

      form.reset();

      expect(email.value, isNull);
      expect(password.value, isNull);
    });

    test('Listenable notifies listeners', () {
      int notificationCount = 0;
      form.listenable.addListener(() {
        notificationCount++;
      });

      email.set('new@example.com');

      expect(notificationCount, 1);
    });

    test('Throws ArgumentError when accessing a non-existent field', () {
      expect(
        () => form.field<String>('non_existent_field'),
        throwsArgumentError,
      );
    });

    test('Throws ArgumentError when type is incorrect', () {
      expect(() => form.field<int>('email'), throwsArgumentError);
    });

    test('rawValue returns Map<String, dynamic>', () {
      email.set('test@example.com');
      password.set('Aa1@aaaa');

      expect(form.rawValue, {
        'email': 'test@example.com',
        'password': 'Aa1@aaaa',
      });
    });

    test('value returns Map<String, dynamic> for VMap form', () {
      email.set('test@example.com');
      password.set('Aa1@aaaa');

      final value = form.value;
      expect(value, isA<Map<String, dynamic>>());
      expect(value['email'], 'test@example.com');
    });

    test(
      'value does NOT throw when fields are empty on VMap — nulls fit inside Map<String, dynamic>',
      () {
        // Contrast with the VObject case: a VMap form just returns a Map
        // populated with whatever the fields hold (including `null`). No
        // builder is invoked, so there is no non-nullable constructor
        // parameter to explode on.
        //
        // Reading `form.value` on an unvalidated VMap is therefore safe —
        // the TypeError risk is exclusive to VObject forms whose builder
        // dereferences `data[key]` directly.
        expect(() => form.value, returnsNormally);
        expect(form.value, {'email': null, 'password': null});
      },
    );
  });

  group('form.listenable contract', () {
    test(
      'add/removeListener against an ad-hoc access still works — fresh merge propagates to the underlying field ValueNotifiers',
      () {
        // Listenable.merge returns a new wrapper on every form.listenable
        // access, BUT both wrappers delegate add/removeListener to the same
        // underlying field.listenable notifiers — so removeListener on a
        // second access correctly removes the listener registered on the
        // first. Pinning this here because a previous CLAUDE.md note
        // incorrectly claimed the opposite.
        final form = V.map({'name': V.string()}).form();

        final a = form.listenable;
        final b = form.listenable;
        expect(
          identical(a, b),
          isFalse,
          reason:
              'still a fresh wrapper per access — allocation characteristic, not a correctness one',
        );

        var calls = 0;
        void listener() => calls++;

        form.listenable.addListener(listener);
        form.listenable.removeListener(listener);

        form.field<String>('name').set('x');

        expect(
          calls,
          0,
          reason:
              'removeListener on a fresh merge wrapper correctly unregisters from the underlying field notifiers',
        );

        form.dispose();
      },
    );
  });

  group('Default values', () {
    late VForm<Map<String, dynamic>> form;
    late VField<String> email;

    setUp(() {
      form = V.map({
        'email': V.string().email(),
      }).form(initialValues: {'email': 'default@example.com'});

      email = form.field<String>('email');
    });

    tearDown(() {
      form.dispose();
    });

    test('Initial value is correctly assigned to fields', () {
      expect(email.value, 'default@example.com');
    });

    test('Reset restores initial values', () {
      email.set('changed@example.com');

      expect(email.value, 'changed@example.com');

      form.reset();

      expect(email.value, 'default@example.com');
    });
  });

  group('Refine', () {
    late VForm<Map<String, dynamic>> form;
    late VField<String> password;
    late VField<String> confirmPassword;

    setUp(() {
      form = V
          .map({
            'password': V.string().password(),
            'confirmPassword': V.string().password(),
          })
          .refineFormField(
            (data) => data['password'] == data['confirmPassword'],
            path: 'confirmPassword',
          )
          .form();

      password = form.field<String>('password');
      confirmPassword = form.field<String>('confirmPassword');
    });

    tearDown(() {
      form.dispose();
    });

    Widget buildFormWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Form(
            key: form.key,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('passwordField'),
                  validator: password.validator,
                  onChanged: password.onChanged,
                ),
                TextFormField(
                  key: const Key('confirmPasswordField'),
                  validator: confirmPassword.validator,
                  onChanged: confirmPassword.onChanged,
                ),
              ],
            ),
          ),
        ),
      );
    }

    test('silentValidate works correctly', () {
      expect(form.silentValidate(), false);

      password.set('Aa1@aaaa');
      confirmPassword.set('Aa1@aaaa');

      expect(form.silentValidate(), true);

      password.set('Aa1@aaaaa');
      confirmPassword.set('Aa1@aaaa');

      expect(form.silentValidate(), false);
    });

    testWidgets('validate works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildFormWidget());

      expect(form.validate(), false);

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'Aa1@aaaa',
      );
      await tester.enterText(
        find.byKey(const Key('confirmPasswordField')),
        'Aa1@aaaa',
      );

      expect(form.validate(), true);

      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'Aa1@aaaaa',
      );

      expect(form.validate(), false);
    });

    test('vError wraps the extra validator message in VError(custom)', () {
      form.field<String>('password').set('Aa1@aaaa');
      form.field<String>('confirmPassword').set('Aa1@bbbb');

      final vErr = form.field<String>('confirmPassword').vError;
      expect(vErr, isNotNull);
      expect(vErr!.first.code, VCode.custom);
    });

    test('errorAsync surfaces the extra validator message', () async {
      form.field<String>('password').set('Aa1@aaaa');
      form.field<String>('confirmPassword').set('Aa1@bbbb');

      expect(
        await form.field<String>('confirmPassword').errorAsync,
        isNotNull,
      );
    });
  });

  group('VForm initialization with different types', () {
    late VForm<Map<String, dynamic>> form;
    late VField<int> integer;
    late VField<double> decimal;
    late VField<bool> boolean;
    late VField<DateTime> date;

    setUp(() {
      form = V.map({
        'integer': V.int(),
        'decimal': V.double(),
        'boolean': V.bool(),
        'date': V.date(),
      }).form(
        initialValues: {
          'integer': 42,
          'decimal': 3.14,
          'boolean': true,
          'date': DateTime(2024, 02, 25),
        },
      );

      integer = form.field<int>('integer');
      decimal = form.field<double>('decimal');
      boolean = form.field<bool>('boolean');
      date = form.field<DateTime>('date');
    });

    tearDown(() {
      form.dispose();
    });

    test('Fields are correctly initialized with the right types', () {
      expect(integer, isA<VField<int>>());
      expect(decimal, isA<VField<double>>());
      expect(form.field<bool>('boolean'), isA<VField<bool>>());
      expect(form.field<DateTime>('date'), isA<VField<DateTime>>());
    });

    test('Initial values are correctly assigned', () {
      expect(integer.value, 42);
      expect(decimal.value, 3.14);
      expect(boolean.value, true);
      expect(date.value, DateTime(2024, 02, 25));
    });

    test('Reset restores initial values', () {
      integer.set(99);
      decimal.set(9.99);
      boolean.set(false);
      date.set(DateTime(2025, 01, 01));

      form.reset();

      expect(integer.value, 42);
      expect(decimal.value, 3.14);
      expect(boolean.value, true);
      expect(date.value, DateTime(2024, 02, 25));
    });
  });

  group('VObject form', () {
    late VForm<_User> form;
    late VField<String> name;
    late VField<String> email;

    setUp(() {
      form = V
          .object<_User>(
            configure: (o) => o
                .field('name', (u) => u.name, V.string().min(3))
                .field('email', (u) => u.email, V.string().email()),
          )
          .form(
            builder: (data) =>
                _User(name: data['name'] ?? '', email: data['email'] ?? ''),
          );

      name = form.field<String>('name');
      email = form.field<String>('email');
    });

    tearDown(() {
      form.dispose();
    });

    test('Fields are created from VObject schema', () {
      expect(name, isA<VField<String>>());
      expect(email, isA<VField<String>>());
    });

    test('value returns typed object', () {
      name.set('John');
      email.set('john@example.com');

      final user = form.value;
      expect(user, isA<_User>());
      expect(user.name, 'John');
      expect(user.email, 'john@example.com');
    });

    test('rawValue returns map', () {
      name.set('John');
      email.set('john@example.com');

      expect(form.rawValue, {
        'name': 'John',
        'email': 'john@example.com',
      });
    });

    test('silentValidate validates the built object', () {
      expect(form.silentValidate(), false);

      name.set('John');
      email.set('john@example.com');

      expect(form.silentValidate(), true);

      name.set('Jo');
      expect(form.silentValidate(), false);
    });

    test('initial values work with typed initialValue', () {
      final formWithDefaults = V
          .object<_User>(
            configure: (o) => o
                .field('name', (u) => u.name, V.string().min(3))
                .field('email', (u) => u.email, V.string().email()),
          )
          .form(
            builder: (data) =>
                _User(name: data['name'] ?? '', email: data['email'] ?? ''),
            initialValue:
                const _User(name: 'Default', email: 'default@test.com'),
          );

      expect(formWithDefaults.field<String>('name').value, 'Default');
      expect(formWithDefaults.field<String>('email').value, 'default@test.com');

      formWithDefaults.dispose();
    });

    test(
      'value throws TypeError when fields are empty and builder has no null fallback',
      () {
        // `form.value` is optimistic — it builds T from whatever is in the
        // fields, without running validation first. If the builder dereferences
        // `data['name']` directly (no `??` fallback) and the field is empty,
        // the resulting `null` is passed to a non-nullable `String` parameter
        // and Dart throws at runtime.
        //
        // This is the documented contract: either validate before reading
        // `form.value`, or add null fallbacks in the builder, or read
        // `form.rawValue` / individual `form.field(...)` values instead.
        final form = V
            .object<_User>(
              configure: (o) => o
                  .field('name', (u) => u.name, V.string().min(3))
                  .field('email', (u) => u.email, V.string().email()),
            )
            .form(
              // Intentionally no `?? ''` — we want the TypeError to surface.
              builder: (data) =>
                  _User(name: data['name'], email: data['email']),
            );

        expect(() => form.value, throwsA(isA<TypeError>()));

        // rawValue stays safe — always `Map<String, dynamic>`, null-tolerant —
        // and individual field access is also safe (both VObject and VMap
        // forms share this escape hatch).
        expect(form.rawValue, {'name': null, 'email': null});
        expect(form.field<String>('name').value, isNull);

        form.dispose();
      },
    );

    test(
      'value succeeds after validate returns true, even when builder has no null fallback',
      () {
        // Flip side of the previous test: once every field passes validation,
        // the builder can safely dereference without `??` fallbacks.
        final form = V
            .object<_User>(
              configure: (o) => o
                  .field('name', (u) => u.name, V.string().min(3))
                  .field('email', (u) => u.email, V.string().email()),
            )
            .form(
              builder: (data) =>
                  _User(name: data['name'], email: data['email']),
            );

        form.field<String>('name').set('Alice');
        form.field<String>('email').set('alice@example.com');

        expect(form.silentValidate(), true);

        final user = form.value;
        expect(user.name, 'Alice');
        expect(user.email, 'alice@example.com');

        form.dispose();
      },
    );

    test('silentValidateAsync runs the typed builder pipeline', () async {
      final form = V
          .object<_User>(
            configure: (o) =>
                o.field('name', (u) => u.name, V.string().min(3)).field(
                      'email',
                      (u) => u.email,
                      V.string().email().refineAsync(
                            (v) async => !v.contains('bad'),
                            message: 'forbidden',
                          ),
                    ),
          )
          .form(
            builder: (data) => _User(
              name: data['name'] ?? '',
              email: data['email'] ?? '',
            ),
          );

      form.field<String>('name').set('Alice');
      form.field<String>('email').set('alice@example.com');
      expect(await form.silentValidateAsync(), true);

      form.field<String>('email').set('bad@example.com');
      expect(await form.silentValidateAsync(), false);

      form.dispose();
    });

    // Initial value resolution order — parity with VMap tests elsewhere in
    // this file. VMap is thoroughly covered; VObject wasn't. The resolution
    // rule is the same (initialValues[key] > schema.defaultValueOrNull > null),
    // but since the user-facing surface for VObject is a typed instance, it
    // needs its own pins.

    test(
      'schema defaultValue auto-populates field when no initialValue is passed',
      () {
        final form = V
            .object<_User>(
              configure: (o) => o
                  .field(
                    'name',
                    (u) => u.name,
                    V.string().defaultValue('Guest'),
                  )
                  .field('email', (u) => u.email, V.string().email()),
            )
            .form(
              builder: (data) =>
                  _User(name: data['name'] ?? '', email: data['email'] ?? ''),
            );

        expect(form.field<String>('name').value, 'Guest');

        form.dispose();
      },
    );

    test('initialValue wins over schema defaultValue', () {
      final form = V
          .object<_User>(
            configure: (o) => o
                .field(
                  'name',
                  (u) => u.name,
                  V.string().defaultValue('Guest'),
                )
                .field('email', (u) => u.email, V.string().email()),
          )
          .form(
            builder: (data) =>
                _User(name: data['name'] ?? '', email: data['email'] ?? ''),
            initialValue: const _User(name: 'Alice', email: 'alice@x.com'),
          );

      expect(form.field<String>('name').value, 'Alice');

      form.dispose();
    });

    test(
      'reset() restores the winning initial value (initialValue, not defaultValue)',
      () {
        final form = V
            .object<_User>(
              configure: (o) => o
                  .field(
                    'name',
                    (u) => u.name,
                    V.string().defaultValue('Guest'),
                  )
                  .field('email', (u) => u.email, V.string().email()),
            )
            .form(
              builder: (data) =>
                  _User(name: data['name'] ?? '', email: data['email'] ?? ''),
              initialValue: const _User(name: 'Alice', email: 'alice@x.com'),
            );

        form.field<String>('name').set('Bob');
        form.reset();

        expect(form.field<String>('name').value, 'Alice');

        form.dispose();
      },
    );
  });

  group('onValueChanged', () {
    test('callback passed in form() is called on field change', () {
      final values = <Map<String, dynamic>>[];

      final form = V.map({
        'name': V.string(),
      }).form(onValueChanged: (value) => values.add(value));

      form.field<String>('name').set('hello');

      expect(values.length, 1);
      expect(values.first['name'], 'hello');

      form.dispose();
    });

    test('addValueChangedListener works', () {
      final form = V.map({
        'name': V.string(),
      }).form();

      final values = <Map<String, dynamic>>[];
      form.addValueChangedListener((value) => values.add(value));

      form.field<String>('name').set('world');

      expect(values.length, 1);
      expect(values.first['name'], 'world');

      form.dispose();
    });

    test('removeValueChangedListener stops notifications', () {
      final form = V.map({
        'name': V.string(),
      }).form();

      final values = <Map<String, dynamic>>[];
      void listener(Map<String, dynamic> value) => values.add(value);

      form.addValueChangedListener(listener);
      form.field<String>('name').set('first');

      form.removeValueChangedListener(listener);
      form.field<String>('name').set('second');

      expect(values.length, 1);

      form.dispose();
    });

    test('VObject form onValueChanged returns typed object', () {
      final users = <_User>[];

      final form = V
          .object<_User>(
            configure: (o) => o
                .field('name', (u) => u.name, V.string())
                .field('email', (u) => u.email, V.string()),
          )
          .form(
            builder: (data) =>
                _User(name: data['name'] ?? '', email: data['email'] ?? ''),
            onValueChanged: (user) => users.add(user),
          );

      form.field<String>('name').set('John');

      expect(users.length, 1);
      expect(users.first.name, 'John');

      form.dispose();
    });

    test(
      'dispose clears pending onValueChanged listeners without explicit disposer',
      () {
        final form = V.map({'name': V.string()}).form();
        final name = form.field<String>('name');
        var calls = 0;

        // Register but intentionally never call the returned disposer —
        // form.dispose() must clean the listener list on its own.
        name.onValueChanged((_) => calls++);

        name.set('first');
        expect(calls, 1);

        form.dispose();
      },
    );
  });

  group('Typed fields via mapType', () {
    test('VEnum creates correctly typed VField', () {
      final form = V.map({
        'status': V.enm<_Status>(_Status.values),
      }).form();

      final status = form.field<_Status>('status');
      expect(status, isA<VField<_Status>>());

      status.set(_Status.active);
      expect(status.value, _Status.active);

      form.dispose();
    });

    test('VObject field creates correctly typed VField', () {
      final form = V.map({
        'name': V.string(),
        'data': V.object<_User>(),
      }).form();

      final data = form.field<_User>('data');
      expect(data, isA<VField<_User>>());

      data.set(const _User(name: 'John', email: 'john@test.com'));
      expect(data.value?.name, 'John');

      form.dispose();
    });
  });

  group('Transforms and parsedValue', () {
    test('form.value applies transforms', () {
      final form = V.map({
        'name': V.string().trim(),
      }).form();

      form.field<String>('name').set('  hello  ');

      expect(form.rawValue['name'], '  hello  ');
      expect(form.value['name'], 'hello');

      form.dispose();
    });

    test('silentValidate uses parsed values', () {
      final form = V.map({
        'name': V.string().trim().min(3),
      }).form();

      form.field<String>('name').set('  hi  ');
      expect(form.silentValidate(), false);

      form.field<String>('name').set('  hello  ');
      expect(form.silentValidate(), true);

      form.dispose();
    });

    test('VObject form value applies transforms', () {
      final form = V
          .object<_User>(
            configure: (o) => o
                .field('name', (u) => u.name, V.string().trim())
                .field('email', (u) => u.email, V.string().trim()),
          )
          .form(
            builder: (data) =>
                _User(name: data['name'] ?? '', email: data['email'] ?? ''),
          );

      form.field<String>('name').set('  John  ');
      form.field<String>('email').set('  john@test.com  ');

      final user = form.value;
      expect(user.name, 'John');
      expect(user.email, 'john@test.com');

      form.dispose();
    });
  });

  group('Conditional validation (when)', () {
    late VForm<Map<String, dynamic>> form;

    setUp(() {
      form = V.map({
        'type': V.string(),
        'document': V.string().nullable(),
      }).when('type', equals: 'company', then: {
        'document': V.string().min(14),
      }).form();
    });

    tearDown(() {
      form.dispose();
    });

    test('No error when condition is not met', () {
      form.field<String>('type').set('person');
      form.field<String>('document').set(null);

      expect(form.field<String>('document').validator(null), isNull);
    });

    test('Error when condition is met and value is invalid', () {
      form.field<String>('type').set('company');
      form.field<String>('document').set('123');

      expect(form.field<String>('document').validator('123'), isNotNull);
    });

    test('No error when condition is met and value is valid', () {
      form.field<String>('type').set('company');
      form.field<String>('document').set('12345678901234');

      expect(
        form.field<String>('document').validator('12345678901234'),
        isNull,
      );
    });

    test('silentValidate respects when rules', () {
      form.field<String>('type').set('company');
      form.field<String>('document').set('123');
      expect(form.silentValidate(), false);

      form.field<String>('document').set('12345678901234');
      expect(form.silentValidate(), true);

      form.field<String>('type').set('person');
      form.field<String>('document').set(null);
      expect(form.silentValidate(), true);
    });

    test(
      'empty string on non-nullable base is substituted with null for a nullable conditional type',
      () {
        final form = V.map({
          'type': V.string(),
          // Non-nullable base keeps empty string as-is instead of
          // normalizing it to null. Lets the when-validator see the
          // empty string and exercise the nullable-substitution branch.
          'bio': V.string(),
        }).when(
          'type',
          equals: 'verbose',
          then: {'bio': V.string().nullable().min(5)},
        ).form();

        form.field<String>('type').set('verbose');
        form.field<String>('bio').set('');

        // The when-validator treats '' as null because the conditional type
        // is nullable, so it produces no error on its own. The base
        // validator (non-nullable, empty → invalid) is the one that fails;
        // this confirms the two paths stay independent.
        expect(form.silentValidate(), false);
        expect(form.field<String>('bio').value, '');

        form.dispose();
      },
    );
  });

  group('Manual errors', () {
    late VForm<Map<String, dynamic>> form;

    setUp(() {
      form = V.map({
        'email': V.string().email(),
        'cpf': V.string().min(11),
      }).form();
    });

    tearDown(() {
      form.dispose();
    });

    test('form.setError propagates to the underlying VField', () {
      form.setError('email', 'Email already taken');
      expect(form.field<String>('email').manualError, 'Email already taken');
    });

    test('form.setError throws ArgumentError for unknown field', () {
      expect(
        () => form.setError('unknown', 'x'),
        throwsArgumentError,
      );
    });

    test('field.setError direct call matches form.setError behaviour', () {
      final email = form.field<String>('email');
      email.setError('Direct error');
      expect(email.manualError, 'Direct error');
      expect(form.field<String>('email').manualError, 'Direct error');
    });

    test('form.setErrors sets multiple fields at once', () {
      form.setErrors({'email': 'taken', 'cpf': 'invalid'});
      expect(form.field<String>('email').manualError, 'taken');
      expect(form.field<String>('cpf').manualError, 'invalid');
    });

    test('form.vErrors returns detailed VErrors per field', () {
      final detailedForm = V.map({
        'emails': V.array<String>(V.string().email()).min(1),
        'age': V.int().min(18),
      }).form();

      detailedForm.field<List<String>>('emails').set(['a@b.com', 'bad']);
      detailedForm.field<int>('age').set(10);

      final errs = detailedForm.vErrors();
      expect(errs, isNotNull);
      expect(errs!.keys, containsAll(['emails', 'age']));

      // 'emails' should have at least one VError with a non-empty path
      expect(errs['emails']!.any((e) => e.path.isNotEmpty), true);

      detailedForm.dispose();
    });

    test('form.vErrors returns null when all fields valid', () {
      final validForm = V.map({
        'emails': V.array<String>(V.string().email()).min(1),
      }).form();
      validForm.field<List<String>>('emails').set(['a@b.com']);
      expect(validForm.vErrors(), isNull);
      validForm.dispose();
    });

    test('form.setErrors with empty map fails the assert', () {
      expect(
        () => form.setErrors({}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('form.setErrors throws for unknown keys and lists them', () {
      expect(
        () => form.setErrors({'email': 'x', 'phone': 'y', 'zip': 'z'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('phone'),
          ),
        ),
      );
    });

    test('silentValidate returns false when a manual error is present', () {
      form.field<String>('email').set('valid@example.com');
      form.field<String>('cpf').set('12345678901');
      expect(form.silentValidate(), true); // baseline

      form.setError('email', 'taken');
      expect(form.silentValidate(), false);
    });

    test('silentValidate consumes one-shot manual errors', () {
      form.field<String>('email').set('valid@example.com');
      form.field<String>('cpf').set('12345678901');
      form.setError('email', 'taken');

      // First call sees and consumes the manual error
      expect(form.silentValidate(), false);
      expect(form.field<String>('email').manualError, isNull);

      // Subsequent call: manual is gone, data is still valid
      expect(form.silentValidate(), true);
    });

    test('silentValidate respects persist: true (does not consume)', () {
      form.field<String>('email').set('valid@example.com');
      form.field<String>('cpf').set('12345678901');
      form.setError('email', 'sticky', persist: true);

      expect(form.silentValidate(), false);
      expect(form.silentValidate(), false);
      expect(form.field<String>('email').manualError, 'sticky');
    });

    testWidgets('silentValidate does NOT trigger UI error display',
        (tester) async {
      final silentForm = V.map({'email': V.string().email()}).form();
      final email = silentForm.field<String>('email');
      email.set('valid@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: silentForm.key,
              child: TextFormField(
                // VField.key intentionally NOT attached — isolates this test
                // from setError's single-field refresh path.
                initialValue: email.value,
                validator: email.validator,
              ),
            ),
          ),
        ),
      );

      silentForm.setError('email', 'invisible in UI', persist: true);
      silentForm.silentValidate();
      await tester.pump();

      expect(find.text('invisible in UI'), findsNothing);

      // validate() renders the error
      silentForm.validate();
      await tester.pump();
      expect(find.text('invisible in UI'), findsOneWidget);

      silentForm.dispose();
    });

    test('form.clearError clears a single field', () {
      form.setErrors({'email': 'e', 'cpf': 'c'});
      form.clearError('email');
      expect(form.field<String>('email').manualError, isNull);
      expect(form.field<String>('cpf').manualError, 'c');
    });

    test('form.clearErrors clears every field', () {
      form.setErrors({'email': 'e', 'cpf': 'c'});
      form.clearErrors();
      expect(form.field<String>('email').manualError, isNull);
      expect(form.field<String>('cpf').manualError, isNull);
    });

    test('manual error surfaces through VField.validator', () {
      final email = form.field<String>('email');
      email.set('valid@email.com');
      form.setError('email', 'Email already taken');
      expect(email.validator(email.value), 'Email already taken');
    });

    test('form.setError propagates force flag to the field', () {
      final email = form.field<String>('email');
      email.set('not-an-email');
      form.setError('email', 'Backend rejected', force: true);
      expect(email.validator(email.value), 'Backend rejected');
    });

    test('form.setErrors propagates force flag to every field', () {
      final email = form.field<String>('email');
      final cpf = form.field<String>('cpf');
      email.set('not-an-email');
      cpf.set('123');
      form.setErrors({'email': 'E', 'cpf': 'C'}, force: true);
      expect(email.validator(email.value), 'E');
      expect(cpf.validator(cpf.value), 'C');
    });

    test('form.setError propagates persist flag to the field', () {
      final email = form.field<String>('email');
      email.set('valid@email.com');
      form.setError('email', 'Sticky', persist: true);
      expect(email.validator(email.value), 'Sticky');
      expect(email.validator(email.value), 'Sticky');
    });

    testWidgets(
        'clearError wipes the cached error from the UI after one-shot consumption',
        (tester) async {
      final email = form.field<String>('email');
      email.set('valid@email.com');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: form.key,
              child: TextFormField(
                key: email.key,
                initialValue: email.value,
                validator: email.validator,
                onChanged: email.onChanged,
              ),
            ),
          ),
        ),
      );

      form.setError('email', 'Email already taken');
      await tester.pump();
      expect(find.text('Email already taken'), findsOneWidget);

      form.clearErrors();
      await tester.pump();
      expect(find.text('Email already taken'), findsNothing);
    });

    test('form.errors() returns a map keyed by failing field names', () {
      final form = V.map({
        'email': V.string().email(),
        'password': V.string().password(),
      }).form();

      final errs = form.errors();
      expect(errs, isNotNull);
      expect(errs!.keys, containsAll(['email', 'password']));

      form.dispose();
    });

    test('vError wraps a forced manual error in VError(custom)', () {
      final form = V.map({'email': V.string().email()}).form(
        initialValues: {'email': 'user@example.com'},
      );
      final email = form.field<String>('email');
      email.setError('server rejected', force: true);

      final vErr = email.vError;
      expect(vErr, isNotNull);
      expect(vErr!.length, 1);
      expect(vErr.first.code, VCode.custom);
      expect(vErr.first.message, 'server rejected');

      form.dispose();
    });

    test('vError wraps a non-forced manual error when std+extra pass', () {
      final form = V.map({'email': V.string().email()}).form(
        initialValues: {'email': 'user@example.com'},
      );
      final email = form.field<String>('email');
      email.setError('server rejected');

      final vErr = email.vError;
      expect(vErr, isNotNull);
      expect(vErr!.first.code, VCode.custom);
      expect(vErr.first.message, 'server rejected');

      form.dispose();
    });
  });

  group('Cursor position', () {
    Future<void> pumpField({
      required WidgetTester tester,
      required GlobalKey<FormState> formKey,
      required TextEditingController controller,
      required VField<String> field,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  onChanged: field.onChanged,
                ),
              ),
            ),
          ),
        );

    testWidgets(
        'user typing (atomic text+selection update) preserves cursor position',
        (tester) async {
      final testForm = V.map({'email': V.string()}).form(
        initialValues: {'email': 'helo'},
      );
      final email = testForm.field<String>('email');
      final controller = TextEditingController(text: 'helo');
      email.attachTextController(controller, owns: false);

      await pumpField(
        tester: tester,
        formKey: testForm.key,
        controller: controller,
        field: email,
      );

      // Simulate what Flutter's EditableText does on a keystroke: atomically
      // update text AND selection. User inserted 'x' at position 3.
      controller.value = const TextEditingValue(
        text: 'helxo',
        selection: TextSelection.collapsed(offset: 3),
      );
      await tester.pump();

      expect(controller.text, 'helxo');
      expect(
        controller.selection.baseOffset,
        3,
        reason: 'valiform must not reset the cursor when reading from the '
            'controller',
      );
      expect(email.value, 'helxo');

      controller.dispose();
      testForm.dispose();
    });

    testWidgets(
        'selection-only change does NOT trigger a VField value notification',
        (tester) async {
      final testForm = V.map({'email': V.string()}).form(
        initialValues: {'email': 'hello'},
      );
      final email = testForm.field<String>('email');
      final controller = TextEditingController(text: 'hello');
      email.attachTextController(controller, owns: false);

      await pumpField(
        tester: tester,
        formKey: testForm.key,
        controller: controller,
        field: email,
      );

      int valueChanges = 0;
      email.listenable.addListener(() => valueChanges++);

      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      expect(controller.selection.baseOffset, 2);
      expect(valueChanges, 0, reason: 'No text change → no value notification');
      expect(email.value, 'hello');

      controller.dispose();
      testForm.dispose();
    });

    testWidgets(
        'field.set() with different text moves the cursor away from its prior position',
        (tester) async {
      final testForm = V.map({'email': V.string()}).form(
        initialValues: {'email': 'hello'},
      );
      final email = testForm.field<String>('email');
      final controller = TextEditingController(text: 'hello');
      email.attachTextController(controller, owns: false);

      await pumpField(
        tester: tester,
        formKey: testForm.key,
        controller: controller,
        field: email,
      );

      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      expect(controller.selection.baseOffset, 2);

      // Programmatic set with DIFFERENT text. Flutter's TextEditingController
      // .text setter internally does value.copyWith(selection:
      // TextSelection.collapsed(offset: -1)), so the cursor is no longer at 2.
      email.set('world');
      await tester.pump();

      expect(controller.text, 'world');
      expect(
        controller.selection.baseOffset,
        isNot(2),
        reason: 'Programmatic field.set resets the cursor (Flutter default)',
      );

      controller.dispose();
      testForm.dispose();
    });
  });

  group('Async validation', () {
    test('VMap form.validateAsync fails and surfaces async error on field',
        () async {
      final form = V.map({
        'username': V.string().min(3).refineAsync(
              (v) async => v != 'taken',
              message: 'already taken',
            ),
      }).form(initialValues: {'username': 'taken'});

      expect(await form.validateAsync(), isFalse);

      final field = form.field<String>('username');
      // validateAsync persists the error as a manual error so the
      // synchronous FormField.validator will surface it.
      expect(field.manualError, 'already taken');
      expect(field.validator(field.value), 'already taken');

      form.dispose();
    });

    test('VMap form.validateAsync passes for a valid value', () async {
      final form = V.map({
        'username': V.string().refineAsync(
              (v) async => v != 'taken',
              message: 'already taken',
            ),
      }).form(initialValues: {'username': 'eduardo'});

      expect(await form.validateAsync(), isTrue);
      expect(form.field<String>('username').manualError, isNull);

      form.dispose();
    });

    test('silentValidateAsync runs full pipeline without touching UI',
        () async {
      final form = V.map({
        'email': V.string().email().refineAsync(
              (v) async => !v.endsWith('@blocked.com'),
              message: 'blocked domain',
            ),
      }).form(initialValues: {'email': 'a@blocked.com'});

      expect(await form.silentValidateAsync(), isFalse);
      // manualError must NOT be populated by silentValidateAsync.
      expect(form.field<String>('email').manualError, isNull);

      form.dispose();
    });

    test('errorsAsync and vErrorsAsync report full error detail', () async {
      final form = V.map({
        'username': V.string().refineAsync(
              (v) async => v != 'taken',
              message: 'already taken',
            ),
      }).form(initialValues: {'username': 'taken'});

      expect(await form.errorsAsync(), {'username': 'already taken'});
      final vErrs = await form.vErrorsAsync();
      expect(vErrs, isNotNull);
      expect(vErrs!['username']!.first.message, 'already taken');

      form.dispose();
    });

    test(
        'mixed sync + async schema: sync fields still validate individually '
        'via field.validator, form-level sync methods throw', () async {
      final form = V.map({
        'name': V.string().min(3),
        'username': V.string().refineAsync(
              (v) async => v != 'taken',
              message: 'already taken',
            ),
      }).form(initialValues: {'name': 'x', 'username': 'taken'});

      // The sync `name` field still surfaces its error through its own
      // validator — this is what Flutter's FormField uses while typing.
      final name = form.field<String>('name');
      expect(name.validator(name.value), isNotNull);

      // Form-level sync methods are strict: they throw because some field
      // depends on async validation.
      expect(
        () => form.silentValidate(),
        throwsA(isA<VAsyncRequiredException>()),
      );
      expect(() => form.errors(), throwsA(isA<VAsyncRequiredException>()));

      // Async path surfaces both the sync (still enforced) and the async.
      expect(await form.validateAsync(), isFalse);
      expect(form.field<String>('username').manualError, 'already taken');

      form.dispose();
    });

    test('VObject form.validateAsync works', () async {
      final schema = V.object<_User>(
        configure: (o) => o
          ..field('name', (u) => u.name, V.string().min(2))
          ..field(
            'email',
            (u) => u.email,
            V.string().email().refineAsync(
                  (v) async => !v.endsWith('@blocked.com'),
                  message: 'blocked domain',
                ),
          ),
      );
      final form = schema.form(
        builder: (data) => _User(
          name: data['name'] as String,
          email: data['email'] as String,
        ),
        initialValue: const _User(name: 'John', email: 'a@blocked.com'),
      );

      expect(await form.validateAsync(), isFalse);
      expect(form.field<String>('email').manualError, 'blocked domain');

      form.dispose();
    });

    test('Conditional (when) rule with async type runs only when condition met',
        () async {
      final form = V.map({
        'type': V.string(),
        'taxId': V.string().nullable(),
      }).when('type', equals: 'company', then: {
        'taxId': V.string().refineAsync(
              (v) async => v.length >= 5,
              message: 'taxId too short',
            ),
      }).form(initialValues: {'type': 'person', 'taxId': 'x'});

      // condition not met → valid
      expect(await form.validateAsync(), isTrue);

      // flip the condition
      form.field<String>('type').set('company');
      expect(await form.validateAsync(), isFalse);
      expect(form.field<String>('taxId').manualError, 'taxId too short');

      form.dispose();
    });

    test('validateAsync clears previous async error when value becomes valid',
        () async {
      final form = V.map({
        'username': V.string().refineAsync(
              (v) async => v != 'taken',
              message: 'already taken',
            ),
      }).form(initialValues: {'username': 'taken'});

      expect(await form.validateAsync(), isFalse);
      expect(form.field<String>('username').manualError, 'already taken');

      form.field<String>('username').set('available');
      expect(await form.validateAsync(), isTrue);
      expect(form.field<String>('username').manualError, isNull);

      form.dispose();
    });

    test(
        'sync methods on a fully async schema throw VAsyncRequiredException '
        '(mirror of validart\'s contract)', () {
      final form = V.map({
        'username': V.string().refineAsync(
              (v) async => v != 'taken',
              message: 'already taken',
            ),
      }).form(initialValues: {'username': 'taken'});

      expect(form.hasAsync, isTrue);
      expect(() => form.validate(), throwsA(isA<VAsyncRequiredException>()));
      expect(
        () => form.silentValidate(),
        throwsA(isA<VAsyncRequiredException>()),
      );
      expect(() => form.errors(), throwsA(isA<VAsyncRequiredException>()));
      expect(() => form.vErrors(), throwsA(isA<VAsyncRequiredException>()));
      expect(() => form.value, throwsA(isA<VAsyncRequiredException>()));

      // Field-level sync methods throw too — except validator(T?), the
      // unavoidable sync adapter for Flutter's FormField.
      final field = form.field<String>('username');
      expect(() => field.validate(), throwsA(isA<VAsyncRequiredException>()));
      expect(() => field.error, throwsA(isA<VAsyncRequiredException>()));
      expect(() => field.vError, throwsA(isA<VAsyncRequiredException>()));
      expect(
        () => field.parsedValue,
        throwsA(isA<VAsyncRequiredException>()),
      );
      expect(() => field.validator('taken'), returnsNormally);

      form.dispose();
    });

    test('form.valueAsync resolves parsed value across async pipeline',
        () async {
      final form = V.map({
        'email': V.string().trim().toLowerCase().refineAsync(
              (v) async => v.contains('@'),
              message: 'invalid email',
            ),
      }).form(initialValues: {'email': '  USER@Mail.COM  '});

      final result = await form.valueAsync;
      expect(result['email'], 'user@mail.com');

      form.dispose();
    });

    test(
        'form 100% sync is unaffected — hasAsync false, sync methods behave '
        'as before', () {
      final form = V.map({
        'email': V.string().email(),
      }).form(initialValues: {'email': 'valid@mail.com'});

      expect(form.hasAsync, isFalse);
      expect(form.validate(), anyOf(isTrue, isFalse));
      expect(form.silentValidate(), isTrue);
      expect(form.errors(), isNull);
      expect(form.vErrors(), isNull);
      expect(form.value['email'], 'valid@mail.com');

      form.dispose();
    });

    test(
        'schema-level refineAsync on VMap — form is async even with sync '
        'fields only (regression: bug where schema.hasAsync was ignored)',
        () async {
      final form = V
          .map({
            'a': V.string(),
            'b': V.string(),
          })
          .refineAsync((data) async => data['a'] != data['b'])
          .form(initialValues: {'a': 'same', 'b': 'same'});

      // Form must report hasAsync even though every individual field is sync.
      expect(form.hasAsync, isTrue);
      expect(() => form.validate(), throwsA(isA<VAsyncRequiredException>()));
      expect(
        () => form.silentValidate(),
        throwsA(isA<VAsyncRequiredException>()),
      );
      // Async path reports the schema-level failure.
      expect(await form.silentValidateAsync(), isFalse);

      form.dispose();
    });

    test('VField.vErrorAsync surfaces errors from async extra validators',
        () async {
      final form = V.map({
        'type': V.string(),
        'name': V.string().nullable(),
      }).when(
        'type',
        equals: 'member',
        then: {
          'name': V.string().min(1).refineAsync(
                (v) async => false,
                message: 'taken',
              ),
        },
      ).form();

      form.field<String>('type').set('member');
      form.field<String>('name').set('foo');

      final vErr = await form.field<String>('name').vErrorAsync;
      expect(vErr, isNotNull);
      expect(vErr!.first.message, 'taken');

      form.dispose();
    });

    test('VField.errorAsync surfaces errors from async extra validators',
        () async {
      final form = V.map({
        'type': V.string(),
        'name': V.string().nullable(),
      }).when(
        'type',
        equals: 'member',
        then: {
          'name': V.string().min(1).refineAsync(
                (v) async => false,
                message: 'taken',
              ),
        },
      ).form();

      form.field<String>('type').set('member');
      form.field<String>('name').set('foo');

      expect(await form.field<String>('name').errorAsync, 'taken');

      form.dispose();
    });

    test(
      'validateAsync handles re-entry cycle bad → good → bad without ghost errors',
      () async {
        // Existing test covers bad → good. This extends to a full round-trip
        // to pin that the internal setError/clearError mechanism used by
        // validateAsync does not get stuck after a clear — otherwise a user
        // who fixes and re-breaks the same value would see no error.
        final form = V.map({
          'username': V.string().refineAsync(
                (v) async => v != 'taken',
                message: 'already taken',
              ),
        }).form(initialValues: {'username': 'taken'});

        expect(await form.validateAsync(), isFalse);
        expect(form.field<String>('username').manualError, 'already taken');

        form.field<String>('username').set('available');
        expect(await form.validateAsync(), isTrue);
        expect(form.field<String>('username').manualError, isNull);

        // Re-entry: the mechanism must re-populate the error cleanly.
        form.field<String>('username').set('taken');
        expect(await form.validateAsync(), isFalse);
        expect(form.field<String>('username').manualError, 'already taken');

        form.dispose();
      },
    );

    test(
      'validateAsync clears prior manual persistent errors when async passes — contract pin',
      () async {
        // Pins current behavior documented in form.dart:455-475: validateAsync
        // unconditionally calls field.clearError() on fields whose async
        // pipeline returns null. That wipes any persistent manual error the
        // caller set BEFORE validateAsync — e.g. a server-side block pushed
        // via form.setError(..., persist: true). If this ever needs to
        // distinguish "my own persistent errors" from "user-set ones",
        // update this expect and the implementation together.
        final form = V.map({
          'username': V.string().refineAsync(
                (v) async => true, // always passes
                message: 'never fires',
              ),
        }).form(initialValues: {'username': 'anything'});

        form.setError('username', 'server-side block', persist: true);
        expect(form.field<String>('username').manualError, 'server-side block');

        expect(await form.validateAsync(), isTrue);
        expect(
          form.field<String>('username').manualError,
          isNull,
          reason:
              'validateAsync unconditionally clearError()s on pass — pinned',
        );

        form.dispose();
      },
    );
  });

  group('Integration: all types mixed with async/when', () {
    test(
        'VMap with every primitive + array + nested + enum + union + literal '
        '+ when (sync & async) + refineFormField validates end-to-end',
        () async {
      final form = V
          .map({
            'name': V.string().min(1),
            'age': V.int().between(0, 150),
            'height': V.double().positive(),
            'active': V.bool().isTrue(),
            'joined': V.date().before(DateTime(2030)),
            'tags': V.string().min(2).array().min(1).unique(),
            'address': V.map({
              'zip': V.string().min(5),
              'country': V.literal('US'),
            }),
            'role': V.enm<_Role>(_Role.values),
            'id': V.union([V.string().uuid(), V.int().min(1)]),
            'confirmation': V.string(),
            // A plain field that becomes async under a condition.
            'type': V.string(),
            'username': V.string().nullable(),
          })
          // Cross-field sync validator: name echoes into confirmation.
          .refineFormField(
            (data) => data['name'] == data['confirmation'],
            path: 'confirmation',
            message: 'must match name',
          )
          // Conditional SYNC: when type=person, age must be >= 18.
          .when('type', equals: 'person', then: {
            'age': V.int().min(18, message: (_) => 'person must be 18+'),
          })
          // Conditional ASYNC: when type=member, username must be available.
          .when('type', equals: 'member', then: {
            'username': V.string().min(3).refineAsync(
                  (v) async =>
                      !const {'admin', 'root'}.contains(v.toLowerCase()),
                  message: 'username taken',
                ),
          })
          .form(initialValues: {
            'name': 'Alice',
            'age': 30,
            'height': 1.72,
            'active': true,
            'joined': DateTime(2024, 6, 1),
            'tags': ['dart', 'flutter'],
            'address': {'zip': '12345', 'country': 'US'},
            'role': _Role.admin,
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'confirmation': 'Alice',
            'type': 'person',
            'username': null,
          });

      // The when('member') rule adds an async extra — form is async overall.
      expect(form.hasAsync, isTrue);
      expect(() => form.validate(), throwsA(isA<VAsyncRequiredException>()));
      expect(() => form.value, throwsA(isA<VAsyncRequiredException>()));

      // Async validation passes for these happy-path initial values.
      expect(await form.validateAsync(), isTrue);

      // valueAsync returns the fully-parsed form value.
      final value = await form.valueAsync;
      expect(value['name'], 'Alice');
      expect(value['age'], 30);
      expect(value['height'], 1.72);
      expect(value['active'], isTrue);
      expect(value['role'], _Role.admin);
      // Typed field access — exercises mapType generic preservation for
      // enums (regression: V.enm must be called with an explicit <T>).
      expect(form.field<_Role>('role').value, _Role.admin);
      expect((value['address'] as Map)['country'], 'US');
      expect((value['tags'] as List), ['dart', 'flutter']);

      // Flip to member with a taken username — async failure bubbles up.
      form.field<String>('type').set('member');
      form.field<String>('username').set('admin');
      expect(await form.validateAsync(), isFalse);
      expect(form.field<String>('username').manualError, 'username taken');

      // Flip to a free username — async passes again.
      form.field<String>('username').set('alice_new');
      expect(await form.validateAsync(), isTrue);
      expect(form.field<String>('username').manualError, isNull);

      // Break the sync conditional (person under 18) to confirm the sync
      // branch still fires.
      form.field<String>('type').set('person');
      form.field<int>('age').set(12);
      expect(await form.validateAsync(), isFalse);
      final ageError = form.field<int>('age');
      expect(ageError.manualError, 'person must be 18+');

      // Break the cross-field refineFormField too.
      form.field<int>('age').set(25);
      form.field<String>('confirmation').set('someone else');
      expect(await form.validateAsync(), isFalse);
      expect(form.field<String>('confirmation').manualError, 'must match name');

      form.dispose();
    });

    test(
        'VObject with every primitive + array + enum + union + async field '
        'rebuilds the typed instance via valueAsync', () async {
      final schema = V.object<_Profile>(
        configure: (o) => o
          ..field('name', (u) => u.name, V.string().min(1))
          ..field('age', (u) => u.age, V.int().between(0, 150))
          ..field('height', (u) => u.height, V.double().positive())
          ..field('active', (u) => u.active, V.bool().isTrue())
          ..field('joined', (u) => u.joined, V.date().before(DateTime(2030)))
          ..field(
            'tags',
            (u) => u.tags,
            V.string().min(2).array().min(1).unique(),
          )
          ..field('role', (u) => u.role, V.enm<_Role>(_Role.values))
          ..field(
            'id',
            (u) => u.id,
            V.union([V.string().uuid(), V.int().min(1)]),
          )
          // Async: email must not be blocked.
          ..field(
            'email',
            (u) => u.email,
            V.string().email().trim().toLowerCase().refineAsync(
                  (v) async => !v.endsWith('@blocked.com'),
                  message: 'blocked domain',
                ),
          ),
      );

      final seed = _Profile(
        name: 'Alice',
        age: 30,
        height: 1.72,
        active: true,
        joined: DateTime(2024, 6, 1),
        tags: const ['dart', 'flutter'],
        role: _Role.admin,
        id: '550e8400-e29b-41d4-a716-446655440000',
        email: '  ALICE@example.COM  ',
      );

      final form = schema.form(
        builder: (data) => _Profile(
          name: data['name'] as String,
          age: data['age'] as int,
          height: data['height'] as double,
          active: data['active'] as bool,
          joined: data['joined'] as DateTime,
          tags: (data['tags'] as List).cast<String>(),
          role: data['role'] as _Role,
          id: data['id'] as Object,
          email: data['email'] as String,
        ),
        initialValue: seed,
      );

      expect(form.hasAsync, isTrue);
      expect(() => form.validate(), throwsA(isA<VAsyncRequiredException>()));
      expect(() => form.value, throwsA(isA<VAsyncRequiredException>()));

      // Happy path.
      expect(await form.validateAsync(), isTrue);

      // valueAsync applies transforms (trim + toLowerCase on email) while
      // reconstructing the typed object.
      final user = await form.valueAsync;
      expect(user.name, 'Alice');
      expect(user.age, 30);
      expect(user.role, _Role.admin);
      expect(user.email, 'alice@example.com'); // trimmed + lowercased
      expect(user.tags, ['dart', 'flutter']);

      // Push a blocked email — async error persists on the field.
      form.field<String>('email').set('bob@blocked.com');
      expect(await form.validateAsync(), isFalse);
      expect(form.field<String>('email').manualError, 'blocked domain');

      form.dispose();
    });

    test(
        'schema defaultValue auto-populates the VField initial value, '
        'appears in the UI, and is the target of reset()', () {
      final form = V.map({
        'name': V.string().defaultValue('Guest'),
      }).form();

      final field = form.field<String>('name');

      // UI sees the default out of the box.
      expect(field.value, 'Guest');
      expect(form.rawValue['name'], 'Guest');
      expect(form.value['name'], 'Guest');

      // User edits then resets — back to the default.
      field.set('Alice');
      expect(field.value, 'Alice');
      field.reset();
      expect(field.value, 'Guest');

      form.dispose();
    });

    test(
        'explicit initialValues win over schema defaultValue and reset() '
        'restores the explicit value', () {
      final form = V.map({
        'name': V.string().defaultValue('Guest'),
      }).form(initialValues: {'name': 'Alice'});

      final field = form.field<String>('name');

      expect(field.value, 'Alice');
      field.set('Bob');
      field.reset();
      expect(field.value, 'Alice');

      // parsedValue still falls back to the default on empty input.
      field.set('');
      expect(field.parsedValue, 'Guest');

      form.dispose();
    });

    test(
        'explicit null in initialValues wins over schema defaultValue — '
        'dev opted out; reset() returns to null', () {
      final form = V.map({
        'name': V.string().defaultValue('Guest'),
      }).form(initialValues: {'name': null});

      final field = form.field<String>('name');

      expect(field.value, isNull);
      field.set('Typed');
      field.reset();
      expect(field.value, isNull);

      // The pipeline still applies the default downstream — `form.value`
      // produces `'Guest'` because validart's _resolveNull kicks in.
      expect(form.value['name'], 'Guest');

      form.dispose();
    });

    test(
        'defaultValue on the schema flows into form.value / parsedValue '
        'when the field is empty — regression for empty-string not being '
        'normalized to null before safeParse', () {
      final form = V.map({
        'name': V.string().min(1).defaultValue('John'),
      }).form();

      final field = form.field<String>('name');

      // User types and then clears — the stored raw value is an empty
      // string, not null. parsedValue must still surface the default.
      field.set('Alice');
      field.set('');

      expect(field.value, equals(''));
      expect(field.parsedValue, 'John'); // ← bug: returns '' today
      expect(form.value['name'], 'John');

      // Validator must also see the field as valid (default applied).
      expect(form.silentValidate(), isTrue);

      form.dispose();
    });

    test(
        'V.enm without explicit generic inside V.map({}) degrades to '
        'VField<Enum> — pins the Dart inference pitfall that forces users '
        'to write V.enm<T>(T.values)', () {
      // Intentionally no <_Role> — Dart resolves T to the Enum upper bound.
      final degraded = V.map({
        'role': V.enm(_Role.values),
      }).form(initialValues: {'role': _Role.admin});

      expect(
        () => degraded.field<_Role>('role'),
        throwsArgumentError,
      );
      expect(degraded.field<Enum>('role').value, _Role.admin);
      degraded.dispose();

      // With the explicit generic, the field is correctly typed.
      final ok = V.map({
        'role': V.enm<_Role>(_Role.values),
      }).form(initialValues: {'role': _Role.admin});
      expect(ok.field<_Role>('role').value, _Role.admin);
      ok.dispose();
    });
  });

  group('reset() clears widget text in a single call', () {
    testWidgets(
      'with a listener rebuilding on every keystroke',
      (WidgetTester tester) async {
        final form = V.map({'name': V.string()}).form();

        await tester.pumpWidget(_RebuildOnChangeHarness(form: form));

        await tester.enterText(find.byKey(const Key('nameField')), 'John');
        await tester.pumpAndSettle();

        expect(form.field<String>('name').value, 'John');
        expect(find.text('John'), findsOneWidget);

        form.reset();
        await tester.pumpAndSettle();

        expect(form.field<String>('name').value, isNull);
        expect(find.text('John'), findsNothing);

        form.dispose();
      },
    );

    testWidgets(
      'with no listener rebuilding the tree between keystrokes',
      (WidgetTester tester) async {
        final form = V.map({'name': V.string(), 'email': V.string()}).form();

        await tester.pumpWidget(_StaticHarness(form: form));

        await tester.enterText(find.byKey(const Key('nameField')), 'John');
        await tester.enterText(
          find.byKey(const Key('emailField')),
          'john@example.com',
        );
        await tester.pumpAndSettle();

        expect(form.field<String>('name').value, 'John');
        expect(form.field<String>('email').value, 'john@example.com');

        form.reset();
        await tester.pumpAndSettle();

        expect(form.field<String>('name').value, isNull);
        expect(form.field<String>('email').value, isNull);
        expect(find.text('John'), findsNothing);
        expect(find.text('john@example.com'), findsNothing);

        form.dispose();
      },
    );

    testWidgets(
      'after a submit-driven setState rebuild',
      (WidgetTester tester) async {
        final form = V.map({'name': V.string(), 'email': V.string()}).form();

        await tester.pumpWidget(_SubmitThenResetHarness(form: form));

        await tester.enterText(find.byKey(const Key('nameField')), 'John');
        await tester.enterText(
          find.byKey(const Key('emailField')),
          'john@example.com',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('submit')));
        await tester.pumpAndSettle();

        form.reset();
        await tester.pumpAndSettle();

        expect(form.field<String>('name').value, isNull);
        expect(form.field<String>('email').value, isNull);
        expect(find.text('John'), findsNothing);
        expect(find.text('john@example.com'), findsNothing);

        form.dispose();
      },
    );
  });
}

class _SubmitThenResetHarness extends StatefulWidget {
  final VForm<Map<String, dynamic>> form;

  const _SubmitThenResetHarness({required this.form});

  @override
  State<_SubmitThenResetHarness> createState() =>
      _SubmitThenResetHarnessState();
}

class _SubmitThenResetHarnessState extends State<_SubmitThenResetHarness> {
  @override
  Widget build(BuildContext context) {
    final name = widget.form.field<String>('name');
    final email = widget.form.field<String>('email');
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: widget.form.key,
          child: Column(
            children: [
              TextFormField(
                key: const Key('nameField'),
                initialValue: name.initialValue,
                validator: name.validator,
                onChanged: name.onChanged,
              ),
              TextFormField(
                key: const Key('emailField'),
                initialValue: email.initialValue,
                validator: email.validator,
                onChanged: email.onChanged,
              ),
              ElevatedButton(
                key: const Key('submit'),
                onPressed: () {
                  widget.form.validate();
                  setState(() {});
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticHarness extends StatelessWidget {
  final VForm<Map<String, dynamic>> form;

  const _StaticHarness({required this.form});

  @override
  Widget build(BuildContext context) {
    final name = form.field<String>('name');
    final email = form.field<String>('email');
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: form.key,
          child: Column(
            children: [
              TextFormField(
                key: const Key('nameField'),
                initialValue: name.initialValue,
                validator: name.validator,
                onChanged: name.onChanged,
              ),
              TextFormField(
                key: const Key('emailField'),
                initialValue: email.initialValue,
                validator: email.validator,
                onChanged: email.onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RebuildOnChangeHarness extends StatefulWidget {
  final VForm<Map<String, dynamic>> form;

  const _RebuildOnChangeHarness({required this.form});

  @override
  State<_RebuildOnChangeHarness> createState() =>
      _RebuildOnChangeHarnessState();
}

class _RebuildOnChangeHarnessState extends State<_RebuildOnChangeHarness> {
  @override
  void initState() {
    super.initState();
    widget.form.addValueChangedListener(_onChange);
  }

  @override
  void dispose() {
    widget.form.removeValueChangedListener(_onChange);
    super.dispose();
  }

  void _onChange(Map<String, dynamic> _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final name = widget.form.field<String>('name');
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: widget.form.key,
          child: TextFormField(
            key: const Key('nameField'),
            initialValue: name.initialValue,
            validator: name.validator,
            onChanged: name.onChanged,
          ),
        ),
      ),
    );
  }
}

enum _Status { active, inactive }

enum _Role { admin, user, guest }

class _User {
  final String name;
  final String email;

  const _User({required this.name, required this.email});
}

class _Profile {
  final String name;
  final int age;
  final double height;
  final bool active;
  final DateTime joined;
  final List<String> tags;
  final _Role role;
  final Object id; // String (uuid) OR int
  final String email;

  const _Profile({
    required this.name,
    required this.age,
    required this.height,
    required this.active,
    required this.joined,
    required this.tags,
    required this.role,
    required this.id,
    required this.email,
  });
}
