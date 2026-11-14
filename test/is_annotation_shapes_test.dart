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
}
