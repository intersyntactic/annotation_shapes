# is_review_shapes

The shapes a person reviews with, declared once so that every intersyntactic
module imports the same ones.

A shape is a Dart type, and binding an offering to an acceptor is the analyzer
checking that one type can be assigned to the other
([#1069](https://github.com/enspyrco/intersyntactic/issues/1069)). Dart
matches classes by name, so if Hart and Slack each declared an `Approve`, a
Slack reaction could never bind where Hart waits for an approval. They are
declared here instead
([#1073](https://github.com/enspyrco/intersyntactic/issues/1073)).

```dart
import 'package:is_review_shapes/is_review_shapes.dart';

/// What a rung concludes: the fields a correction to it may change.
final class RungVerdict extends Verdict {
  const RungVerdict(this.level, this.rationale);
  final RungLevel level;
  final String rationale;
}

/// A rung is about its failure mode; its verdict may change from pass to pass.
final class Rung {
  const Rung({required this.failureMode, required this.verdict});
  @identity
  final String failureMode;
  final RungVerdict verdict;
}
```

## What is here

- `Comment`: a thought on a node, by a party, proposing no change to it.
- `Correction<V extends Verdict>`: a proposed new verdict for a node, of that
  node's own verdict type. An acceptor for `Correction<RungVerdict>` refuses
  a `Correction<SectionVerdict>` at composition, even when the two verdicts
  have the same fields. It proposes; the corrected node is never rewritten.
- `Approve`: an approval of a node, by a party. It is never changed once
  written; it is taken back by a later `Withdraw<Approve>` from its author.
- `Verdict`: what a node concludes, the fields a correction may change. Each
  module declares its own verdicts by extending it. It is `abstract base`:
  another library can extend it but not implement it, and a record or an
  extension type can't be one. (Not `sealed`, which would let only this
  library declare verdicts.)
- `@identity`: marks a field as what the node is about. Every other field is a
  verdict. A shape with no field marked has every field as identity, so
  revision is opt-in
  ([#1068](https://github.com/enspyrco/intersyntactic/issues/1068)). The
  analyzer reads it from source by its type, `Identity`, without running
  anything.
- The ids these hold: `TurnId` (the exact node a person saw), `SemanticAnchor`
  (the same node in any pass), `Target` (the two together), and `PartyId` (who
  wrote a node).

Every id is a class with a library-private constructor, made only by `parse`,
which returns null for a malformed one
([enspyrco/intersyntactic#1082](https://github.com/enspyrco/intersyntactic/pull/1082)).
Code that holds one never asks whether it is well formed. They are classes, not
extension types, because a `String` can be cast to an extension type and skip
the check.

## Coming next

- `Withdraw<T>`: takes back a `T`. Readers apply one rule everywhere: an `X`
  counts while no later `Withdraw<X>` from its author targets it.

## Still open

- **What a party is.** `PartyId` is printable ASCII with no spaces until the
  roster settles it. That is narrow on purpose: allowing more later breaks no
  id already written, and allowing less would. It holds an id, never a display
  name. Every id the Slack module writes fits it (Slack's own `U…`, `T…:U…`,
  `B…`, and agent ids like `slack:c0`).
- **How a node becomes bytes.** There is no `toJson` yet. The line mints a
  `TurnId` by hashing a node, and a `SemanticAnchor` by hashing its shape and
  identity fields, so the encoding belongs with that hash, not here.

## The pure list

A shape file may import only what import admission's pure list allows
([#1046](https://github.com/enspyrco/intersyntactic/issues/1046)), so this
package imports nothing at all. `test/pure_list_test.dart` holds it to the
list, and it reads every branch of a conditional import, not only the first.

## Depending on it

It isn't published yet. Until it is:

```yaml
dependencies:
  is_review_shapes:
    git: git@github.com:intersyntactic/review_shapes.git
```
