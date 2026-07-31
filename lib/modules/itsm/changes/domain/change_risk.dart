import '../../shared/domain/itsm_common.dart';
import 'change_request.dart';

enum ChangeLikelihood {
  rare(1),
  unlikely(2),
  possible(3),
  likely(4),
  almostCertain(5);

  const ChangeLikelihood(this.score);

  final int score;
}

class ChangeRiskAssessment {
  const ChangeRiskAssessment({
    required this.score,
    required this.level,
    required this.requiresCab,
    required this.requiresEmergencyApproval,
  });

  final int score;
  final ChangeRiskLevel level;
  final bool requiresCab;
  final bool requiresEmergencyApproval;
}

abstract final class ChangeRiskCalculator {
  static ChangeRiskAssessment calculate({
    required ChangeType type,
    required ItsmImpact impact,
    required ItsmUrgency urgency,
    required ChangeLikelihood likelihood,
    bool affectsCriticalService = false,
    int expectedDowntimeMinutes = 0,
  }) {
    if (expectedDowntimeMinutes < 0) {
      throw RangeError.value(
        expectedDowntimeMinutes,
        'expectedDowntimeMinutes',
      );
    }

    final base = _impactScore(impact) * likelihood.score;
    final urgencyModifier = switch (urgency) {
      ItsmUrgency.low => 0,
      ItsmUrgency.medium => 1,
      ItsmUrgency.high => 2,
    };
    final criticalServiceModifier = affectsCriticalService ? 2 : 0;
    final downtimeModifier = switch (expectedDowntimeMinutes) {
      > 240 => 3,
      > 60 => 2,
      > 0 => 1,
      _ => 0,
    };
    final typeModifier = type == ChangeType.emergency ? 2 : 0;
    final score = base +
        urgencyModifier +
        criticalServiceModifier +
        downtimeModifier +
        typeModifier;
    final level = switch (score) {
      <= 5 => ChangeRiskLevel.low,
      <= 10 => ChangeRiskLevel.medium,
      <= 17 => ChangeRiskLevel.high,
      _ => ChangeRiskLevel.critical,
    };

    return ChangeRiskAssessment(
      score: score,
      level: level,
      requiresCab: type != ChangeType.standard ||
          level == ChangeRiskLevel.high ||
          level == ChangeRiskLevel.critical,
      requiresEmergencyApproval: type == ChangeType.emergency,
    );
  }

  static int _impactScore(ItsmImpact impact) => switch (impact) {
        ItsmImpact.low => 1,
        ItsmImpact.medium => 2,
        ItsmImpact.high => 3,
        ItsmImpact.critical => 4,
      };
}
