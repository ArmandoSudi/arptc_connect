import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentResolutionCode {
  const IncidentResolutionCode({
    required this.id,
    required this.code,
    required this.labelEn,
    required this.labelFr,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String labelEn;
  final String labelFr;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory IncidentResolutionCode.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final code = normalizeCode(data['code']?.toString() ?? snapshot.id);
    return IncidentResolutionCode(
      id: snapshot.id,
      code: code,
      labelEn: data['labelEn']?.toString().trim() ?? code,
      labelFr: data['labelFr']?.toString().trim() ?? code,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': normalizeCode(code),
      'labelEn': labelEn.trim(),
      'labelFr': labelFr.trim(),
      'isActive': isActive,
    };
  }

  String labelForLanguageCode(String languageCode) {
    final localized = languageCode.toLowerCase() == 'fr' ? labelFr : labelEn;
    return localized.trim().isEmpty ? code : localized.trim();
  }

  static String normalizeCode(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static const List<IncidentResolutionCode> builtInDefaults = [
    IncidentResolutionCode(
      id: 'fixed',
      code: 'FIXED',
      labelEn: 'Fixed',
      labelFr: 'Résolu',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'workaround_provided',
      code: 'WORKAROUND_PROVIDED',
      labelEn: 'Workaround provided',
      labelFr: 'Solution de contournement fournie',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'user_guidance',
      code: 'USER_GUIDANCE',
      labelEn: 'User guidance',
      labelFr: 'Assistance utilisateur',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'configuration_changed',
      code: 'CONFIGURATION_CHANGED',
      labelEn: 'Configuration changed',
      labelFr: 'Configuration modifiée',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'hardware_replaced',
      code: 'HARDWARE_REPLACED',
      labelEn: 'Hardware replaced',
      labelFr: 'Matériel remplacé',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'software_reinstalled',
      code: 'SOFTWARE_REINSTALLED',
      labelEn: 'Software reinstalled',
      labelFr: 'Logiciel réinstallé',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'duplicate',
      code: 'DUPLICATE',
      labelEn: 'Duplicate',
      labelFr: 'Doublon',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'no_fault_found',
      code: 'NO_FAULT_FOUND',
      labelEn: 'No fault found',
      labelFr: 'Aucun défaut détecté',
      isActive: true,
    ),
    IncidentResolutionCode(
      id: 'cancelled',
      code: 'CANCELLED',
      labelEn: 'Cancelled',
      labelFr: 'Annulé',
      isActive: true,
    ),
  ];
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
