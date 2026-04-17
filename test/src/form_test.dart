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
  });
}

enum _Status { active, inactive }

class _User {
  final String name;
  final String email;

  const _User({required this.name, required this.email});
}
