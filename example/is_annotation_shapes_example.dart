// A module's own shapes, the way its shape file declares them: a value of
// its own (Hart calls its rung's value a verdict), and a shape whose identity
// is marked. Then a correction to one, and an approval of the correction.
import 'package:is_annotation_shapes/is_annotation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';

enum RungLevel { supported, overstated, unsupported }

/// What a rung concludes: the fields a correction to it may change.
final class RungVerdict extends Value {
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
  // The correction is a node of its own, with its own id and anchor.
  final correctionId = TurnId.parse(
    'fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9',
  );
  final correctionAnchor = SemanticAnchor.parse(
    'b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c',
  );
  // A party id names the source that minted it: Peter is a Teams user,
  // teams:<tenant id>/<AAD object id>.
  final peter = PartyId.parse(
    'teams:11111111-1111-1111-1111-111111111111/'
    '22222222-2222-2222-2222-222222222222',
  );
  if (seen == null || anchor == null || peter == null) return;
  if (correctionId == null || correctionAnchor == null) return;

  final correction = Correction(
    target: Target(exact: seen, anchor: anchor),
    proposed: const RungVerdict(RungLevel.overstated, 'one source, not two'),
    by: peter,
  );
  final approval = Approve(
    target: Target(exact: correctionId, anchor: correctionAnchor),
    by: peter,
  );
  print('${correction.by} proposed ${correction.proposed.level}');
  print('${approval.by} approved ${approval.target.exact}');
}
