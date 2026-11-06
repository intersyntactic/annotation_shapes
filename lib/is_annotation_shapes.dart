/// Annotation shapes: a comment, a correction and an approval. An annotation
/// is a node a party writes beside another node: it points at that node and
/// never changes it, as in the W3C Web Annotation model
/// (https://www.w3.org/TR/annotation-model/). A module needs them when
/// parties annotate its nodes, as Hart's corrections to a rung and Slack's
/// consent by reaction do.
///
/// Dart matches classes by name. A module that declared its own `Approve`
/// would make a type no other module's `Approve` can be assigned to, so a
/// Slack reaction could never bind where Hart waits for an approval. So they
/// are declared once, here, for every module whose nodes are annotated
/// (https://github.com/enspyrco/intersyntactic/issues/1073).
///
/// - [Comment]: a thought on a node, proposing no change to it.
/// - [Correction]: a proposed new value for a node.
/// - [Approve]: an approval of a node.
///
/// Each can be taken back by its author: they are `Withdrawable`, and a
/// `Withdraw` of one is final. What they point at and who wrote them, the
/// `Value` a correction proposes, and the `Withdraw<T>` that takes one back,
/// come from `is_shapes`.
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
  final PartyId by;
}

/// A proposed new value, by [by], for the node at [target].
///
/// [V] is the value type of the shape being corrected. An acceptor that
/// applies corrections to rungs accepts `Correction<RungVerdict>`, and the
/// analyzer refuses a `Correction<SectionVerdict>` bound to it, even when the
/// two values have the same fields.
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
  final PartyId by;
}

/// An approval, by [by], of the node at [target]: a correction, or a
/// question-shaped node.
///
/// Whose approval counts is decided by readers, not by this type. An approval
/// is never changed once written. It is taken back by a later
/// `Withdraw<Approve>` from its author.
final class Approve implements Withdrawable {
  const Approve({required this.target, required this.by});

  /// What is approved.
  final Target target;

  /// Who approved it.
  final PartyId by;
}
