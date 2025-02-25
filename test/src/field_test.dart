import 'package:flutter_test/flutter_test.dart';
import 'package:valiform/valiform.dart';

final v = Validart();

void main() {
  late VField<String> field;

  setUp(() {
    field = VField<String>(
      type: v.string().email(),
      validators: [],
      initialValue: 'Initial',
    );
  });

  tearDown(() {
    field.dispose();
  });

  test('Initial value is set correctly', () {
    expect(field.value, 'Initial');
  });

  test('Set and get values', () {
    field.set('New Value');
    expect(field.value, 'New Value');
  });

  test('TextEditingController initializes correctly', () {
    expect(field.controller, isNotNull);
    expect(field.controller!.text, 'Initial');
  });

  test('Setting value updates controller', () {
    field.set('Updated Value');
    expect(field.controller!.text, 'Updated Value');
  });

  test('Clear resets value to null', () {
    field.clear();
    expect(field.value, isNull);
    expect(field.controller!.text, '');
  });

  test('Reset restores initial value', () {
    field.set('Temporary');
    field.reset();
    expect(field.value, 'Initial');
    expect(field.controller!.text, 'Initial');
  });

  test('Validator returns error when value is empty', () {
    field.set('');
    expect(field.validator(field.value), 'Required');
  });

  test('Validator returns null for valid input', () {
    field.set('example@email.com');
    expect(field.validator(field.value), isNull);
  });

  test('Validate returns false for empty value', () {
    field.set('');
    expect(field.validate(), false);
  });

  test('Validate returns true for non-empty value', () {
    field.set('example@email.com');
    expect(field.validate(), true);
  });

  test('Listenable emits notification when value changes', () {
    int notificationCount = 0;

    field.listenable.addListener(() {
      notificationCount++;
    });

    field.set('New Value');

    expect(notificationCount, 1);
  });

  test('onChanged updates value and notifies listeners', () {
    int notificationCount = 0;

    field.listenable.addListener(() {
      notificationCount++;
    });

    field.onChanged('Changed Value');

    expect(field.value, 'Changed Value');
    expect(notificationCount, 1);
  });

  test('onSaved updates value', () {
    field.onSaved('Saved Value');
    expect(field.value, 'Saved Value');
  });

  test('Custom error message', () {
    final customField = VField<String>(
      type: v.string().email(),
      validators: [() => 'Error message'],
      initialValue: 'Initial',
    );

    expect(customField.validator('example@email.com'), 'Error message');
  });
}
