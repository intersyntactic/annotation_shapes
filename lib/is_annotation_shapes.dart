/// Annotation shapes: a comment, a correction, an approval and a mark that a
/// node was seen. An annotation is a node an actor writes beside another node:
/// it points at that node and never changes it, as in the W3C Web Annotation
/// model (https://www.w3.org/TR/annotation-model/). A module needs them when
/// actors annotate its nodes.
///
/// A Dart class is its declaration: two classes with one name, declared in
/// two libraries, are two types. A module that declared its own `Approval`
/// would make a type no other module's `Approval` can be assigned to, so one
/// module's approval could never bind where another waits for one. So they
/// are declared once, here, for every module whose nodes are annotated
/// (https://github.com/enspyrco/intersyntactic/issues/1073).
///
/// - [Comment]: a thought on a node, proposing no change to it.
/// - [Correction]: a proposed new value for a node.
/// - [Approval]: an approval of a node.
/// - [Seen]: a mark that an actor has seen a node.
/// - [Response]: what a person said back to something shown to them, before
///   anyone knows which node it was: [Approved], [HeldOff] or [Proposed].
///
/// A version of a node is what it says: its shape and its fields, without the
/// whole history its exact id also names. A new pass gives every node a new
/// exact id, and a new version only where something changed. An annotation is
/// of the version at its target's exact id, and holds for a later pass while
/// the node now at its anchor says the same. Whatever an actor has written of a
/// version, on any pass and withdrawn or not, shows they considered it.
///
/// A comment, a correction or an approval can be taken back by its author:
/// they are `Withdrawable`, and a `Withdrawal` of one is final. A `Seen` is
/// not: what has been seen stays seen. What they point at and who wrote them,
/// the `Value` a correction proposes, and the `Withdrawal<T>` that takes one
/// back, come from `is_shapes`.
///
/// It imports only `is_shapes` and `checked_json`, which a [Response] is read
/// through, so a shape file may import it under import admission's pure list
/// once they are all on it
/// (https://github.com/enspyrco/intersyntactic/issues/1046).
library;

import 'package:checked_json/checked_json.dart';
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
/// `Withdrawal<Approval>` from its author. It approves a version, so a pass
/// that changes what the node says needs a fresh approval.
///
/// An actor may hold several approvals of one version: approving twice writes
/// two, and an approval of an earlier pass stands for a later one that says the
/// same. Each is its own node, and a withdrawal takes back only the one whose
/// id it names. The version stays approved by that actor while any of theirs
/// stands, so to take their approval back a module withdraws every one.
final class Approval implements Withdrawable {
  const Approval({required this.target, required this.by});

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

/// What a person said back to something shown to them, before anyone knows
/// which node it was: a card press in Teams, a button in Slack.
///
/// It has no target and no author. The module that reads it knows only which
/// message was pressed, so whatever carries the response also carries that
/// message and who pressed it. Whoever knows which node the message showed
/// builds the annotations:
///
/// - [Approved]: an [Approval] of that node.
/// - [HeldOff]: a [Seen] of it, and a `Withdrawal<Approval>` of each approval
///   of theirs that stands.
/// - [Proposed]: a [Correction] of it, if [Proposed.inputs] parse as a value
///   of its shape's value type. If they don't, it is refused.
///
/// It is a thing that happened, so like a [Seen] it is not `Withdrawable`:
/// a press stays pressed, and what is taken back is the annotation built from
/// it. The cases are past tense for the same reason, and are named for what
/// the person said, so any press, button or reply that says it reads the same.
///
/// It travels as JSON in a node's map form,
/// `{"shape": "<class name>", ...its fields}`, so the process that reads the
/// press can pass it on already built and the one that builds the annotations
/// decodes it.
sealed class Response {
  const Response();

  /// The response [json] holds, read strictly: an unknown shape, or a field
  /// missing, extra or of the wrong type, is a [FormatException].
  factory Response.fromJson(JsonObject json) {
    final (response, fields) = switch (json.string('shape')) {
      'Approved' => (const Approved(), const {'shape'}),
      'HeldOff' => (const HeldOff(), const {'shape'}),
      'Proposed' => (
        Proposed({
          for (final MapEntry(:key, :value)
              in json.object('inputs').asUncheckedMap().entries)
            key: value is String
                ? value
                : throw JsonFieldException('inputs.$key', 'a string'),
        }),
        const {'shape', 'inputs'},
      ),
      final shape => throw FormatException('`shape` is not a response: $shape'),
    };
    for (final key in json.keys) {
      if (!fields.contains(key)) {
        throw FormatException(
          '`$key` is not a field of ${json.string('shape')}',
        );
      }
    }
    return response;
  }

  /// This response in a node's map form, for `jsonEncode`.
  JsonObject toJson();
}

/// They approved what they were shown.
final class Approved extends Response {
  const Approved();

  @override
  JsonObject toJson() => const JsonObject.of({'shape': 'Approved'});
}

/// They looked at what they were shown and held off on it.
final class HeldOff extends Response {
  const HeldOff();

  @override
  JsonObject toJson() => const JsonObject.of({'shape': 'HeldOff'});
}

/// They proposed a new value for what they were shown, in the [inputs] their
/// client sent with it.
///
/// It carries text, not a [Value]: which value type a correction needs
/// depends on the shape shown, and that is known only once the node is.
/// Whoever learns the node reads the ids its shape's fields name, parses them
/// into its value type `V` and builds a `Correction<V>`, or refuses them if
/// they don't fit. Other ids may be there too: a client can send what the
/// person typed and the message's own data as one set. They come from
/// the person's client and are unchecked until then.
final class Proposed extends Response {
  Proposed(Map<String, String> inputs) : inputs = Map.unmodifiable(inputs);

  /// The text fields their client sent with the response, by id.
  final Map<String, String> inputs;

  @override
  JsonObject toJson() => JsonObject.of({'shape': 'Proposed', 'inputs': inputs});
}
