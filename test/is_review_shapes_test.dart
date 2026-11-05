import 'package:is_review_shapes/is_review_shapes.dart';
import 'package:is_shapes/is_shapes.dart';
import 'package:test/test.dart';

const _hex = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// A verdict as a module declares one.
final class _Level extends Verdict {
  const _Level(this.level);
  final int level;
}

/// Another shape's verdict, with the same fields.
final class _Other extends Verdict {
  const _Other(this.level);
  final int level;
}

Target _target() =>
    Target(exact: TurnId.parse(_hex)!, anchor: SemanticAnchor.parse(_hex)!);

PartyId _peter() => PartyId.parse('U024BE7LH')!;

void main() {
  test('a comment holds its text and proposes nothing', () {
    final comment = Comment(target: _target(), text: 'why 3?', by: _peter());
    expect(comment.target, _target());
    expect(comment.text, 'why 3?');
    expect(comment.by, _peter());
  });

  test('a correction proposes a verdict of its own type', () {
    final correction = Correction(
      target: _target(),
      proposed: const _Level(1),
      by: _peter(),
    );
    expect(correction, isA<Correction<_Level>>());
    expect(correction, isNot(isA<Correction<_Other>>()));
    expect(correction.proposed.level, 1);
  });

  test('an approval holds what is approved and who approved it', () {
    final approval = Approve(target: _target(), by: _peter());
    expect(approval.target, _target());
    expect(approval.by, _peter());
  });

  test('an approval is taken back by a withdrawal of an approval', () {
    final withdrawal = Withdraw<Approve>(
      target: TurnId.parse(_hex)!,
      by: _peter(),
    );
    expect(withdrawal, isA<Withdraw<Approve>>());
    expect(withdrawal, isNot(isA<Withdraw<Comment>>()));
  });

  test('a module declares its own verdict by extending Verdict', () {
    const Verdict verdict = _Level(2);
    expect(verdict, isA<_Level>().having((v) => v.level, 'level', 2));
  });
}
