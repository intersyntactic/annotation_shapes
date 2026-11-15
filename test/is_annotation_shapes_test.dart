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
    final comment = Comment(target: _target(), text: 'why 3?', by: _sam());
    expect(comment.target, _target());
    expect(comment.text, 'why 3?');
    expect(comment.by, _sam());
  });

  test('a correction proposes a value of its own type', () {
    final correction = Correction(
      target: _target(),
      proposed: const _Level(1),
      by: _sam(),
    );
    expect(correction, isA<Correction<_Level>>());
    expect(correction, isNot(isA<Correction<_Other>>()));
    expect(correction.proposed.level, 1);
  });

  test('an approval holds what is approved and who approved it', () {
    final approval = Approval(target: _target(), by: _sam());
    expect(approval.target, _target());
    expect(approval.by, _sam());
  });

  test('an approval is taken back by a withdrawal of an approval', () {
    final withdrawal = Withdrawal<Approval>(
      target: TurnId.parse(_hex)!,
      by: _sam(),
    );
    expect(withdrawal, isA<Withdrawal<Approval>>());
    expect(withdrawal, isNot(isA<Withdrawal<Comment>>()));
  });

  test('a seen mark holds what was seen and who saw it', () {
    final seen = Seen(target: _target(), by: _sam());
    expect(seen.target, _target());
    expect(seen.by, _sam());
    expect(seen, isNot(isA<Withdrawable>()));
  });

  test(
    'a response becomes the annotations it says, once its node is known',
    () {
      // The shape shown is known here, so its value type is too.
      Object annotate(Response response) => switch (response) {
        Approved() => Approval(target: _target(), by: _sam()),
        HeldOff() => Seen(target: _target(), by: _sam()),
        Proposed(:final inputs) => switch (int.tryParse(
          inputs['level'] ?? '',
        )) {
          final level? => Correction(
            target: _target(),
            proposed: _Level(level),
            by: _sam(),
          ),
          null => 'refused',
        },
      };
      expect(annotate(const Approved()), isA<Approval>());
      expect(annotate(const HeldOff()), isA<Seen>());
      expect(
        annotate(Proposed({'level': '1'})),
        isA<Correction<_Level>>().having((c) => c.proposed.level, 'level', 1),
      );
      expect(annotate(Proposed({'level': 'high'})), 'refused');
      expect(annotate(Proposed({})), 'refused');
      expect(const Approved(), isNot(isA<Withdrawable>()));
    },
  );

  test('a proposal holds its inputs as they were sent', () {
    final typed = {'level': '1'};
    final proposed = Proposed(typed);
    typed['level'] = '2';
    expect(proposed.inputs, {'level': '1'});
    expect(() => proposed.inputs['level'] = '3', throwsUnsupportedError);
  });
}
