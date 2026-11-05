// A module's own shapes, the way its shape file declares them: a verdict of
// its own, and a shape whose identity is marked. Then an approval of one.
import 'package:is_review_shapes/is_review_shapes.dart';

enum RungLevel { supported, overstated, unsupported }

/// What a rung concludes: the fields a correction to it may change.
final class RungVerdict extends Verdict {
  const RungVerdict(this.level, this.rationale);
  final RungLevel level;
  final String rationale;
}

/// A rung: what it is about is its failure mode, and its verdict may change
/// from one pass to the next without the rung becoming a different rung.
final class Rung {
  const Rung({required this.failureMode, required this.verdict});
  @identity
  final String failureMode;
  final RungVerdict verdict;
}

void main() {
  // Ids are read back from text where a node arrives; null if malformed.
  final seen = TurnId.parse(
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
  );
  final anchor = SemanticAnchor.parse(
    '2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae',
  );
  final peter = PartyId.parse('U024BE7LH');
  if (seen == null || anchor == null || peter == null) return;

  final approval = Approve(
    target: Target(exact: seen, anchor: anchor),
    by: peter,
  );
  print('${approval.by} approved ${approval.target.exact}');
}
