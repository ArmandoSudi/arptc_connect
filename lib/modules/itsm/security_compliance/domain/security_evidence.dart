import '../../shared/domain/itsm_common.dart';
import 'security_compliance_serialization.dart';

class SecurityActor {
  SecurityActor({
    required String userId,
    required String displayName,
    this.email = '',
  })  : userId = requireSecurityComplianceText(userId, 'userId'),
        displayName = requireSecurityComplianceText(
          displayName,
          'displayName',
        );

  final String userId;
  final String displayName;
  final String email;

  factory SecurityActor.fromMap(Map<String, Object?> map) => SecurityActor(
        userId: securityComplianceString(map['userId']),
        displayName: securityComplianceString(
          map['displayName'] ?? map['name'],
        ),
        email: securityComplianceString(map['email']),
      );

  Map<String, Object?> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'email': email,
      };
}

class SecurityEvidenceMetadata {
  SecurityEvidenceMetadata({
    required String id,
    required String fileName,
    required String contentType,
    required String storagePath,
    required this.confidentiality,
    required String createdBy,
    required DateTime createdAt,
    this.description = '',
    this.sizeBytes = 0,
    this.checksum,
    Iterable<String> authorizedManagerIds = const [],
  })  : id = requireSecurityComplianceText(id, 'id'),
        fileName = requireSecurityComplianceText(fileName, 'fileName'),
        contentType = requireSecurityComplianceText(contentType, 'contentType'),
        storagePath = requireSecurityComplianceText(storagePath, 'storagePath'),
        createdBy = requireSecurityComplianceText(createdBy, 'createdBy'),
        createdAt = createdAt.toUtc(),
        authorizedManagerIds = immutableSecurityComplianceStrings(
          authorizedManagerIds,
        ) {
    if (sizeBytes < 0) throw RangeError.value(sizeBytes, 'sizeBytes');
    if (confidentiality == ItsmConfidentiality.restricted &&
        this.authorizedManagerIds.isEmpty) {
      throw ArgumentError(
        'Restricted evidence requires at least one authorized MANAGER.',
      );
    }
  }

  final String id;
  final String fileName;
  final String contentType;
  final String storagePath;
  final String description;
  final int sizeBytes;
  final String? checksum;
  final ItsmConfidentiality confidentiality;
  final String createdBy;
  final DateTime createdAt;
  final List<String> authorizedManagerIds;

  factory SecurityEvidenceMetadata.fromMap(Map<String, Object?> map) =>
      SecurityEvidenceMetadata(
        id: securityComplianceString(map['id']),
        fileName: securityComplianceString(map['fileName']),
        contentType: securityComplianceString(map['contentType']),
        storagePath: securityComplianceString(map['storagePath']),
        description: securityComplianceString(map['description']),
        sizeBytes: securityComplianceInt(map['sizeBytes']),
        checksum: securityComplianceNullableString(map['checksum']),
        confidentiality: ItsmConfidentiality.fromValue(
          map['confidentiality'],
        ),
        createdBy: securityComplianceString(map['createdBy']),
        createdAt: requireSecurityComplianceDate(
          map['createdAt'],
          'createdAt',
        ),
        authorizedManagerIds: securityComplianceStrings(
          map['authorizedManagerIds'],
        ),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'fileName': fileName,
        'contentType': contentType,
        'storagePath': storagePath,
        'description': description,
        'sizeBytes': sizeBytes,
        'checksum': checksum,
        'confidentiality': confidentiality.value,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'authorizedManagerIds': authorizedManagerIds,
      };
}

enum RemediationLinkType {
  serviceRequest,
  changeRequest;

  String get value => enumStorageValue(this);

  static RemediationLinkType fromValue(Object? value) => enumFromStorageValue(
        values,
        value,
        RemediationLinkType.serviceRequest,
      );
}

class RemediationLink {
  RemediationLink({
    required String id,
    required this.type,
    required String reference,
    this.status = '',
  })  : id = requireSecurityComplianceText(id, 'id'),
        reference = requireSecurityComplianceText(reference, 'reference');

  final String id;
  final RemediationLinkType type;
  final String reference;
  final String status;

  factory RemediationLink.fromMap(Map<String, Object?> map) => RemediationLink(
        id: securityComplianceString(map['id']),
        type: RemediationLinkType.fromValue(map['type']),
        reference: securityComplianceString(map['reference']),
        status: securityComplianceString(map['status']),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.value,
        'reference': reference,
        'status': status,
      };
}
