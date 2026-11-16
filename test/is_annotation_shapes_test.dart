import 'dart:convert';

import 'package:checked_json/checked_json.dart';
import 'package:is_annotation_shapes/is_annotation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';
import 'package:test/test.dart';

const _hex = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// A value as a module declares one.
final class _Level extends Value {
  const _Level(this.level);
  final int level;
}

/// Another shape's value, with the same fields.
final class _Other extends Value {
  const _Other(this.level);
  final int level;
}

Target _target() =>
    Target(exact: TurnId.parse(_hex)!, anchor: SemanticAnchor.parse(_hex)!);

ActorId _sam() => ActorId.parse('example:sam')!;

void main() {
  test('a comment holds its text and proposes nothing', () {
    final comment = NodeComment(target: _target(), text: 'why 3?', by: _sam());
    expect(comment.target, _target());
    expect(comment.text, 'why 3?');
    expect(comment.by, _sam());
  });

  test('a correction proposes a value of its own type', () {
    final correction = NodeCorrection(
      target: _target(),
      proposed: const _Level(1),
      by: _sam(),
    );
    expect(correction, isA<NodeCorrection<_Level>>());
    expect(correction, isNot(isA<NodeCorrection<_Other>>()));
    expect(correction.proposed.level, 1);
  });

  test('an approval holds what is approved and who approved it', () {
    final approval = NodeApproval(target: _target(), by: _sam());
    expect(approval.target, _target());
    expect(approval.by, _sam());
  });

  test('an approval is taken back by a withdrawal of an approval', () {
    final withdrawal = Withdrawal<NodeApproval>(
      target: TurnId.parse(_hex)!,
      by: _sam(),
    );
    expect(withdrawal, isA<Withdrawal<NodeApproval>>());
    expect(withdrawal, isNot(isA<Withdrawal<NodeComment>>()));
  });

  test('a seen mark holds what was seen and who saw it', () {
    final seen = NodeSeenMark(target: _target(), by: _sam());
    expect(seen.target, _target());
    expect(seen.by, _sam());
    expect(seen, isNot(isA<Withdrawable>()));
  });

  test('a verdict becomes the annotations it says, once its node is known', () {
    // The shape shown is known here, so its value type is too.
    Object annotate(VerdictOnShownMessage verdict) => switch (verdict) {
      ApprovedVerdict() => NodeApproval(target: _target(), by: _sam()),
      HeldOffVerdict() => NodeSeenMark(target: _target(), by: _sam()),
      ProposedCorrectionVerdict(:final inputs) => switch (int.tryParse(
        inputs['level'] ?? '',
      )) {
        final level? => NodeCorrection(
          target: _target(),
          proposed: _Level(level),
          by: _sam(),
        ),
        null => 'refused',
      },
    };
    expect(annotate(const ApprovedVerdict()), isA<NodeApproval>());
    expect(annotate(const HeldOffVerdict()), isA<NodeSeenMark>());
    expect(
      annotate(ProposedCorrectionVerdict({'level': '1'})),
      isA<NodeCorrection<_Level>>().having((c) => c.proposed.level, 'level', 1),
    );
    expect(annotate(ProposedCorrectionVerdict({'level': 'high'})), 'refused');
    expect(annotate(ProposedCorrectionVerdict({})), 'refused');
    expect(const ApprovedVerdict(), isNot(isA<Withdrawable>()));
  });

  test('a proposal holds its inputs as they were sent', () {
    final typed = {'level': '1'};
    final proposed = ProposedCorrectionVerdict(typed);
    typed['level'] = '2';
    expect(proposed.inputs, {'level': '1'});
    expect(() => proposed.inputs['level'] = '3', throwsUnsupportedError);
  });

  group('a verdict as JSON', () {
    VerdictOnShownMessage read(String text) =>
        VerdictOnShownMessage.fromJson(JsonObject.decode(text));

    test('names every shape it writes, and reads each one it names', () {
      final written = {
        for (final verdict in [
          const ApprovedVerdict(),
          const HeldOffVerdict(),
          ProposedCorrectionVerdict({}),
        ])
          verdict.toJson().string('shape'),
      };
      expect(VerdictOnShownMessage.shapeNames, written);
      for (final name in VerdictOnShownMessage.shapeNames) {
        final json = name == ProposedCorrectionVerdict.shapeName
            ? {'shape': name, 'inputs': <String, Object?>{}}
            : {'shape': name};
        expect(
          VerdictOnShownMessage.fromJson(JsonObject.of(json))
              .toJson()
              .string('shape'),
          name,
        );
      }
    });

    test('is written in a node\'s map form, to the byte', () {
      expect(
        jsonEncode(const ApprovedVerdict()),
        '{"shape":"ApprovedVerdict"}',
      );
      expect(jsonEncode(const HeldOffVerdict()), '{"shape":"HeldOffVerdict"}');
      expect(
        jsonEncode(
          ProposedCorrectionVerdict({'level': '1', 'why': 'too high'}),
        ),
        '{"shape":"ProposedCorrectionVerdict","inputs":{"level":"1","why":"too high"}}',
      );
    });

    test('reads back as the verdict it was', () {
      expect(read('{"shape":"ApprovedVerdict"}'), isA<ApprovedVerdict>());
      expect(read('{"shape":"HeldOffVerdict"}'), isA<HeldOffVerdict>());
      expect(
        read(jsonEncode(ProposedCorrectionVerdict({'level': '1'}))),
        isA<ProposedCorrectionVerdict>().having((p) => p.inputs, 'inputs', {
          'level': '1',
        }),
      );
      expect(
        read('{"shape":"ProposedCorrectionVerdict","inputs":{}}'),
        isA<ProposedCorrectionVerdict>().having(
          (p) => p.inputs,
          'inputs',
          isEmpty,
        ),
      );
    });

    test('read back, a proposal\'s inputs refuse changes', () {
      final proposed = read(
        '{"shape":"ProposedCorrectionVerdict","inputs":{"a":"1"}}',
      );
      expect(
        () => (proposed as ProposedCorrectionVerdict).inputs['a'] = '2',
        throwsUnsupportedError,
      );
    });

    final refused = {
      'an unknown shape': '{"shape":"Approve"}',
      'another package\'s shape': '{"shape":"UserSaid"}',
      'no shape': '{}',
      'a shape that is not a string': '{"shape":1}',
      'an extra field': '{"shape":"ApprovedVerdict","by":"example:sam"}',
      'an extra field on a proposal':
          '{"shape":"ProposedCorrectionVerdict","inputs":{},"target":"x"}',
      'a proposal with no inputs': '{"shape":"ProposedCorrectionVerdict"}',
      'inputs that are not an object':
          '{"shape":"ProposedCorrectionVerdict","inputs":[]}',
      'null inputs': '{"shape":"ProposedCorrectionVerdict","inputs":null}',
      'an input that is not text':
          '{"shape":"ProposedCorrectionVerdict","inputs":{"level":1}}',
      'a null input':
          '{"shape":"ProposedCorrectionVerdict","inputs":{"level":null}}',
    };
    for (final MapEntry(key: what, value: text) in refused.entries) {
      test('refuses $what', () {
        expect(() => read(text), throwsFormatException);
      });
    }
  });
}
