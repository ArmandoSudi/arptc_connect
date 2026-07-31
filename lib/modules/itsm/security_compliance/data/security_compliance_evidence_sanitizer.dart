import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';

abstract final class SecurityComplianceEvidenceSanitizer {
  static Map<String, Object?> sanitize(
    Map<String, dynamic> source,
    ItsmQueryPrincipal principal,
  ) {
    final data = Map<String, Object?>.from(source);
    final evidence = data['evidence'];
    if (evidence is! Iterable || principal.role != ItsmRole.manager) {
      data['evidence'] = const <Object?>[];
      return data;
    }
    data['evidence'] = evidence.where((item) {
      if (item is! Map) return false;
      final metadata = Map<String, Object?>.from(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );
      final confidentiality = ItsmConfidentiality.fromValue(
        metadata['confidentiality'],
      );
      if (confidentiality != ItsmConfidentiality.restricted) return true;
      final authorized = metadata['authorizedManagerIds'];
      return authorized is Iterable && authorized.contains(principal.userId);
    }).toList(growable: false);
    return data;
  }
}
