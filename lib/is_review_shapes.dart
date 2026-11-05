/// The shapes a person reviews with, declared once so that every
/// intersyntactic module imports the same ones.
///
/// Dart matches classes by name. A module that declared its own `Approve`
/// would make a type no other module's `Approve` can be assigned to, so a
/// Slack reaction could never bind where Hart waits for an approval
/// (https://github.com/enspyrco/intersyntactic/issues/1073).
///
/// - [Comment]: a thought on a node, proposing no change to it.
/// - [Correction]: a proposed new verdict for a node.
/// - [Approve]: an approval of a node.
/// - [Withdraw]: takes back a node its author wrote.
/// - [Verdict]: what a node concludes. Each module declares its own verdicts
///   by extending it.
/// - [identity]: marks the fields a node is about.
/// - The ids these hold: [TurnId], [SemanticAnchor], the [Target] made of the
///   two, and [PartyId].
///
/// An id is a class with a library-private constructor, made only by `parse`,
/// which returns null for a malformed one. So code holding one never asks
/// whether it is well formed. Classes, not extension types, since a `String`
/// can be cast to an extension type and skip every check.
///
/// It imports nothing, so a shape file may import it under import admission's
/// pure list (https://github.com/enspyrco/intersyntactic/issues/1046).
library;

final _sha256Hex = RegExp(r'^[0-9a-f]{64}$');
final _printableAscii = RegExp(r'^[\x21-\x7e]+$');

/// Marks a field of a shape as identity: what the node is about. Every other
/// field is a verdict: what the node concludes.
///
/// ```dart
/// final class Rung {
///   const Rung({required this.failureMode, required this.verdict});
///   @identity
///   final String failureMode;
///   final RungVerdict verdict;
/// }
/// ```
///
/// A shape with no field marked has every field as identity. So revision is
/// opt-in: a field is a verdict, which a later pass may change, only when its
/// shape says so (https://github.com/enspyrco/intersyntactic/issues/1068).
///
/// Nothing runs it. The analyzer reads it from a shape file's source, by its
/// type, [Identity] (https://github.com/enspyrco/intersyntactic/issues/1069).
/// Only a field's annotations are read.
const identity = Identity._();

/// The type of [identity]. Its constructor is private, so [identity] is the
/// only one, and a reader looking for the annotation looks for this type.
final class Identity {
  const Identity._();
}

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
/// It proposes; it changes nothing. The acceptor applying it checks [target]
/// first (see [Target]), and the corrected node is never rewritten: the
/// correction folds into the next pass.
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

/// Takes back a [T]: the node at [target], which [by] wrote.
///
/// A node is never changed once written, so taking one back is a new node.
/// Readers apply one rule to every shape: an `X` counts while no later
/// `Withdraw<X>` from its author targets it. A withdrawal by anyone else
/// counts for nothing, so a reader checks that [by] wrote [target].
///
/// [T] says what is taken back, so an acceptor waiting on withdrawn approvals
/// accepts `Withdraw<Approve>` and is never handed a withdrawn Slack reaction.
/// No field holds a [T], so nothing here checks that [target] is one; the
/// reader that fetches [target] does.
///
/// [target] is the exact node, not an anchor: what is taken back is the one
/// node its author wrote, not whatever is at its anchor in a later pass.
final class Withdraw<T extends Object> {
  const Withdraw({required this.target, required this.by});

  /// The node taken back.
  final TurnId target;

  /// Who took it back. It counts only if this is who wrote [target].
  final PartyId by;
}

/// What a review points at: the exact node a person saw, and its anchor.
///
/// An acceptor applying a correction uses both. It fetches the node at
/// [exact] and the node now at [anchor], and holds the correction for a fresh
/// approval if they differ in what the correction depends on, since two
/// different nodes may have come to share an anchor. That check is the
/// acceptor's, not these types'.
final class Target {
  const Target({required this.exact, required this.anchor});

  /// The node the person saw.
  final TurnId exact;

  /// The same node, in any pass.
  final SemanticAnchor anchor;

  @override
  bool operator ==(Object other) =>
      other is Target && other.exact == exact && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(exact, anchor);
}

/// A sha256 used as a name, written as lower-case hex. Each kind of name
/// extends it, and two kinds with the same hex are never equal, so one can't
/// be passed or compared as the other.
sealed class _Sha256Hex {
  const _Sha256Hex(this.hex);

  /// The sha256 in lower-case hex: 64 characters.
  final String hex;

  /// Equal only to the same kind of name with the same hex.
  @override
  bool operator ==(Object other) =>
      other is _Sha256Hex &&
      other.runtimeType == runtimeType &&
      other.hex == hex;

  @override
  int get hashCode => Object.hash(runtimeType, hex);

  @override
  String toString() => hex;
}

/// The exact node a person saw.
///
/// A node's id is a hash of its parent's id and its own bytes, like a git
/// commit, so it names the node's whole path. Two nodes with the same fields
/// in different places have different ids.
///
/// Only [parse] makes one here. What mints a node's id is the line, which
/// hashes the node; this package never sees a node's bytes.
final class TurnId extends _Sha256Hex {
  const TurnId._(super.hex);

  /// [s] as a turn id, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static TurnId? parse(String s) => _sha256Hex.hasMatch(s) ? TurnId._(s) : null;
}

/// The same node in any pass: hashed from its shape and its identity fields,
/// never its parent or its verdicts. So a correction made on one pass still
/// finds its node in the next, where the verdict has changed and the identity
/// has not.
///
/// How the hash is taken is the shape language's to say
/// (https://github.com/enspyrco/intersyntactic/issues/1068). This type only
/// holds it.
final class SemanticAnchor extends _Sha256Hex {
  const SemanticAnchor._(super.hex);

  /// [s] as an anchor, read back from text; null unless it is a sha256 in
  /// lower-case hex.
  static SemanticAnchor? parse(String s) =>
      _sha256Hex.hasMatch(s) ? SemanticAnchor._(s) : null;
}

/// Who wrote a node: a person, or an agent.
///
/// What a party is, and whether the roster names it, is still open
/// (https://github.com/enspyrco/intersyntactic/issues/1073). Until that is
/// settled, a party id is printable ASCII with no spaces, such as a Slack user
/// id or a roster key. That is narrow on purpose: allowing more later breaks
/// no id already written, and allowing less would.
///
/// It holds an id, never a display name: a name may have spaces in it, and
/// may change.
final class PartyId {
  const PartyId._(this.value);

  /// The id, as text.
  final String value;

  /// [s] as a party id, read back from text; null unless it is one or more
  /// printable ASCII characters, none of them a space.
  static PartyId? parse(String s) =>
      _printableAscii.hasMatch(s) ? PartyId._(s) : null;

  @override
  bool operator ==(Object other) => other is PartyId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
