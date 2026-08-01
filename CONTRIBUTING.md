# Contributing

Thanks for taking the time. This document is the contract for whoever writes code here —
the `README.md` is the contract for whoever uses `valiform`.

## Before you open a PR

One command has to be green:

```bash
./scripts/verify.sh
```

It is the same script the release runs, minus tag, push and publish: dependencies, the
README version pins, the CHANGELOG entry, analyze (package and example app), tests, the
examples inside the `///` docs, `dart doc` with zero warnings, the publish dry-run, and a
pana score of 160/160. If it passes locally it passes in CI, because CI runs that file and
nothing else.

It needs network (it asks pub.dev which pana version to use) and a Flutter at or above the
floor declared in `pubspec.yaml`. Running it changes your globally activated pana version —
pub.dev always scores with the newest one, so the script installs exactly that.

**Two pins, not one.** The README's `## Installation` block pins `valiform` at the exact
`pubspec.yaml` version *and* `validart` at the exact constraint `pubspec.yaml` requires.
Both packages are installed side by side, so a stale `validart` line in the README hands
copy-paste users a resolution they cannot build. `verify.sh` refuses to continue on either
mismatch.

## What CI checks

Two jobs, both on every pull request:

- **Verify** — `./scripts/verify.sh` on the current stable Flutter.
- **Floor** — analyze, test and analyze the example app on the **lowest** Flutter
  `valiform` supports, read straight from `pubspec.yaml`. It exists because nothing else
  catches it: the Flutter framework carries no `@Since` annotations, so an API added after
  the floor looks perfectly valid to an analyzer running on a newer SDK, and only breaks
  for the users we promised to support.

## Conventions

- **No `//` comments.** A fact that needs recording goes in the commit message, in the
  README, or in a test. Analyzer directives (`// ignore:`) are not comments and may stay.
- **`///` dartdoc is mandatory on every public member**, in English, with a runnable
  example. `public_member_api_docs` is enforced, and `scripts/verify_doc_examples.sh`
  compiles every ```dart fence found in `lib/`.
- **Behavior changes ship with their test.** Bug fixes start red: write the failing test
  first, watch it fail for the right reason, then fix.
- **A public-API change updates README, CHANGELOG and `example/lib/` in the same commit.**
  A new page under `example/lib/pages/` is wired into the `main.dart` menu and gets a row
  in the README's "Example App" table, in the same order.
- **Cross-cutting validation semantics are linked, not copied.** Pipeline order, refine
  semantics and preprocess are documented exhaustively in the
  [validart README](https://github.com/edunatalec/validart#readme); valiform links to the
  anchor and adds only what is valiform-specific. Duplicating the prose makes the two
  READMEs drift.
- **Commits are conventional and lowercase**: `feat:`, `fix:`, `chore:`, `docs:`. No body,
  no co-author trailers.

## Deliberate gaps

These are absent by decision, not by omission — a PR adding one will be declined.

- **No wrapper widget.** Flutter forms are widget-driven: the widget owns its state through
  `FormFieldState`, and valiform stays out of that. You opt into two-way sync with a
  controller (`attachController` / `attachTextController`) or a `ListenableBuilder`. The
  price is that sync is not free; the payoff is that any widget tree and any design-system
  input works, and fields you never mutate programmatically cost nothing.
- **The barrel does not re-export validart.** `package:valiform/valiform.dart` exports
  `VField`, `VForm` and the two `form()` extensions, and nothing else. Schemas come from
  `package:validart/validart.dart` under their own import, so the boundary between the two
  packages stays visible at the top of every file.

## Releasing

Releases are cut by the maintainer, from `master`, with `./scripts/release.sh`. It refuses
to run outside `master` or with a dirty working tree — `pub publish` packs the files on
disk, not the commit — then runs the full `verify.sh` before tagging. Nothing publishes
from CI.
