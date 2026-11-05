/// The shapes a person reviews with: a comment, a correction, an approval,
/// and the verdict a correction proposes. A module needs them when a person
/// judges something in it, as Hart's corrections to a rung and Slack's
/// consent by reaction do.
///
/// Dart matches classes by name. A module that declared its own `Approve`
/// would make a type no other module's `Approve` can be assigned to, so a
/// Slack reaction could never bind where Hart waits for an approval. So they
/// are declared once, here, for every module that reviews
/// (https://github.com/enspyrco/intersyntactic/issues/1073).
///
/// - [Comment]: a thought on a node, proposing no change to it.
/// - [Correction]: a proposed new verdict for a node.
/// - [Approve]: an approval of a node.
/// - [Verdict]: what a node concludes. Each module declares its own verdicts
///   by extending it.
///
/// What they point at and who wrote them, and the `Withdraw<T>` that takes
/// one back, come from `is_shapes`.
///
/// It imports only `is_shapes`, so a shape file may import it under import
/// admission's pure list once both are on it
/// (https://github.com/enspyrco/intersyntactic/issues/1046).
library;

import 'package:is_shapes/is_shapes.dart';

/// What a node concludes: the fields a correction may change.
///
/// Each shape that can be corrected declares its own verdict, as a class
/// extending this one:
///
/// ```dart
/// final class RungVerdict extends Verdict {
///   const RungVerdict(this.level, this.rationale);
///   final RungLevel level;
///   final String rationale;
/// }
/// ```
///
/// A [Correction] is generic over the verdict it proposes, bounded by this
/// class. Classes match by name, so the analyzer refuses a correction that
/// proposes one shape's verdict to another, even when their fields are the
/// same. A record or an extension type can't extend a class, so neither can be
/// a verdict; and a class survives at run time, so a delivered verdict can be
/// checked with `is`.
///
/// It is `base`, so another library can extend it but never implement it. It
/// is not `sealed`, since only its own library could extend a sealed class,
/// and every module declares its own verdicts.
abstract base class Verdict {
  const Verdict();
}

/// A thought on the node at [target], by [by], proposing no change to it.
final class Comment {
  const Comment({required this.target, required this.text, required this.by});

  /// What the comment is on.
  final Target target;

  /// What it says.
  final String text;

  /// Who wrote it.
  final PartyId by;
}

/// A proposed new verdict, by [by], for the node at [target].
///
/// [V] is the verdict type of the shape being corrected. An acceptor that
/// applies corrections to rungs accepts `Correction<RungVerdict>`, and the
/// analyzer refuses a `Correction<SectionVerdict>` bound to it, even when the
/// two verdicts have the same fields. Declare a verdict `final`: a verdict
/// with subclasses would let a correction proposing a subclass bind where its
/// parent is accepted.
///
/// It proposes; it changes nothing. The acceptor applying it fetches the node
/// at the target's exact id and the node now at its anchor, and holds the
/// correction for a fresh approval if they differ in what it depends on. The
/// corrected node is never rewritten: the correction folds into the next
/// pass.
final class Correction<V extends Verdict> {
  const Correction({
    required this.target,
    required this.proposed,
    required this.by,
  });

  /// The node to be corrected.
  final Target target;

  /// The verdict proposed for it, of its own shape's verdict type.
  final V proposed;

  /// Who proposed it.
  final PartyId by;
}

/// An approval, by [by], of the node at [target]: a correction, or a
/// question-shaped node.
///
/// Whose approval counts is decided by readers, against the roster, not by
/// this type. An approval is never changed once written. It is taken back by
/// a later `Withdraw<Approve>` from its author.
final class Approve {
  const Approve({required this.target, required this.by});

  /// What is approved.
  final Target target;

  /// Who approved it.
  final PartyId by;
}
