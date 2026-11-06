# is_annotation_shapes

Annotation shapes for intersyntactic: a comment, a correction to a node's
value, and an approval. An annotation is a node a party writes beside another
node: it points at that node and never changes it, as in the
[W3C Web Annotation model](https://www.w3.org/TR/annotation-model/). A module
needs them when parties annotate its nodes, as Hart's corrections to a rung
and Slack's consent by reaction do. A module that only declares shapes needs
[`is_shapes`](https://github.com/intersyntactic/shapes) alone.

A shape is a Dart type, and binding an offering to an acceptor is the analyzer
checking that one type can be assigned to the other
([#1069](https://github.com/enspyrco/intersyntactic/issues/1069)). Dart
matches classes by name, so if Hart and Slack each declared an `Approve`, a
Slack reaction could never bind where Hart waits for an approval. They are
declared once, here, for every module whose nodes are annotated
([#1073](https://github.com/enspyrco/intersyntactic/issues/1073)).

```dart
import 'package:is_annotation_shapes/is_annotation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';

/// A rung's value, which Hart calls its verdict: what a correction may change.
final class RungVerdict extends Value {
  const RungVerdict(this.level, this.rationale);
  final RungLevel level;
  final String rationale;
}

/// A rung is about its failure mode; its value may change from pass to pass.
final class Rung {
  const Rung({required this.failureMode, required this.verdict});
  @identity
  final String failureMode;
  final RungVerdict verdict;
}

// An acceptor that applies corrections to rungs takes Correction<RungVerdict>.
```

## What is here

- `Comment`: a thought on a node, by a party, proposing no change to it.
- `Correction<V extends Value>`: a proposed new value for a node, of that
  node's own value type. An acceptor for `Correction<RungVerdict>` refuses a
  `Correction<SectionVerdict>` at composition, even when the two values have
  the same fields. It proposes; the corrected node is never rewritten.
- `Approve`: an approval of a node, by a party. It is never changed once
  written; it is taken back by a later `Withdraw<Approve>` from its author.

Each is `Withdrawable`: its author can take it back with a `Withdraw`, and a
withdrawal is final. What they point at (`Target`), who wrote them
(`PartyId`), the `Value` a
correction proposes, and the `Withdraw<T>` that takes one back all come from
`is_shapes`. `Value` is there, not here, because it is `@identity`'s other
half: every field a shape doesn't mark as identity is its value.

## The pure list

A shape file may import only what import admission's pure list allows
([#1046](https://github.com/enspyrco/intersyntactic/issues/1046)). This
package imports only `is_shapes`, and both have to be added to that list.
`test/pure_list_test.dart` holds it to the list, reading every branch of every
import and export from the parse tree.

## Depending on it

It isn't published yet. Until it is:

```yaml
dependencies:
  is_shapes: ^0.1.0
  is_annotation_shapes:
    git: git@github.com:intersyntactic/annotation_shapes.git
```
