# Changelog

## 0.3.1

- Depends on `is_shapes` `>=0.4.0 <0.6.0`, so it resolves beside 0.5.0, where
  `JourneyId` is `MissionId` and `JourneyPathId` is `TrajectoryId`. This
  package uses none of the names 0.5.0 renamed or removed.

## 0.3.0

- **Breaking:** every type is named for what it is. The annotations are
  `NodeComment`, `NodeCorrection<V>`, `NodeApproval` and `NodeSeenMark`
  (were `Comment`, `Correction<V>`, `Approval` and `Seen`), and a
  `Withdrawal<Approval>` is a `Withdrawal<NodeApproval>`.
- **Breaking:** `Response` is `VerdictOnShownMessage`: a person's call on
  something shown to them. Its cases are `ApprovedVerdict`, `HeldOffVerdict`
  and `ProposedCorrectionVerdict` (were `Approved`, `HeldOff` and `Proposed`).
- `VerdictOnShownMessage.fromJson` and `toJson()`: a verdict as JSON in a
  node's map form, `{"shape": "<class name>", ...its fields}`, so it can
  travel already built from the process that reads a press to the one that
  builds its annotations. Reading is strict: an unknown shape, or a field
  missing, extra or of the wrong type, is a `FormatException`. Depends on
  `checked_json`.
- Docs: "pass" is gone. A node is named three ways, by its anchor (what it
  is about), its version (what it says) and its exact id (which one
  exactly), in `is_shapes`' words, and each rule is a comparison of two:
  an annotation holds for a later node at its anchor with the same version.
- `VerdictOnShownMessage.shapeNames`, built from each case's `shapeName`,
  which `fromJson` matches on: every `shape` a verdict decodes from, for
  checking that no two packages' node shapes collide.

## 0.2.1

- `Response`: what a person said back to something shown to them, before
  anyone knows which node it was. It is `Approved`, `HeldOff` or `Proposed`
  with the text fields their client sent, and has no target and no author,
  for a module that knows only which message was pressed
  (https://github.com/intersyntactic/docking_port/pull/1).

## 0.2.0

- **Breaking:** `Approve` is renamed `Approval`, so the withdrawable shapes
  are all nouns: `Comment`, `Correction`, `Approval`.
- **Breaking:** depends on `is_shapes` ^0.4.0, where `Withdraw<T>` is
  `Withdrawal<T>`.

## 0.1.1

- Docs: a version leaves out the whole history its exact id names, in the
  words `TurnId` uses in `is_shapes` 0.3.1.

## 0.1.0

- First release: `Comment`, `Correction<V extends Value>`, `Approve` and
  `Seen`, built on `is_shapes`.
