/// Schema-driven Flutter forms on top of
/// [Validart](https://pub.dev/packages/validart).
///
/// A Validart schema describes the shape of the data; valiform turns that
/// schema into form state. `V.map({...})` and `V.object<T>()` each gain a
/// `form()` extension returning a [VForm], and every key of the schema becomes
/// a typed [VField] holding its own value, validators and error.
///
/// State is a plain `ValueNotifier`, so a field drives any widget: bind it to a
/// `TextFormField` through [VField.validator] and [VField.onChanged], attach a
/// controller for two-way synchronization, or listen to [VForm.listenable] and
/// rebuild. The package ships no widgets of its own.
///
/// Terminology used throughout: a **field** is one key of the schema; the **raw
/// value** is what the widget wrote, before transforms; the **parsed value** is
/// what the schema produced. **Root errors** are messages a schema-level rule
/// emitted with no field path — they belong in a banner, not under an input.
///
/// ```dart
/// final form = V.map({
///   'email': V.string().email(),
///   'password': V.string().min(8),
/// }).form();
///
/// final email = form.field<String>('email');
/// email.onChanged('user@example.com');
///
/// print(form.silentValidate()); // false — password is still empty
/// ```
///
/// See also:
///
///  * [VForm], the form built from a schema.
///  * [VField], one field of that form.
///  * [VMapExtension.form], which turns a `VMap` schema into a [VForm].
///  * [VObjectExtension.form], which turns a `VObject<T>` schema into a typed
///    [VForm].
library;

export 'src/field.dart';
export 'src/form.dart';
export 'src/valiform.dart';
