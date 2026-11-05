import 'package:is_review_shapes/is_review_shapes.dart';
import 'package:test/test.dart';

const _hex = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// A verdict as a module declares one.
final class _Level extends Verdict {
  const _Level(this.level);
  final int level;
}

void main() {
  group('TurnId and SemanticAnchor', () {
    test('parse reads a sha256 in lower-case hex', () {
      expect(TurnId.parse(_hex)?.hex, _hex);
      expect(SemanticAnchor.parse(_hex)?.hex, _hex);
      expect(TurnId.parse(_hex).toString(), _hex);
    });

    test('parse refuses anything else', () {
      for (final s in [
        '',
        _hex.substring(1),
        '${_hex}0',
        _hex.toUpperCase(),
        'g${_hex.substring(1)}',
        ' $_hex',
        '$_hex\n',
      ]) {
        expect(TurnId.parse(s), isNull, reason: s);
        expect(SemanticAnchor.parse(s), isNull, reason: s);
      }
    });

    test('equal to the same kind with the same hex', () {
      expect(TurnId.parse(_hex), TurnId.parse(_hex));
      expect(TurnId.parse(_hex).hashCode, TurnId.parse(_hex).hashCode);
    });

    test('a turn id is never equal to an anchor with the same hex', () {
      expect(TurnId.parse(_hex), isNot(SemanticAnchor.parse(_hex)));
    });

    test('a string cannot be cast to one', () {
      // What an extension type over String would allow.
      Object raw = _hex;
      expect(() => raw as TurnId, throwsA(isA<TypeError>()));
    });
  });

  group('PartyId', () {
    test('parse reads printable ASCII with no spaces', () {
      for (final s in ['U024BE7LH', 'T0001:U024BE7LH', 'agent:hart-79']) {
        expect(PartyId.parse(s)?.value, s);
      }
    });

    test('parse refuses anything else', () {
      for (final s in ['', ' ', 'nick meinhold', 'nick\n', 'nick\t', 'ñick']) {
        expect(PartyId.parse(s), isNull, reason: s);
      }
    });

    test('equal to a party id with the same text', () {
      expect(PartyId.parse('U024BE7LH'), PartyId.parse('U024BE7LH'));
      expect(PartyId.parse('U024BE7LH'), isNot(PartyId.parse('U024BE7LI')));
    });
  });

  test('a target is equal to one with the same two ids', () {
    Target target() =>
        Target(exact: TurnId.parse(_hex)!, anchor: SemanticAnchor.parse(_hex)!);
    expect(target(), target());
    expect(target().hashCode, target().hashCode);
  });

  test('an approval holds what is approved and who approved it', () {
    final target = Target(
      exact: TurnId.parse(_hex)!,
      anchor: SemanticAnchor.parse(_hex)!,
    );
    final by = PartyId.parse('U024BE7LH')!;
    final approval = Approve(target: target, by: by);
    expect(approval.target, target);
    expect(approval.by, by);
  });

  test('a module declares its own verdict by extending Verdict', () {
    const Verdict verdict = _Level(2);
    expect(verdict, isA<_Level>().having((v) => v.level, 'level', 2));
  });

  test('identity is the one Identity', () {
    expect(identity, isA<Identity>());
  });
}
