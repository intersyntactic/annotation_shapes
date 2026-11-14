# is_annotation_shapes

Annotation shapes for intersyntactic: a comment, a correction to a node's value,
an approval and a mark that a node was seen. An annotation is a node an actor
writes beside another node: it points at that node and never changes it, as in
the [W3C Web Annotation model](https://www.w3.org/TR/annotation-model/). A
module needs them when actors annotate its nodes. A module that only declares
shapes needs [`is_shapes`](https://github.com/intersyntactic/shapes) alone.

A shape is a Dart type, and binding an offering to an acceptor is the analyzer
checking that one type can be assigned to the other
([#1069](https://github.com/enspyrco/intersyntactic/issues/1069)). A
Dart class is its declaration, so if two modules each declared an `Approval`,
they would hold two types, and one module's approval could never bind where
the other waits for one. They are declared once, here, for every module whose
nodes are annotated
([#1073](https://github.com/enspyrco/intersyntactic/issues/1073)).

```dart
import 'package:is_annotation_shapes/is_annotation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';

/// A forecast's value: what a correction may change.
final class Outlook extends Value {
  const Outlook(this.weather, this.reason);
  final Weather weather;
  final String reason;
}

/// A forecast is about its day; its outlook may change from pass to pass.
final class Forecast {
  const Forecast({required this.day, required this.outlook});
  @identity
  final String day;
  final Outlook outlook;
}

// An acceptor that applies corrections to forecasts takes Correction<Outlook>.
```

## What is here

- `Comment`: a thought on a node, by an actor, proposing no change to it.
- `Correction<V extends Value>`: a proposed new value for a node, of that
  node's own value type. An acceptor for `Correction<Outlook>` refuses a
  correction to any other value type at composition, even one with the same
  fields. It proposes; the corrected node is never rewritten.
- `Approval`: an approval of a node, by an actor. It is never changed once
  written; it is taken back by a later `Withdrawal<Approval>` from its author.
- `Seen`: a mark, by an actor, that they have seen a node and considered that
  version. A version they have seen and not approved is one they looked at and
  held off on.

A version of a node is what it says: its shape and its fields, without the
whole history its exact id also names. A new pass gives every node a new exact
id, and a new version only where something changed. An annotation is of the
version at its target's exact id, and holds for a later pass while the node now
at its anchor says the same. Whatever an actor has written of a version, on any
pass and withdrawn or not, shows they considered it.

A comment, a correction or an approval is `Withdrawable`: its author can take it
back with a `Withdrawal`, and a withdrawal is final. A `Seen` is not: what has
been seen stays seen. What they point at (`Target`), who wrote them (`ActorId`),
the `Value` a correction proposes, and the `Withdrawal<T>` that takes one back
all come from `is_shapes`. `Value` is there, not here, because it is
`@identity`'s other half: every field a shape doesn't mark as identity is its
value.

## The pure list

A shape file may import only what import admission's pure list allows
([#1046](https://github.com/enspyrco/intersyntactic/issues/1046)). This
package imports only `is_shapes`, and both have to be added to that list.
`test/pure_list_test.dart` holds it to the list, reading every branch of every
import and export from the parse tree.

## Depending on it

A module that annotates also names `Target` and `ActorId`, so it depends on
`is_shapes` too:

```yaml
dependencies:
  is_annotation_shapes: ^0.2.0
  is_shapes: ^0.4.0
```
