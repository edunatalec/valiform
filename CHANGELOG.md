# Changelog

## [1.1.0] - 2026-04-21

### Added

- **Async validation** — first-class support for validart 1.1.0 async primitives (`refineAsync`, `preprocessAsync`, `transformAsync`).
  - `VForm.validateAsync()` — runs the full async pipeline and surfaces errors through the normal `FormField` error channel (via persistent imperative errors), so the UI updates exactly like sync validation.
  - `VForm.silentValidateAsync()` — async validation without touching the UI.
  - `VForm.errorsAsync()` / `VForm.vErrorsAsync()` — async counterparts for inspecting current errors.
  - `VForm.valueAsync` — awaits each field's async pipeline and returns the fully-parsed value.
  - `VForm.hasAsync` / `VField.hasAsync` — introspection flag for schemas that require async validation.
  - `VField.validateAsync()`, `VField.errorAsync`, `VField.vErrorAsync`, `VField.parsedValueAsync` — per-field async APIs with the same semantics as their sync siblings.
  - Conditional `.when()` rules now detect async schemas and register them into the async validation path automatically.
- **Async example page** — `example/lib/pages/async_validation_page.dart` demonstrates a simulated remote username-availability check with loading state.
- **Schema `defaultValue` now seeds the VField initial value** — when `.form()` isn't given an explicit value for a field, the schema's `defaultValue` (if any) auto-populates the UI and is the target of `reset()`. Resolution order: `initialValues[key]` (even an explicit `null`) → `schema.defaultValue` → `null`. Reinforces the semantic that a field with `defaultValue` is **never required** — validart substitutes the default for null before any validator runs.
- **`Required Message` example page** — `example/lib/pages/required_message_page.dart` compares `V.bool(message: ...)` against `preprocess((v) => v ?? false)` as two ways to customize the error on an untouched checkbox.
- **`Default Value` example page** — `example/lib/pages/default_value_page.dart` demonstrates the three combinations (`defaultValue` only, `initialValues` only, both) side by side with their respective `reset()` and `required` semantics.

### Changed

- Synchronous inspection methods now mirror validart's strict contract: when the schema contains any async step, `VForm.validate`, `silentValidate`, `errors`, `vErrors`, `value`, `VField.validate`, `error`, `vError`, and `parsedValue` throw `VAsyncRequiredException`. Use the corresponding `*Async` variants. `VField.validator(T?)` is the single sync adapter kept tolerant — it is required by Flutter's synchronous `FormField.validator` signature and is the channel `validateAsync` uses to surface async errors via `setError(persist: true)`.
- Bumped minimum validart constraint to `1.1.0` for `VType.isNullable`, `VType.hasAsync`, `VType.hasDefault`, `VType.defaultValueOrNull`, and the async pipeline APIs.

### Fixed

- `VField.parsedValue` / `parsedValueAsync` now normalize empty strings to `null` before calling `safeParse`, so a schema's `defaultValue` is applied consistently when the user clears a text field. Previously `parsedValue` returned the raw empty string, causing `form.value` to disagree with `form.validate()` in defaulted schemas.

## [1.0.0] - 2026-04-18

### Breaking Changes

- **Removed validart re-export** — import `package:validart/validart.dart` separately.
- **Removed built-in `TextEditingController`** — use `attachTextController()` for bidirectional sync.
- **`VForm` is now generic** — `VForm<Map<String, dynamic>>` for VMap, `VForm<T>` for VObject.
- **Replaced `Validart()` instance** — use the `V` class (`V.string()`, `V.map()`, ...).
- **Replaced `.refine(check, path:)`** — use `.refineFormField(check, path:)`.
- **Removed `VNum` support** — use `VInt` or `VDouble` directly.
- **Renamed `defaultValues` → `initialValues`** on `VMap.form()` / `VForm.map()`.
- **Renamed `defaultValue` → `initialValue`** on `VObject.form()` / `VForm.object()`.
- **`VField.onChanged` now accepts `T?`** — compatible with widgets like `DropdownButtonFormField` whose `onChanged` passes a nullable value.
- **`VField.validate()` now runs all validators without side-effects** — previously only ran the schema check. Behaviour of the Flutter-facing `validator(value)` is unchanged.

### Added

- **VObject support** — `V.object<T>().form(builder:)` returns typed `T` instead of `Map`.
- **Typed fields via `mapType`** — `VField<Country>`, `VField<DateTime>`, and any custom type are preserved across the schema pipeline (no more `VField<dynamic>` fallback).
- **Conditional validation (`.when()`)** — schema rules are plumbed into per-field validators automatically.
- **Nullable fields** — empty strings are normalized to `null` for `.nullable()` types.
- **`initialValues` / `initialValue`** — seed values at form construction, for `VMap` and `VObject` forms respectively.
- **`parsedValue` getter on `VField`** — value after pipeline transforms (`trim`, `toLowerCase`, ...).
- **`rawValue` on `VForm`** — untransformed field values as `Map<String, dynamic>`.
- **`onValueChanged` on form factory** plus **`addValueChangedListener` / `removeValueChangedListener`** on `VForm` for dynamic subscription.
- **`attachController(ValueNotifier<T?>, {owns = true})`** — bidirectional sync with any custom controller that extends `ValueNotifier<T?>` (e.g. `LuneSelectFieldController<T>`). Owned by default — the controller is disposed together with the field. Pass `owns: false` to keep external lifecycle management.
- **`attachTextController(TextEditingController, {owns = true})`** — extension on `VField<String>` for text inputs (since `TextEditingController.value` is `TextEditingValue`, not `String`).
- **`controller` / `textController` getters** — typed access to the currently attached controller.
- **`detachController()`** — remove sync listeners without disposing the controller.
- **`onValueChanged(callback)` on `VField`** — bridge for external state that isn't a `ValueNotifier`. Registers a typed callback on every value change and returns a dispose function.
- **Imperative error setting** — `VField.setError(message, {persist, force})` / `clearError()` and the `VForm` counterparts (`setError`, `setErrors`, `clearError`, `clearErrors`). Useful for backend rejections, async checks, and external-state business rules.
  - **Default (one-shot)** — the error surfaces on the next `validator()` call and is cleared on it, even when a standard validator wins the precedence. Prevents "ghost" errors on later valid input.
  - **`persist: true`** — keeps the error across validations until `clearError()` is called explicitly.
  - **`force: true`** — overrides standard-validator precedence so the manual error shows even on fields that would fail their own rules.
  - **`persist: true, force: true`** — always shown until cleared (server-side blocks like "Account suspended").
- **`VField.key`** — optional `GlobalKey<FormFieldState<T>>` that, when attached to a `FormField`, lets `setError` revalidate only that field (other fields are untouched).
- **`VForm.errors()` / `VField.error`** — read-only inspection of current validation state (all fields or single field). Does NOT consume one-shot manual errors, does NOT touch the UI. Perfect for live error summary panels and debug tooling.
- **`VForm.vErrors()` / `VField.vError`** — like `errors()` / `error` but return the full `List<VError>` (preserving `code`, `path`, `message`). Useful for array fields where `path` contains the failing element's index, or when you need the validator code for custom UI.

### Changed

- `form.value` returns parsed values (transforms applied).
- `form.silentValidate()` now mirrors `validate()` semantically — runs per-field validators AND the schema validator, consuming one-shot manual errors — while still not touching the UI.
- Controller sync uses equality checks and a `_syncing` guard to avoid cascading updates.

### Fixed

- Re-attaching the **same** owned controller no longer disposes it — `attachController` and `attachTextController` use an identity check before disposing the previously owned instance, so `field.attachController(ctrl); field.attachController(ctrl);` is safe.

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
