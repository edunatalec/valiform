import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

void main() {
  late VField<String> field;

  setUp(() {
    field = VField<String>(
      type: V.string().email(),
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

  test('Clear resets value to null', () {
    field.clear();
    expect(field.value, isNull);
  });

  test('Reset restores initial value', () {
    field.set('Temporary');
    field.reset();
    expect(field.value, 'Initial');
  });

  test('Validator returns error when value is empty', () {
    field.set('');
    expect(field.validator(field.value), isNotNull);
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
      type: V.string().email(),
      validators: [() => 'Error message'],
      initialValue: 'Initial',
    );

    expect(customField.validator('example@email.com'), 'Error message');
  });

  group('attachController', () {
    test('Syncs ValueNotifier controller to field', () {
      final controller = ValueNotifier<String?>('test');
      field.attachController(controller);

      controller.value = 'updated';
      expect(field.value, 'updated');

      controller.dispose();
    });

    test('Syncs field set to controller', () {
      final controller = ValueNotifier<String?>(null);
      field.attachController(controller);

      field.set('hello');
      expect(controller.value, 'hello');

      controller.dispose();
    });

    test('Syncs field clear to controller', () {
      final controller = ValueNotifier<String?>('value');
      field.attachController(controller);

      field.clear();
      expect(controller.value, isNull);

      controller.dispose();
    });

    test('Syncs field reset to controller', () {
      final controller = ValueNotifier<String?>(null);
      field.attachController(controller);

      field.set('changed');
      field.reset();
      expect(controller.value, 'Initial');

      controller.dispose();
    });

    test('detachController stops syncing', () {
      final controller = ValueNotifier<String?>(null);
      field.attachController(controller);

      field.detachController();

      field.set('after detach');
      expect(controller.value, isNull);

      controller.dispose();
    });
  });

  group('parsedValue', () {
    test('Returns transformed value after pipeline', () {
      final trimField = VField<String>(
        type: V.string().trim().min(3),
        validators: [],
      );

      trimField.set('  hello  ');
      expect(trimField.value, '  hello  ');
      expect(trimField.parsedValue, 'hello');

      trimField.dispose();
    });

    test('Returns raw value when parsing fails', () {
      final trimField = VField<String>(
        type: V.string().trim().min(10),
        validators: [],
      );

      trimField.set('  hi  ');
      expect(trimField.parsedValue, '  hi  ');

      trimField.dispose();
    });

    test('Returns null when value is null', () {
      field.clear();
      expect(field.parsedValue, isNull);
    });
  });

  group('value edge cases', () {
    test('Empty string returns null for nullable field', () {
      final optionalField = VField<String>(
        type: V.string().nullable(),
        validators: [],
      );

      optionalField.set('');
      expect(optionalField.value, isNull);

      optionalField.dispose();
    });

    test('Empty string returns empty for required field', () {
      final requiredField = VField<String>(
        type: V.string(),
        validators: [],
      );

      requiredField.set('');
      expect(requiredField.value, '');

      requiredField.dispose();
    });
  });

  group('array field', () {
    test('VField<List<String>> stores and retrieves list', () {
      final arrayField = VField<List<String>>(
        type: V.array<String>(V.string().min(2)).min(1),
        validators: [],
      );

      arrayField.set(['hello', 'world']);
      expect(arrayField.value, ['hello', 'world']);

      arrayField.dispose();
    });

    test('Validates minimum items', () {
      final arrayField = VField<List<String>>(
        type: V.array<String>(V.string()).min(2),
        validators: [],
      );

      arrayField.set(['one']);
      expect(arrayField.validate(), false);

      arrayField.set(['one', 'two']);
      expect(arrayField.validate(), true);

      arrayField.dispose();
    });

    test('Validates element constraints', () {
      final arrayField = VField<List<String>>(
        type: V.array<String>(V.string().min(3)),
        validators: [],
      );

      arrayField.set(['hi']);
      expect(arrayField.validate(), false);

      arrayField.set(['hello']);
      expect(arrayField.validate(), true);

      arrayField.dispose();
    });

    test('parsedValue works with arrays', () {
      final arrayField = VField<List<String>>(
        type: V.array<String>(V.string().trim()),
        validators: [],
      );

      arrayField.set(['  hello  ', '  world  ']);
      final parsed = arrayField.parsedValue;
      expect(parsed, ['hello', 'world']);

      arrayField.dispose();
    });
  });

  group('attachTextController', () {
    test('Syncs TextEditingController to field', () {
      final controller = TextEditingController();
      field.attachTextController(controller);

      controller.text = 'typed';
      expect(field.value, 'typed');

      controller.dispose();
    });

    test('Syncs field set to TextEditingController', () {
      final controller = TextEditingController();
      field.attachTextController(controller);

      field.set('programmatic');
      expect(controller.text, 'programmatic');

      controller.dispose();
    });

    test('Syncs field clear to TextEditingController', () {
      final controller = TextEditingController(text: 'initial');
      field.attachTextController(controller);

      field.clear();
      expect(controller.text, '');

      controller.dispose();
    });
  });
}
