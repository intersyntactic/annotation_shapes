/// Annotation shapes: a comment, a correction, an approval and a mark that a
/// node was seen. An annotation is a node an actor writes beside another node:
/// it points at that node and never changes it, as in the W3C Web Annotation
/// model (https://www.w3.org/TR/annotation-model/). A module needs them when
/// actors annotate its nodes.
///
/// A Dart class is its declaration: two classes with one name, declared in
/// two libraries, are two types. A module that declared its own
/// `NodeApproval` would make a type no other module's `NodeApproval` can be
/// assigned to, so one module's approval could never bind where another waits
/// for one. So they
/// are declared once, here, for every module whose nodes are annotated
/// (https://github.com/enspyrco/intersyntactic/issues/1073).
///
/// - [NodeComment]: a thought on a node, proposing no change to it.
/// - [NodeCorrection]: a proposed new value for a node.
/// - [NodeApproval]: an approval of a node.
/// - [NodeSeenMark]: a mark that an actor has seen a node.
/// - [VerdictOnShownMessage]: a person's call on something shown to them,
///   made before anyone knows which node it was: [ApprovedVerdict],
///   [HeldOffVerdict] or [ProposedCorrectionVerdict].
///
/// A node is named three ways, as `is_shapes` sets out: its anchor, what it is
/// about; its version, what it says, its shape and all its fields; and its
/// exact id, which one exactly, naming its whole history. A node is never
/// changed. A later node at its anchor has a new exact id, whatever made it,
/// and is a new version only if it says something different. An annotation is
/// of the version at its target's exact id, and holds for a later node at its
/// anchor with the same version. Whatever an actor has written of a version,
/// at any exact id and withdrawn or not, shows they considered it.
///
/// A comment, a correction or an approval can be taken back by its author:
/// they are `Withdrawable`, and a `Withdrawal` of one is final. A
/// `NodeSeenMark` is not: what has been seen stays seen. What they point at
/// and who wrote them, the `Value` a correction proposes, and the
/// `Withdrawal<T>` that takes one back, come from `is_shapes`.
///
/// It imports only `is_shapes` and `checked_json`, which a
/// [VerdictOnShownMessage] is read through, so a shape file may import it
/// under import admission's pure list once they are all on it
/// (https://github.com/enspyrco/intersyntactic/issues/1046).
library;

import 'package:checked_json/checked_json.dart';
import 'package:is_shapes/is_shapes.dart';

/// A thought on the node at [target], by [by], proposing no change to it.
final class NodeComment implements Withdrawable {
  const NodeComment({
    required this.target,
    required this.text,
    required this.by,
  });

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
/// applies corrections to forecasts accepts `NodeCorrection<Outlook>`, and the
/// analyzer refuses a correction to any other value type bound to it, even
/// one with the same fields.
///
/// It proposes; it changes nothing. The acceptor applying it fetches the node
/// at the target's exact id and the node now at its anchor, and holds the
/// correction for a fresh approval if they differ in what it depends on. The
/// corrected node is never rewritten: the correction folds into the next node
/// written at its anchor.
final class NodeCorrection<V extends Value> implements Withdrawable {
  const NodeCorrection({
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
/// `Withdrawal<NodeApproval>` from its author. It approves a version, so a
/// later node at its anchor that says something different needs a fresh
/// approval.
///
/// An actor may hold several approvals of one version: approving twice writes
/// two, and an approval of an earlier node stands for a later one at its
/// anchor with the same version. Each is its own node, and a withdrawal takes
/// back only the one whose id it names. The version stays approved by that
/// actor while any of theirs stands, so to take their approval back a module
/// withdraws every one.
final class NodeApproval implements Withdrawable {
  const NodeApproval({required this.target, required this.by});

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
/// approved writes a [NodeSeenMark] and withdraws their standing approvals of
/// it. It is not `Withdrawable`: what has been seen stays seen, and what its
/// author writes next, an approval or a comment, says more.
final class NodeSeenMark {
  const NodeSeenMark({required this.target, required this.by});

  /// What was seen.
  final Target target;

  /// Who saw it.
  final ActorId by;
}

/// A person's call on something shown to them, made before anyone knows
/// which node it was: a card press in Teams, a button in Slack.
///
/// It has no target and no author. The module that reads it knows only which
/// message was pressed, so whatever carries the verdict also carries that
/// message and who pressed it. Whoever knows which node the message showed
/// builds the annotations:
///
/// - [ApprovedVerdict]: a [NodeApproval] of that node.
/// - [HeldOffVerdict]: a [NodeSeenMark] of it, and a
///   `Withdrawal<NodeApproval>` of each approval of theirs that stands.
/// - [ProposedCorrectionVerdict]: a [NodeCorrection] of it, if
///   [ProposedCorrectionVerdict.inputs] parse as a value of its shape's value
///   type. If they don't, it is refused.
///
/// It is a thing that happened, so like a [NodeSeenMark] it is not
/// `Withdrawable`: a press stays pressed, and what is taken back is the
/// annotation built from it. The cases are past tense for the same reason,
/// and are named for the call the person made, so any press, button or reply
/// that makes it reads the same.
///
/// It travels as JSON in a node's map form,
/// `{"shape": "<class name>", ...its fields}`, so the process that reads the
/// press can pass it on already built and the one that builds the annotations
/// decodes it.
sealed class VerdictOnShownMessage {
  const VerdictOnShownMessage();

  /// Every `shape` a [VerdictOnShownMessage] may decode from, for whoever
  /// checks that no two packages' top-level node shapes collide
  /// (docking_station, 2026-11-16). [VerdictOnShownMessage.fromJson] matches
  /// on these same constants, so the set and the decoder can't drift apart.
  static const Set<String> shapeNames = {
    ApprovedVerdict.shapeName,
    HeldOffVerdict.shapeName,
    ProposedCorrectionVerdict.shapeName,
  };

  /// The verdict [json] holds, read strictly: an unknown shape, or a field
  /// missing, extra or of the wrong type, is a [FormatException].
  factory VerdictOnShownMessage.fromJson(JsonObject json) {
    final (verdict, fields) = switch (json.string('shape')) {
      ApprovedVerdict.shapeName => (const ApprovedVerdict(), const {'shape'}),
      HeldOffVerdict.shapeName => (const HeldOffVerdict(), const {'shape'}),
      ProposedCorrectionVerdict.shapeName => (
        ProposedCorrectionVerdict({
          for (final MapEntry(:key, :value)
              in json.object('inputs').asUncheckedMap().entries)
            key: value is String
                ? value
                : throw JsonFieldException('inputs.$key', 'a string'),
        }),
        const {'shape', 'inputs'},
      ),
      final shape => throw FormatException('`shape` is not a verdict: $shape'),
    };
    for (final key in json.keys) {
      if (!fields.contains(key)) {
        throw FormatException(
          '`$key` is not a field of ${json.string('shape')}',
        );
      }
    }
    return verdict;
  }

  /// This verdict in a node's map form, for `jsonEncode`.
  JsonObject toJson();
}

/// They approved what they were shown.
final class ApprovedVerdict extends VerdictOnShownMessage {
  const ApprovedVerdict();

  /// The `shape` this decodes and encodes as.
  static const String shapeName = 'ApprovedVerdict';

  @override
  JsonObject toJson() => const JsonObject.of({'shape': shapeName});
}

/// They looked at what they were shown and held off on it.
final class HeldOffVerdict extends VerdictOnShownMessage {
  const HeldOffVerdict();

  /// The `shape` this decodes and encodes as.
  static const String shapeName = 'HeldOffVerdict';

  @override
  JsonObject toJson() => const JsonObject.of({'shape': shapeName});
}

/// They proposed a new value for what they were shown, in the [inputs] their
/// client sent with it.
///
/// It carries text, not a [Value]: which value type a correction needs
/// depends on the shape shown, and that is known only once the node is.
/// Whoever learns the node reads the ids its shape's fields name, parses them
/// into its value type `V` and builds a `NodeCorrection<V>`, or refuses them if
/// they don't fit. Other ids may be there too: a client can send what the
/// person typed and the message's own data as one set. They come from
/// the person's client and are unchecked until then.
final class ProposedCorrectionVerdict extends VerdictOnShownMessage {
  ProposedCorrectionVerdict(Map<String, String> inputs)
    : inputs = Map.unmodifiable(inputs);

  /// The text fields their client sent with the verdict, by id.
  final Map<String, String> inputs;

  /// The `shape` this decodes and encodes as.
  static const String shapeName = 'ProposedCorrectionVerdict';

  @override
  JsonObject toJson() => JsonObject.of({'shape': shapeName, 'inputs': inputs});
}
