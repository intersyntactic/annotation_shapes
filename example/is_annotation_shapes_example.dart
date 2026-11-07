// A module's own shapes, the way its shape file declares them: a value of
// its own, and a shape whose identity is marked. Then a correction to one,
// and an approval of the correction.
import 'package:is_annotation_shapes/is_annotation_shapes.dart';
import 'package:is_shapes/is_shapes.dart';

enum Sky { clear, cloudy, rain }

/// What a forecast says: the fields a correction to it may change.
final class Outlook extends Value {
  const Outlook(this.sky, this.reason);
  final Sky sky;
  final String reason;
}

/// A forecast: what it is about is its day, and its outlook may change from
/// one pass to the next without the forecast becoming a different forecast.
final class Forecast {
  const Forecast({required this.day, required this.outlook});
  @identity
  final String day;
  final Outlook outlook;
}

void main() {
  // Ids are read back from text where a node arrives; null if malformed.
  final forecastId = TurnId.parse(
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
  // An actor id names the source that minted it, then that source's own id.
  final sam = ActorId.parse('example:sam');
  if (forecastId == null || anchor == null || sam == null) return;
  if (correctionId == null || correctionAnchor == null) return;

  final correction = Correction(
    target: Target(exact: forecastId, anchor: anchor),
    proposed: const Outlook(Sky.rain, 'the front arrives a day early'),
    by: sam,
  );
  final approval = Approve(
    target: Target(exact: correctionId, anchor: correctionAnchor),
    by: sam,
  );
  print('${correction.by} proposed ${correction.proposed.sky}');
  print('${approval.by} approved ${approval.target.exact}');
}
