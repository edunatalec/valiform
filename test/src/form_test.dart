import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valiform/valiform.dart';

final v = Validart();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Basic', () {
    late VForm form;
    late VField<String> email;
    late VField<String> password;

    setUp(() {
      form = v.map({
        'email': v.string().email(),
        'password': v.string().password(),
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
                  controller: email.controller,
                  validator: email.validator,
                  onChanged: email.onChanged,
                ),
                TextFormField(
                  key: const Key('passwordField'),
                  controller: password.controller,
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

      email.set('invalid-email');
      password.set('123');

      expect(form.validate(), false);
    });

    testWidgets('Validation returns true for valid inputs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildFormWidget());

      email.set('test@example.com');
      password.set('Aa1@aaaa');

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

    test('clear() sets all fields to null', () {
      email.set('temp@example.com');
      password.set('TempPass');

      form.clear();

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
  });

  group('Default values', () {
    late VForm form;
    late VField<String> email;

    setUp(() {
      form = v.form(
        v.map({
          'email': v.string().email(),
        }),
        defaultValues: {'email': 'default@example.com'},
      );

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
    late VForm form;
    late VField<String> password;
    late VField<String> confirmPassword;

    setUp(() {
      form = v.form(
        v.map({
          'password': v.string().password(),
          'confirmPassword': v.string().password(),
        }).refine(
          (data) => data['password'] == data['confirmPassword'],
          path: 'confirmPassword',
        ),
      );

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
                  controller: password.controller,
                  validator: password.validator,
                  onChanged: password.onChanged,
                ),
                TextFormField(
                  controller: confirmPassword.controller,
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

      password.set('Aa1@aaaa');
      confirmPassword.set('Aa1@aaaa');

      expect(form.validate(), true);

      password.set('Aa1@aaaaa');
      confirmPassword.set('Aa1@aaaa');

      expect(form.validate(), false);
    });
  });

  group('VForm initialization with different types', () {
    late VForm form;
    late VField<int> integer;
    late VField<double> decimal;
    late VField<num> number;
    late VField<bool> boolean;
    late VField<DateTime> date;

    setUp(() {
      form = v.map({
        'integer': v.int(),
        'decimal': v.double(),
        'number': v.num(),
        'boolean': v.bool(),
        'date': v.date(),
      }).form(
        defaultValues: {
          'integer': 42,
          'decimal': 3.14,
          'number': 1000,
          'boolean': true,
          'date': DateTime(2024, 02, 25),
        },
      );

      integer = form.field<int>('integer');
      decimal = form.field<double>('decimal');
      number = form.field<num>('number');
      boolean = form.field<bool>('boolean');
      date = form.field<DateTime>('date');
    });

    tearDown(() {
      form.dispose();
    });

    test('Fields are correctly initialized with the right types', () {
      expect(integer, isA<VField<int>>());
      expect(decimal, isA<VField<double>>());
      expect(form.field<num>('number'), isA<VField<num>>());
      expect(form.field<bool>('boolean'), isA<VField<bool>>());
      expect(form.field<DateTime>('date'), isA<VField<DateTime>>());
    });

    test('Initial values are correctly assigned', () {
      expect(integer.value, 42);
      expect(decimal.value, 3.14);
      expect(number.value, 1000);
      expect(boolean.value, true);
      expect(date.value, DateTime(2024, 02, 25));
    });

    test('Reset restores initial values', () {
      integer.set(99);
      decimal.set(9.99);
      number.set(500);
      boolean.set(false);
      date.set(DateTime(2025, 01, 01));

      form.reset();

      expect(integer.value, 42);
      expect(decimal.value, 3.14);
      expect(number.value, 1000);
      expect(boolean.value, true);
      expect(date.value, DateTime(2024, 02, 25));
    });
  });
}
