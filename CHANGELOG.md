## [1.0.0] - 2026-04-15

### Breaking Changes

- **Removed validart re-export** — Import `package:validart/validart.dart` separately.
- **Removed built-in `TextEditingController`** — Use `attachTextController()` for bidirectional sync.
- **`VForm` is now generic** — `VForm<Map<String, dynamic>>` for VMap, `VForm<T>` for VObject.
- **Replaced `Validart()` instance** — Use `V` class with static methods (`V.string()`, `V.map()`, etc.).
- **Replaced `.refine(check, path:)`** — Use `.refineFormField(check, path:)` for cross-field validation.
- **Removed `VNum` support** — Use `VInt` or `VDouble` directly.

### Added

- **VObject support** — Create typed forms with `V.object<T>().form(builder:)` that return `T` instead of `Map`.
- **`attachController(ValueNotifier<T?>)`** — Bidirectional sync with any `ValueNotifier`.
- **`attachTextController(TextEditingController)`** — Bidirectional sync for text fields.
- **`detachController()`** — Remove attached controller listeners.
- **`parsedValue` getter** — Returns the value after pipeline transforms (trim, toLowerCase, etc.).
- **`onValueChanged` callback** — Pass in `.form()` or use `addValueChangedListener()` / `removeValueChangedListener()`.
- **`rawValue` getter on VForm** — Returns field values without transforms.
- **Typed `defaultValue` for VObject forms** — Pass a `T` instance instead of a map.
- **`mapType` on VType** — Preserves generic types, enabling `VField<Country>` for enums and custom types.
- **Fallback-free field creation** — All VType generics are preserved via `mapType` (no more `VField<dynamic>` fallback).

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
