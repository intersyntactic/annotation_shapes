/// Annotation shapes: a comment, a correction, an approval and a mark that a
/// node was seen. An annotation is a node an actor writes beside another node:
/// it points at that node and never changes it, as in the W3C Web Annotation
/// model (https://www.w3.org/TR/annotation-model/). A module needs them when
/// actors annotate its nodes.
///
/// Dart matches classes by name. A module that declared its own `Approve`
/// would make a type no other module's `Approve` can be assigned to, so one
/// module's approval could never bind where another waits for one. So they
/// are declared once, here, for every module whose nodes are annotated
/// (https://github.com/enspyrco/intersyntactic/issues/1073).
///
/// - [Comment]: a thought on a node, proposing no change to it.
/// - [Correction]: a proposed new value for a node.
/// - [Approve]: an approval of a node.
/// - [Seen]: a mark that an actor has seen a node.
///
/// A version of a node is what it says: its shape and its fields, without the
/// path its exact id also names. A new pass gives every node a new exact id,
/// and a new version only where something changed. An annotation is of the
/// version at its target's exact id, and holds for a later pass while the node
/// now at its anchor says the same. Whatever an actor has written of a version,
/// on any pass and withdrawn or not, shows they considered it.
///
/// A comment, a correction or an approval can be taken back by its author:
/// they are `Withdrawable`, and a `Withdraw` of one is final. A `Seen` is
/// not: what has been seen stays seen. What they point at and who wrote them,
/// the `Value` a correction proposes, and the `Withdraw<T>` that takes one
/// back, come from `is_shapes`.
///
/// It imports only `is_shapes`, so a shape file may import it under import
/// admission's pure list once both are on it
/// (https://github.com/enspyrco/intersyntactic/issues/1046).
library;

import 'package:is_shapes/is_shapes.dart';

/// A thought on the node at [target], by [by], proposing no change to it.
final class Comment implements Withdrawable {
  const Comment({required this.target, required this.text, required this.by});

  /// What the comment is on.
  final Target target;

  /// What it says.
  final String text;

  /// Who wrote it.
  final ActorId by;
}

/// A proposed new value, by [by], for the node at [target].
///
/// [V] is the value type of the shape being corrected. An acceptor that
/// applies corrections to forecasts accepts `Correction<Outlook>`, and the
/// analyzer refuses a correction to any other value type bound to it, even
/// one with the same fields.
///
/// It proposes; it changes nothing. The acceptor applying it fetches the node
/// at the target's exact id and the node now at its anchor, and holds the
/// correction for a fresh approval if they differ in what it depends on. The
/// corrected node is never rewritten: the correction folds into the next
/// pass.
final class Correction<V extends Value> implements Withdrawable {
  const Correction({
    required this.target,
    required this.proposed,
    required this.by,
  });

  /// The node to be corrected.
  final Target target;

  /// The value proposed for it, of its own shape's value type.
  final V proposed;

  /// Who proposed it.
  final ActorId by;
}

/// An approval, by [by], of the node at [target]: a correction, or a
/// question-shaped node.
///
/// Whose approval counts is decided by readers, not by this type. An approval
/// is never changed once written. It is taken back by a later
/// `Withdraw<Approve>` from its author. It approves a version, so a pass that
/// changes what the node says needs a fresh approval.
///
/// An actor may hold several approvals of one version: approving twice writes
/// two, and an approval of an earlier pass stands for a later one that says the
/// same. Each is its own node, and a withdrawal takes back only the one whose
/// id it names. The version stays approved by that actor while any of theirs
/// stands, so to take their approval back a module withdraws every one.
final class Approve implements Withdrawable {
  const Approve({required this.target, required this.by});

  /// What is approved.
  final Target target;

  /// Who approved it.
  final ActorId by;
}

/// A mark, by [by], that they have seen the node at [target]: they considered
/// that version, and the mark says nothing more. So a version an actor has
/// seen and not approved is one they looked at and held off on.
///
/// Its author writes it by choosing to. An actor holding off on a version they
/// approved writes a Seen and withdraws their standing approvals of it. It is
/// not `Withdrawable`: what has been seen stays seen, and what its author
/// writes next, an approval or a comment, says more.
final class Seen {
  const Seen({required this.target, required this.by});

  /// What was seen.
  final Target target;

  /// Who saw it.
  final ActorId by;
}
