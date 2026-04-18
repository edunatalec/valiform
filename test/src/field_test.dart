import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valiform/valiform.dart';
import 'package:validart/validart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('set(null) resets value to null', () {
    field.set(null);
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

  test('onChanged accepts null (e.g. DropdownButtonFormField)', () {
    final dropdownField = VField<String>(
      type: V.string().nullable(),
      validators: [],
      initialValue: 'start',
    );
    dropdownField.onChanged(null);
    expect(dropdownField.value, isNull);
    dropdownField.dispose();
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
      field.attachController(controller, owns: false);

      controller.value = 'updated';
      expect(field.value, 'updated');

      controller.dispose();
    });

    test('Syncs field set to controller', () {
      final controller = ValueNotifier<String?>(null);
      field.attachController(controller, owns: false);

      field.set('hello');
      expect(controller.value, 'hello');

      controller.dispose();
    });

    test('Syncs field set(null) to controller', () {
      final controller = ValueNotifier<String?>('value');
      field.attachController(controller, owns: false);

      field.set(null);
      expect(controller.value, isNull);

      controller.dispose();
    });

    test('Syncs field reset to controller', () {
      final controller = ValueNotifier<String?>(null);
      field.attachController(controller, owns: false);

      field.set('changed');
      field.reset();
      expect(controller.value, 'Initial');

      controller.dispose();
    });

    test('detachController stops syncing', () {
      final controller = ValueNotifier<String?>(null);
      field.attachController(controller, owns: false);

      field.detachController();

      field.set('after detach');
      expect(controller.value, isNull);

      controller.dispose();
    });

    test('controller returns the attached ValueNotifier, textController null',
        () {
      final ownedField = VField<String>(
        type: V.string(),
        validators: [],
      );
      expect(ownedField.controller, isNull);
      expect(ownedField.textController, isNull);

      final vn = ValueNotifier<String?>(null);
      ownedField.attachController(vn);
      expect(ownedField.controller, same(vn));
      expect(ownedField.textController, isNull);

      ownedField.dispose();
    });

    test('textController returns the attached TextEditingController', () {
      final ownedField = VField<String>(
        type: V.string(),
        validators: [],
      );
      expect(ownedField.textController, isNull);

      final controller = TextEditingController();
      ownedField.attachTextController(controller);
      expect(ownedField.textController, same(controller));
      expect(ownedField.controller, isNull);

      ownedField.dispose();
    });

    test('dispose disposes owned ValueNotifier', () {
      final ownedField = VField<String>(
        type: V.string(),
        validators: [],
      );
      final controller = ValueNotifier<String?>('hi');
      ownedField.attachController(controller); // owns: true default

      ownedField.dispose();

      expect(
        () => controller.addListener(() {}),
        throwsFlutterError,
      );
    });

    test('dispose disposes owned TextEditingController', () {
      final ownedField = VField<String>(
        type: V.string(),
        validators: [],
      );
      final controller = TextEditingController(text: 'hi');
      ownedField.attachTextController(controller);

      ownedField.dispose();

      expect(
        () => controller.addListener(() {}),
        throwsFlutterError,
      );
    });

    test('dispose does NOT dispose controller when owns: false', () {
      final ownedField = VField<String>(
        type: V.string(),
        validators: [],
      );
      final controller = TextEditingController(text: 'hi');
      ownedField.attachTextController(controller, owns: false);

      ownedField.dispose();

      // Controller must still be usable
      expect(() => controller.text = 'still alive', returnsNormally);
      controller.dispose();
    });

    test('onValueChanged fires callback on value changes and returns dispose',
        () {
      final ownedField = VField<String>(
        type: V.string().nullable(),
        validators: [],
      );
      final received = <String?>[];
      final dispose = ownedField.onValueChanged(received.add);

      ownedField.set('a');
      ownedField.set('b');
      expect(received, ['a', 'b']);

      dispose();
      ownedField.set('c');
      expect(received, ['a', 'b']);

      ownedField.dispose();
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
      field.set(null);
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

  group('setError / clearError', () {
    test('setError stores the message and exposes it via manualError', () {
      field.set('valid@email.com');
      field.setError('Email already taken');
      expect(field.manualError, 'Email already taken');
    });

    test('clearError removes the manual error', () {
      field.set('valid@email.com');
      field.setError('Email already taken');
      field.clearError();
      expect(field.manualError, isNull);
    });

    test('clearError is a no-op when no error is set', () {
      expect(() => field.clearError(), returnsNormally);
      expect(field.manualError, isNull);
    });

    test('validator returns manual error when no standard error exists', () {
      field.set('valid@email.com');
      field.setError('Email already taken');
      expect(field.validator(field.value), 'Email already taken');
    });

    test('standard validators take precedence over manual error', () {
      field.set('not-an-email');
      field.setError('Email already taken');
      final result = field.validator(field.value);
      expect(result, isNotNull);
      expect(result, isNot('Email already taken'));
    });

    test(
        'one-shot manual error is consumed even when a standard error wins '
        '(prevents ghost errors on later valid input)', () {
      field.set('not-an-email');
      field.setError('Email already taken');
      field.validator(field.value); // std error wins, but manual is consumed
      expect(field.manualError, isNull);

      field.set('valid@email.com');
      expect(field.validator(field.value), isNull);
    });

    test(
        'persist: manual error survives when standard error wins and resurfaces'
        ' once the field becomes valid', () {
      field.set('not-an-email');
      field.setError('Email already taken', persist: true);
      final first = field.validator(field.value);
      expect(first, isNotNull);
      expect(first, isNot('Email already taken'));
      expect(field.manualError, 'Email already taken');

      field.set('valid@email.com');
      expect(field.validator(field.value), 'Email already taken');
    });

    test('default mode is one-shot: consumed on next validator call', () {
      field.set('valid@email.com');
      field.setError('Email already taken');

      expect(field.validator(field.value), 'Email already taken');
      expect(field.manualError, isNull);
      expect(field.validator(field.value), isNull);
    });

    test('persist: true keeps the error across multiple validator calls', () {
      field.set('valid@email.com');
      field.setError('Email already taken', persist: true);

      expect(field.validator(field.value), 'Email already taken');
      expect(field.validator(field.value), 'Email already taken');
      expect(field.manualError, 'Email already taken');

      field.clearError();
      expect(field.validator(field.value), isNull);
    });

    test('force: true makes manual error win over standard validators', () {
      field.set('not-an-email');
      field.setError('Server rejected this value', force: true);
      expect(field.validator(field.value), 'Server rejected this value');
    });

    test('force is one-shot when persist is false', () {
      field.set('not-an-email');
      field.setError('Forced error', force: true);

      expect(field.validator(field.value), 'Forced error');
      final second = field.validator(field.value);
      expect(second, isNotNull);
      expect(second, isNot('Forced error'));
    });

    test('force + persist: manual error wins on every call until clearError',
        () {
      field.set('not-an-email');
      field.setError('Sticky forced', persist: true, force: true);

      expect(field.validator(field.value), 'Sticky forced');
      expect(field.validator(field.value), 'Sticky forced');

      field.clearError();
      expect(field.validator(field.value), isNotNull);
      expect(field.validator(field.value), isNot('Sticky forced'));
    });

    test('key is available for attachment', () {
      expect(field.key, isNotNull);
      expect(field.key, isA<GlobalKey<FormFieldState<String>>>());
    });

    test('validate() reflects manual error without consuming it', () {
      field.set('valid@email.com');
      field.setError('Manual issue');

      expect(field.validate(), false);
      expect(field.validate(), false);
      expect(field.manualError, 'Manual issue');

      expect(field.validator(field.value), 'Manual issue');
      expect(field.manualError, isNull);
      expect(field.validate(), true);
    });

    test('validate() respects force flag', () {
      field.set('not-an-email');
      field.setError('Forced', force: true, persist: true);
      expect(field.validate(), false);
    });
  });

  group('attachTextController', () {
    test('Syncs TextEditingController to field', () {
      final controller = TextEditingController();
      field.attachTextController(controller, owns: false);

      controller.text = 'typed';
      expect(field.value, 'typed');

      controller.dispose();
    });

    test('Syncs field set to TextEditingController', () {
      final controller = TextEditingController();
      field.attachTextController(controller, owns: false);

      field.set('programmatic');
      expect(controller.text, 'programmatic');

      controller.dispose();
    });

    test('Syncs field set(null) to TextEditingController', () {
      final controller = TextEditingController(text: 'initial');
      field.attachTextController(controller, owns: false);

      field.set(null);
      expect(controller.text, '');

      controller.dispose();
    });
  });
}
