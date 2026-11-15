# Changelog

## 0.2.1

- `Response`: what a person said back to something shown to them, before
  anyone knows which node it was. It is `Approved`, `HeldOff` or
  `Proposed<V extends Value>`, and has no target and no author, for a module
  that knows only which message was pressed
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
