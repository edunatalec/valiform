## [1.0.0] - 2026-04-18

### Breaking Changes

- **Removed validart re-export** — Import `package:validart/validart.dart` separately.
- **Removed built-in `TextEditingController`** — Use `attachController()` for bidirectional sync.
- **`VForm` is now generic** — `VForm<Map<String, dynamic>>` for VMap, `VForm<T>` for VObject.
- **Replaced `Validart()` instance** — Use `V` class with static methods (`V.string()`, `V.map()`, etc.).
- **Replaced `.refine(check, path:)`** — Use `.refineFormField(check, path:)` for cross-field validation.
- **Removed `VNum` support** — Use `VInt` or `VDouble` directly.
- **Renamed `defaultValues` → `initialValues`** — on `VMap.form()` / `VForm.map()`. Matches Flutter's `TextFormField.initialValue` naming and better reflects semantics (seed values, not fallbacks).
- **Renamed `defaultValue` → `initialValue`** — on `VObject.form()` / `VForm.object()`.
- **`VField.onChanged` now accepts `T?`** — so it can be wired directly to widgets like `DropdownButtonFormField` whose `onChanged` passes a nullable value.
- **`VField.validate()` now runs all validators (including cross-field and manual errors) without side-effects** — previously only ran the schema check. Behaviour of the Flutter-facing `validator(value)` is unchanged.

### Added

- **Imperative error setting** — `VField.setError(message, {persist, force})` / `VField.clearError()` and their `VForm` counterparts (`setError`, `setErrors`, `clearError`, `clearErrors`). Useful for backend validation errors, async checks, and external-state business rules.
  - **Default (one-shot)** — the error surfaces on the next `validator()` call and is cleared on it, even when a standard validator wins precedence. This prevents "ghost" errors from lingering until the field happens to pass its own rules later.
  - **`persist: true`** — keeps the error across multiple validations until `clearError()` is called explicitly.
  - **`force: true`** — overrides standard-validator precedence so the manual error is shown even on a field that would otherwise fail its own rules.
  - **`persist: true, force: true`** — combined: always shows the manual error on every validation until `clearError()`, regardless of field state (useful for server-side blocks like "Account suspended").
- **`VField.key`** — Optional `GlobalKey<FormFieldState<T>>` that, when attached to a `TextFormField`, lets `setError` revalidate only that field without triggering error display on others.
- **VObject support** — Create typed forms with `V.object<T>().form(builder:)` that return `T` instead of `Map`.
- **`attachController(ValueNotifier<T?> controller, {bool owns = true})`** — Bidirectional sync with a `ValueNotifier<T?>` (or subclass like `LuneSelectFieldController<T>`). Takes ownership by default — controller is disposed together with the field. Pass `owns: false` to keep external lifecycle management. Retrieve via `field.controller` (typed).
- **`attachTextController(TextEditingController, {bool owns = true})`** — Extension method on `VField<String>` for `TextEditingController` specifically (since its value type is `TextEditingValue`, not `String`). Same ownership semantics. Retrieve via `field.textController` (typed).
- **`onValueChanged(void Function(T? value) callback)`** — Bridge method for complex cases where the external state isn't a `ValueNotifier<T?>`. Registers a callback invoked on every field value change; returns a dispose function.
- **`detachController()`** — Remove attached controller listeners without disposing (dispose happens in `VField.dispose()` if owned).
- **`parsedValue` getter** — Returns the value after pipeline transforms (trim, toLowerCase, etc.).
- **`onValueChanged` callback** — Pass in `.form()` or use `addValueChangedListener()` / `removeValueChangedListener()`.
- **`rawValue` getter on VForm** — Returns field values without transforms.
- **Typed `initialValue` for VObject forms** — Pass a `T` instance instead of a map.
- **`mapType` on VType** — Preserves generic types, enabling `VField<Country>` for enums and custom types.
- **Fallback-free field creation** — All VType generics are preserved via `mapType` (no more `VField<dynamic>` fallback).
- **Conditional validation (`when`)** — VMap's `.when()` rules are automatically plumbed to individual field validators.
- **Nullable field support** — Empty strings are treated as `null` for nullable fields in validators.

### Changed

- `form.value` now returns parsed values (transforms applied).
- `silentValidate()` now validates against parsed values.
- Equality checks in controller sync prevent unnecessary cascading updates.

## [0.0.3] - 2025-02-27

### Fixed

- Corrected an incorrect validation in the example.

### Changed

- Updated the README with a redirect link to the example for more details.

## [0.0.2] - 2025-02-27

## Added

- Added API documentation (api docs) for better clarity and usability.
- Updated the README documentation with improved explanations and examples.

## Changed

- Upgraded the validart dependency to version 0.1.2.

## [0.0.1] - 2025-02-25

- Initial release
