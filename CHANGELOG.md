# Changelog

## [3.1.0] - 2026-08-01

### Added

- `CONTRIBUTING.md` now ships in the published archive, which is what makes pub.dev show the "Contributing" link in the package sidebar.

### Changed

- Minimum `validart` constraint raised to `^3.0.2`.
- **Raised the SDK floor to Dart `^3.9.0` / Flutter `>=3.35.0`.** The previous `>=3.0.0 <4.0.0` / `>=3.10.0` pair was a generic default nothing ever verified — the repository does not resolve, analyze or run on a Flutter that old. The new floor is the lowest the package verifiably works on, and CI now analyzes and tests there on every pull request.
- API reference: every symbol cited in prose is now a link, each public type ends with a `See also:` block, and the library page introduces the terminology (field, raw value, parsed value, root errors) the rest of the docs rely on.
- README follows the skeleton shared by the published packages: `## Contents` sits right after the Quick start and lists only what comes after it, the feature list moved into `## Why valiform`, and Requirements states the command that checks the SDK.
- README gained a `## Contributing` section, and links to repository files are now absolute. A relative link is rewritten to GitHub on the package page but left untouched in the generated API reference, where it resolved to a 404.

## [3.0.1] - 2026-07-28

### Changed

- The `flutter` environment constraint now declares the real floor (`>=3.10.0`, the Flutter release paired with the Dart `>=3.0.0` minimum) instead of the meaningless template default `>=1.17.0`. The Dart constraint is unchanged.
- Adopted the stricter shared analysis options (strict casts, plus async, import, immutability and bug-prone lints); source and tests adjusted to the new rules — no behavior change.
- Raised the minimum `validart` constraint to `^3.0.1`.

## [3.0.0] - 2026-05-16

### Breaking Changes

- **Bumped minimum `validart` constraint to `^3.0.0`.** validart 3.0.0 reshapes `refineFieldRaw` / `whenMatchesRaw` and introduces opt-in empty-string normalization via `V.treatEmptyAsNull` / `VString.treatEmptyAsNull()`. Consumers of the path-dependency setup for development should keep `dependency_overrides: validart: { path: ../validart }` while the new pub version propagates.
- **Removed the implicit empty-string-to-null normalization in `VField.value`, `VField._preprocess`, `VField._preprocessAsync`, and `VForm._rawSnapshot`.** valiform 2.x rewrote `""` to `null` at the form/field boundary so `defaultValue` / `.nullable()` would engage when the user cleared a `TextFormField`. That behaviour is now delegated to validart's explicit switch:
  - **Recommended migration:** add `V.treatEmptyAsNull(true)` once at app boot (e.g. in `main`). This reproduces the 2.x UX globally.
  - **Per-field opt-in:** declare `V.string().treatEmptyAsNull()` on individual schemas where you want the conversion.
  - Forms that never relied on `""` → `null` semantics need no change.
- **`VMap.refineFieldRaw(check, path:)` was removed by validart 3.0.0.** Migrate to `refineField(check, path:, stage: RefineStage.pre)` — same callback shape, same demuxing behaviour in `VForm`. valiform's `example/lib/pages/refine_field_raw_page.dart` and the relevant tests were migrated as part of this release.

### Added

- **`whenMatchesRaw` propagation in `VForm.object<T>`.** The factory now reads `VObject.whenMatchesRawRules` alongside the existing entity-typed `whenMatchesRules`, so raw map-shaped predicates feed the per-field validator chain without going through the user's `builder`. This is the recommended path for typed forms whose builder dereferences `data['x']` into non-nullable parameters — partial inputs are uniformly safe. The pre-existing try/catch adapter for entity-typed `whenMatches` stays in place for forms that prefer the typed predicate.
- **`refineFieldRaw` on `VObject<T>` flows through the schema-error demux automatically** — no factory change required. Path-keyed errors land inline under the target field exactly like `refineField`. Pinned by a new `refineFieldRaw via VObject` test group.
- **README section "Empty strings as `null`"** documenting the recommended `V.treatEmptyAsNull(true)` setup and the per-field alternative, with a migration note from 2.x.
- **README guidance "`whenMatches` vs `whenMatchesRaw` in `VForm.object`" and "`refineField` vs `refineFieldRaw` in `VForm.object`"** explaining when each variant is the right choice and why the `*Raw` flavour is recommended for typed forms with strict (non-defensive) builders.
- **`example/lib/main.dart` now calls `V.treatEmptyAsNull(true)` before `runApp`** so the demo app preserves the 2.x UX of empty `TextFormField` → `null`.
- **`field.computeAsyncError()` promoted to public API.** Previously marked `Internal:` in its dartdoc — in practice it is the only primitive that runs `refineAsync` without reading back `_manualError`, which makes it the right tool for wiring async validation per-keystroke under `AutovalidateMode.always`. Dartdoc rewritten with the recommended `onChanged` pattern; tabulated in the README's "Async Validation" section.
- **`example/lib/pages/live_pipeline_page.dart`** — per-keystroke trace of a chained schema (`preprocess → trim → toLowerCase → min → transform`). Makes it visible that the `TextEditingController.text` never changes while the pipeline rewrites the value the validator sees.
- **`example/lib/pages/async_race_page.dart`** — side-by-side reproducer of the classic out-of-order `refineAsync` race when fired on every keystroke. Inverted-latency demo (short inputs slow, long inputs fast) so the naïve handler flips the verdict backwards while the token-guarded handler stays correct. Paired with a new README subsection "Async with `AutovalidateMode.always` — per-keystroke async needs explicit wiring" covering token / debounce / dedup / HTTP cancel / `switchMap` strategies.
- **README section "Submit-time async — guard against double-submit"** with the `_submitting` flag pattern for disabling the submit button while `validateAsync` is in flight.
- **README "Recommended setup" section** placed right after Installation, encouraging `V.treatEmptyAsNull(true)` at boot for form apps.
- **`form.set(...)` — bulk-update field values.** Counterpart to the existing per-field `field.set`. Accepts a `Map<String, dynamic>` on every form; on `VForm.object<T>`, also accepts a typed `T` instance (decomposed via `VObject.extract`). Partial updates by design — fields missing from the input are left untouched, unknown keys are ignored silently (same forgiving shape as `safeParseRaw`). Useful for hydrating from API responses, applying a "Reset to template" action, or syncing the whole form from external state.
- **`VForm.object` accepts `initialValues: Map<String, dynamic>` (partial Map) as a second shape for pre-filling.** Until 3.0.0 the only way to seed a typed form was a complete `T` instance via `initialValue`. For required non-nullable fields that the user hasn't filled yet, that forced placeholder values (e.g. `title: ''`) just to satisfy the constructor. Now you can pass `initialValues: {'familyId': '...'}` listing only the fields you actually want pre-set; absent fields stay `null` (paired with `treatEmptyAsNull` for the "empty everywhere is null" UX), unknown keys are ignored. The two parameters are mutually exclusive — passing both triggers an `AssertionError`. The `VObjectExtension<T>.form()` extension forwards the new parameter unchanged. Pinned by 5 new tests under `'VForm.object: partial initialValues Map'`.

### Fixed

- **`when` / `whenMatches` predicates now see schema-preprocessed values, not raw widget input.** Before this fix, both `when('field', equals: null, ...)` and `whenMatches((data) => data['field'] == null, ...)` would silently miss a cleared `TextFormField` — the predicate received `""` instead of `null` even when the schema declared `treatEmptyAsNull` (or any other `.preprocess(...)`). The factory now snapshots field values through each type's `runPreprocessors` / `runPreprocessorsAsync` before feeding the predicate, so `treatEmptyAsNull` (and user preprocess) reaches the rule. Sync snapshot is tolerant of async siblings (passes them raw); async snapshot uses `runPreprocessorsAsync` end-to-end. Pinned by two new tests under `'treatEmptyAsNull reaches when / whenMatches predicates'`.
- **`treatEmptyAsNull` now gates `field.value` and every derived getter — guarantees "empty everywhere is null", with no internal divergence.** Before this fix, the flag (global or per-field) only affected validart's pipeline; `field.value`, `form.rawValue`, and `form.value` (when `parsedValue` fell back to raw for a non-nullable field cleared by the user) still returned `""`. The fix runs normalization **on the write path** — every entry point that stores a value into the field (`set`, `onChanged`, `onSaved`, attached `ValueNotifier<T?>` listener, attached `TextEditingController` listener, **the `initialValue` passed at construction**, and therefore `reset()` which restores it) consults the new validart `VString.treatsEmptyAsNull` getter (resolves per-field override over `V.isEmptyAsNullEnabled`) and rewrites `""` → `null` before assigning. The internal `ValueNotifier`, the `field.value` getter, any attached `ValueNotifier<String?>` controller, `field.listenable` listeners, `form.rawValue`, `form.value`, `_rawSnapshot`, `_predicateSnapshot`, and `parsedValue`'s fallback path all observe the same `null` — no divergence between internal state and consumer-visible state. The attached `TextEditingController` keeps displaying `""` (the existing controller-sync renders `null` → `""`), so the user's cleared input remains visible while the model holds `null`. Flag composition stays consistent: per-field `V.string().treatEmptyAsNull()` opts a single schema in, `V.treatEmptyAsNull(true)` opts the whole app in, `V.string().treatEmptyAsNull(enabled: false)` opts a specific field out of a globally-enabled flag. Pinned by three test groups: global-on (4 tests), per-field on/off (2 tests), and `ValueNotifier == field.value` no-divergence (3 tests).

## [2.2.1] - 2026-05-08

### Changed

- **Bumped minimum `validart` constraint to `^2.2.0`.**
- **`example/` trimmed to its portable core (`lib/`, `pubspec.yaml`, `analysis_options.yaml`).**

## [2.2.0] - 2026-05-01

### Changed

- **Bumped minimum `validart` constraint to `^2.1.0`.**

### Added

- **`whenMatches` propagation (parity with `whenRules`).** validart 2.1.0's predicate-based conditional rules — `VMap.whenMatchesRules` and `VObject<T>.whenMatchesRules` — are now wired into each target field's per-field validator chain, mirroring the existing `whenRules` propagation. Sync rules add a closure to `_validators` (fast-path `if (!condition) return null` → `conditionalType.errors(...)` only when the predicate fires); async rules add the awaiting equivalent to `_asyncValidators` so `validateAsync()` can surface `whenMatches.then` async refines through `field.manualError` / `FormField.validator` instead of relying solely on the `_schemaFieldErrors` snapshot. Without this, async forms with a `whenMatches` async target produced no inline error from `validateAsync()` — only `safeParseAsync` saw the failure. **VObject adapter:** the typed predicate `bool Function(T)` is wrapped at the factory level into `bool Function(Map)` that constructs `T` via the user's `builder` and returns `false` when the builder throws `TypeError` on a partial form (same fragility we already handle in container-preprocess routing). Pinned by a new `Conditional validation (whenMatches)` test group covering VMap sync, VMap multi-field predicate, VMap async target, VObject typed predicate, and the VObject partial-form safety case.
- **`example/lib/pages/when_matches_page.dart`** — two side-by-side demos isolating what `whenMatches` enables over `when`: a numeric `>=` threshold (impossible with `equals:`) and a combined-field predicate (`role == 'admin' && level > 5`) that reads two fields in a single trigger.

## [2.1.1] - 2026-04-28

### Fixed

- **`VForm.object`'s `validate()` / `silentValidate()` no longer throw `TypeError` on partial / empty forms.** Previously, both methods invoked the user-supplied `builder` against the raw field snapshot _before_ running validation, which crashed whenever a builder dereferenced `data['key']` into a non-nullable parameter while another field was still null (the canonical Dart factory pattern, e.g. `User(name: data['name'], email: data['email'])` without `?? fallback`). The silent validators now wrap the canonical `object.safeParse(builder(raw))` path in a `TypeError` catch and fall back to per-field iteration over `object.schema` with raw values when the builder cannot construct `T`. Schema-level rules (`refine`, `refineField`, `refineFieldRaw`, `equalFields`, `whenRules`, container preprocess) still run on the canonical path whenever the builder succeeds, so existing schemas don't regress; partial forms now surface per-field "required" / type errors as expected instead of crashing.
- Container preprocess closures on `VForm.object` (`object.hasPreprocessors`) likewise tolerate partial snapshots: when `builder(snapshot)` throws, preprocess is skipped for that tick and the snapshot passes through unchanged. Once every field is filled in, the canonical pipeline reapplies preprocess on the next validation cycle.
- The fallback path re-throws the underlying `TypeError` when per-field validation passes for every field but the builder still cannot construct `T` — that combination can only mean a schema/class mismatch (e.g. a field declared `.nullable()` on the schema but non-nullable on the user's class). Surfacing the original error keeps such mismatches loud instead of silently reporting `silentValidate() == false` with an empty `errors()` map.

## [2.1.0] - 2026-04-27

### Fixed

- **`onValueChanged` no longer throws on incomplete `VForm.object` forms.** The form-level `onValueChanged` callback (and `addValueChangedListener` / `removeValueChangedListener`) now always delivers `Map<String, dynamic>` (raw field values), regardless of whether the form was created from a `VMap` or a `VObject<T>`. Previously, `VForm.object<T>` invoked the user-supplied `builder` against the partial field map on every field change, which threw `TypeError` whenever the builder dereferenced `data['key']` into a non-nullable parameter while other fields were still empty (the idiomatic Dart factory pattern). A field change does not imply the form is valid enough to construct `T`; consumers needing the typed value should call `form.value` / `form.valueAsync` after `form.validate()` returns `true`, or guard the `builder` with `??` defaults / nullable parameters.
- The previous async-form no-op restriction on value-changed listeners is removed — `rawValue` is sync-safe regardless of the schema's async pipeline, so the same callback shape now fires on sync and async forms alike.

## [2.0.0] - 2026-04-25

### Breaking Changes

- **Removed `VMap.refineFormField` extension and the supporting `Expando` / `VFieldValidator` class.** The valiform-specific extension predates validart's `refineField` and had subtly different semantics — `refineFormField` callback received `form.rawValue` (pre-pipeline) for the per-field channel but the parsed map for `silentValidate`, leading to divergence on schemas with field-level transforms. The two semantics are now provided cleanly by validart 2.0.0:
  - `V.map({...}).refineField(check, path: 'x')` → callback receives the **parsed** map (transforms applied). Recommended for the vast majority of cases.
  - `V.map({...}).refineFieldRaw(check, path: 'x')` → callback receives the **raw** input (post container preprocess + type check, before per-field iteration). Reach for it when the rule depends on the original input shape (case, whitespace, pre-coercion).

  Both surface inline under the target field thanks to the schema-error demux. **Migration:**
  - `V.map({...}).refineFormField(check, path: 'x', message: '...')`
    → `V.map({...}).refineField(check, path: 'x', message: '...')` — same result for callbacks that don't depend on case/whitespace.
  - If your callback compared raw values that get transformed by the field-level pipeline (e.g. `data['email']` against an expected literal when the field has `.toLowerCase()`), use `refineFieldRaw` instead.

  See updated `example/lib/pages/password_match_page.dart`, `complex_form_page.dart`, and the new `refine_field_raw_page.dart` for migration patterns.

### Required

- Bumped minimum `validart` constraint to `2.0.0`. New upstream APIs consumed:
  - `VFailure.rootMessages()` — root-level error extraction for the new banner channel.
  - `refine(..., dependsOn: {...})` on `VMap` / `VObject` for cross-field error aggregation.
  - Fluent `V.object<T>().field(...)` API (the `configure:` callback no longer exists upstream).
  - New `VObject` combinators: `equalFields`, `when`, `refineField`, `refineFieldRaw`, `pick`, `omit`, `merge`, `array`.
  - `VType.runPreprocessors` / `runPreprocessorsAsync` / `hasPreprocessors` — public accessors used by the container-preprocess routing fix below.
  - `VType.addRaw` — low-level hook backing `refineFieldRaw`.

### Added

- **`VForm.rootErrors` / `VForm.rootErrorsAsync`** — surface form-level errors emitted by schema-level `refine()` rules with no specific field path (date-range checks, totals, etc.). Self-contained getter: each access re-runs the schema-level `safeParse` against the current parsed values, so a `ListenableBuilder` on `form.listenable` keeps a banner in sync without a manual `silentValidate()` call. The async variant awaits each field's async pipeline before re-running `safeParseAsync` to catch `refineAsync(..., dependsOn:)` failures. Sync getter throws `VAsyncRequiredException` on async schemas — use `rootErrorsAsync`.
- **`example/lib/pages/object_validation_page.dart`** — three sections demoing the new `VObject` combinators on typed DTOs: `equalFields` (password match), `when` (US tax ID conditional), `refineField` (date-range with error pinned to a single field).
- **`example/lib/pages/root_errors_page.dart`** — `refine(..., dependsOn:)` with a banner rendering `form.rootErrors` alongside field-keyed errors. Demonstrates the aggregation introduced in validart 2.0.0 (when `dependsOn` is declared, the cross-field rule keeps running even when sibling fields fail individually).
- **`example/lib/pages/refine_field_raw_page.dart`** — interactive demo showing `refineField` and `refineFieldRaw` side-by-side with the same predicate (`code` length must be 8) and a `.trim().toUpperCase()` transform on the field. Same input → different verdicts. Use it as a template when deciding which API to reach for.
- New test groups in `test/src/form_test.dart` pinning the schema-error demux surface for both `refineField` and `refineFieldRaw` (path-keyed error reaches `field.error` / `form.errors()` / `field.validator`).

### Fixed

- **`VForm.object` now propagates `VObject.whenRules` into per-field validators**, matching the behaviour already in place for `VForm.map`. Previously, conditional rules declared on a `VObject` via `.when(...)` were silently ignored by the form layer (only the schema-level `validate(builder(raw))` saw them, but per-field `FormField.validator` did not), so `form.validate()` could return `true` for inputs the schema knew to be invalid. Pinned by a regression test in the `Conditional validation (when)` group.
- **`form.validate()` and `form.validateAsync()` now include schema-level rules in their return value.** Previously they delegated only to `FormState.validate()` (per-field `FormField.validator`), so a schema with `refine(..., dependsOn: {...})` or `equalFields(...)` could fail at the schema level while `validate()` still returned `true` — the consumer would then `submit()` data the schema rejected. The fix re-runs the silent schema validator after the per-field pass and returns `fieldsValid && schemaValid`. Behavioural consequence: code that previously had to write `if (form.validate() && form.silentValidate())` as a workaround can now drop the second clause; code that wasn't aware of the gap will start receiving `false` correctly when a root rule fails. Bundled cleanup of `example/lib/pages/{root_errors,password_match,object_validation}_page.dart` removes the workaround. Pinned by widget tests in the `Form-level (root) errors` group.
- **Schema-level errors with a non-empty path now surface inline under the target field.** Errors emitted by `VMap.refineField(check, path: 'x')`, `VObject<T>.refineField(check, path: 'x')`, or any nested-path schema construct previously landed only in the `safeParse` failure — `field.error`, `form.errors()`, and `FormField.validator` did not see them, so the UI showed no error even though `silentValidate()` returned `false`. `VForm` now demuxes the `VFailure` after every `validate*` / `silentValidate*` call: errors with a top-level path go to the corresponding `VField` (via a `schemaErrorLookup` closure consulted by `_runValidators`), errors with an empty path go to `form.rootErrors`. The lookup is on-demand for sync forms (re-runs the schema each time so it always reflects the current sibling values — O(N) per keystroke for schemas that actually have schema-level rules; pure schemas pay no cost). Async forms use a snapshot refreshed by `validateAsync` / `silentValidateAsync`.
- **Container `preprocess()` now reaches the per-field validator**, mirroring the order in `VMap.safeParse` / `VObject.safeParse`: `container preprocess → field preprocess → field validators → field transforms`. Previously, container preprocess only ran inside `safeParse` direct (the schema-level path), while each `VField` knew only its own `_type` and ran its pipeline without any awareness of the parent. Result: `form.validator(value)` and `form.silentValidate()` could disagree, with the UI displaying an error that the schema had already "fixed" via preprocess. Now both paths agree. The canonical use case is cross-field rewrites — e.g. `V.map({...}).preprocess((m) => m['country'] == 'US' ? {...m, 'state': m['state'].toUpperCase()} : m)` — which no per-field transform can express because a field doesn't see its siblings. **Limit:** when the container has only `preprocessAsync`, the sync `field.validator` continues to fall through (it cannot await) — use `form.validateAsync` for the full async pipeline. Implementation: each `VField` receives a snapshot-and-preprocess closure that mounts the full sibling map, runs `container.runPreprocessors`, and reads back the field's slot. Schemas without container preprocess (the common case) pay zero overhead — gated on `VType.hasPreprocessors`.

### Changed

- **`example/lib/pages/object_form_page.dart`** migrated to validart 2.0.0's fluent `V.object<T>().field(...)` API. The `configure:` callback no longer exists upstream — see the validart 2.0.0 changelog for the migration.

### Notes

- All other behavior from valiform 1.x stays compatible. `VForm`, `VField`, `attachController`, `attachTextController`, `validate` / `validateAsync` semantics — all unchanged outside of the bullets above.
- **Internal:** `VForm`'s silent validators changed signature from `bool Function(...)` / `Future<bool> Function(...)` to `(bool, List<String>, Map<String, String>) Function(...)` / `Future<(bool, List<String>, Map<String, String>)> Function(...)` so they can carry the validity flag, root messages, and the schema field-error demux in a single pass. Public API unchanged — only relevant if you were extending `VForm` directly (which is unusual; `VForm` is `final` in spirit).
- **Internal:** `_runWithRoot` (the schema-error demux helper) delegates root-message extraction to `VFailure.rootMessages()` instead of duplicating the loop. Field-message demux stays custom because it routes by top-level segment (`path.first`) to match `VForm._fields`'s top-level indexing — `VFailure.toMapFirst()` keys by `pathString` (joined with `.`) which would mis-route nested errors.

## [1.2.0] - 2026-04-23

### Changed

- Bumped minimum `validart` constraint to `1.3.0` for the domain-prefixed error-code format (`string.email`, `number.positive`, `int.even`, ...) introduced in validart 1.2.0 and the `V.coerce.date()` multi-format parsing added in 1.3.0. No API surface of valiform itself changed — the generic `VForm<T>` / `VField<T>` contract stays identical.
- **Example — `locale_page.dart` PT-BR map migrated to the nested type-prefixed shape.** Every validator's translation now lives under its owning type group (`'string': { 'email': '...' }`, `'int': { 'even': '...' }`, `'enum': { 'invalid': '...' }`, ...). The legacy flat keys (`'invalid_email'`, `'positive'`, `'even'`, `'weekday'`, `'invalid_enum'`, ...) were emitted by validart ≤ 1.1.0 but no longer match any code emitted by 1.2.0+, so the previous map silently fell back to English for most validators. `required`, `invalid_type` and `custom` stay flat as documented global fallbacks.

## [1.1.0] - 2026-04-22

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
- **`VField.initialValue` getter** — exposes the stable initial value resolved at form construction (`initialValues[key]` → `schema.defaultValue` → `null`). Prefer binding widgets' `initialValue` parameter to this getter instead of `VField.value` so `FormField.reset()` always targets the true starting point, even when the widget tree rebuilds during typing.

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
