import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_model_helpers.dart';
import 'incident_enums.dart';

class IncidentTicket {
  const IncidentTicket({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.lifecycleState,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdByEmail,
    required this.createdByDepartmentId,
    required this.createdByDepartmentName,
    required this.createdByServiceId,
    required this.createdByServiceName,
    required this.affectedUserId,
    required this.affectedUserName,
    required this.affectedUserEmail,
    required this.affectedServiceId,
    required this.affectedServiceName,
    required this.location,
    required this.deviceType,
    required this.assetId,
    required this.userImpactDescription,
    required this.isBlocking,
    required this.categoryId,
    required this.categoryName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.impact,
    required this.urgency,
    required this.priority,
    required this.assignedToUserId,
    required this.assignedToName,
    required this.assignedToEmail,
    required this.resolutionSummary,
    required this.resolutionCode,
    required this.closedByUserId,
    required this.closedByName,
    required this.closedAt,
    required this.archivedAt,
    required this.archiveEligibleAt,
    required this.createdAt,
    required this.updatedAt,
    required this.lastCommentAt,
    required this.lastStatusChangedAt,
    required this.attachmentCount,
    required this.commentCount,
    required this.isDeleted,
  });

  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String status;
  final String lifecycleState;
  final String createdByUserId;
  final String createdByName;
  final String createdByEmail;
  final String createdByDepartmentId;
  final String createdByDepartmentName;
  final String createdByServiceId;
  final String createdByServiceName;
  final String affectedUserId;
  final String affectedUserName;
  final String affectedUserEmail;
  final String affectedServiceId;
  final String affectedServiceName;
  final String location;
  final String deviceType;
  final String assetId;
  final String userImpactDescription;
  final bool isBlocking;
  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final String impact;
  final String urgency;
  final String priority;
  final String assignedToUserId;
  final String assignedToName;
  final String assignedToEmail;
  final String resolutionSummary;
  final String resolutionCode;
  final String closedByUserId;
  final String closedByName;
  final DateTime? closedAt;
  final DateTime? archivedAt;
  final DateTime? archiveEligibleAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastCommentAt;
  final DateTime? lastStatusChangedAt;
  final int attachmentCount;
  final int commentCount;
  final bool isDeleted;

  factory IncidentTicket.empty() {
    return const IncidentTicket(
      id: '',
      ticketNumber: '',
      title: '',
      description: '',
      status: 'open',
      lifecycleState: 'active',
      createdByUserId: '',
      createdByName: '',
      createdByEmail: '',
      createdByDepartmentId: '',
      createdByDepartmentName: '',
      createdByServiceId: '',
      createdByServiceName: '',
      affectedUserId: '',
      affectedUserName: '',
      affectedUserEmail: '',
      affectedServiceId: '',
      affectedServiceName: '',
      location: '',
      deviceType: '',
      assetId: '',
      userImpactDescription: '',
      isBlocking: false,
      categoryId: '',
      categoryName: '',
      subcategoryId: '',
      subcategoryName: '',
      impact: '',
      urgency: '',
      priority: '',
      assignedToUserId: '',
      assignedToName: '',
      assignedToEmail: '',
      resolutionSummary: '',
      resolutionCode: '',
      closedByUserId: '',
      closedByName: '',
      closedAt: null,
      archivedAt: null,
      archiveEligibleAt: null,
      createdAt: null,
      updatedAt: null,
      lastCommentAt: null,
      lastStatusChangedAt: null,
      attachmentCount: 0,
      commentCount: 0,
      isDeleted: false,
    );
  }

  factory IncidentTicket.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return IncidentTicket(
      id: snapshot.id,
      ticketNumber: stringFromFirestore(data, 'ticketNumber'),
      title: stringFromFirestore(data, 'title'),
      description: stringFromFirestore(data, 'description'),
      status: IncidentStatus.fromValue(data['status']?.toString()).value,
      lifecycleState:
          IncidentLifecycleState.fromValue(data['lifecycleState']?.toString())
              .value,
      createdByUserId: stringFromFirestore(data, 'createdByUserId'),
      createdByName: stringFromFirestore(data, 'createdByName'),
      createdByEmail: stringFromFirestore(data, 'createdByEmail'),
      createdByDepartmentId: stringFromFirestore(data, 'createdByDepartmentId'),
      createdByDepartmentName:
          stringFromFirestore(data, 'createdByDepartmentName'),
      createdByServiceId: stringFromFirestore(data, 'createdByServiceId'),
      createdByServiceName: stringFromFirestore(data, 'createdByServiceName'),
      affectedUserId: stringFromFirestore(data, 'affectedUserId'),
      affectedUserName: stringFromFirestore(data, 'affectedUserName'),
      affectedUserEmail: stringFromFirestore(data, 'affectedUserEmail'),
      affectedServiceId: stringFromFirestore(data, 'affectedServiceId'),
      affectedServiceName: stringFromFirestore(data, 'affectedServiceName'),
      location: stringFromFirestore(data, 'location'),
      deviceType: stringFromFirestore(data, 'deviceType'),
      assetId: stringFromFirestore(data, 'assetId'),
      userImpactDescription: stringFromFirestore(data, 'userImpactDescription'),
      isBlocking: boolFromFirestore(data, 'isBlocking'),
      categoryId: stringFromFirestore(data, 'categoryId'),
      categoryName: stringFromFirestore(data, 'categoryName'),
      subcategoryId: stringFromFirestore(data, 'subcategoryId'),
      subcategoryName: stringFromFirestore(data, 'subcategoryName'),
      impact: stringFromFirestore(data, 'impact'),
      urgency: stringFromFirestore(data, 'urgency'),
      priority: IncidentPriority.fromValue(data['priority']?.toString()).value,
      assignedToUserId: stringFromFirestore(data, 'assignedToUserId'),
      assignedToName: stringFromFirestore(data, 'assignedToName'),
      assignedToEmail: stringFromFirestore(data, 'assignedToEmail'),
      resolutionSummary: stringFromFirestore(data, 'resolutionSummary'),
      resolutionCode: stringFromFirestore(data, 'resolutionCode'),
      closedByUserId: stringFromFirestore(data, 'closedByUserId'),
      closedByName: stringFromFirestore(data, 'closedByName'),
      closedAt: dateTimeFromFirestore(data['closedAt']),
      archivedAt: dateTimeFromFirestore(data['archivedAt']),
      archiveEligibleAt: dateTimeFromFirestore(data['archiveEligibleAt']),
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
      lastCommentAt: dateTimeFromFirestore(data['lastCommentAt']),
      lastStatusChangedAt: dateTimeFromFirestore(data['lastStatusChangedAt']),
      attachmentCount: intFromFirestore(data, 'attachmentCount'),
      commentCount: intFromFirestore(data, 'commentCount'),
      isDeleted: boolFromFirestore(data, 'isDeleted'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ticketNumber': ticketNumber.trim(),
      'title': title.trim(),
      'description': description.trim(),
      'status': IncidentStatus.fromValue(status).value,
      'lifecycleState': IncidentLifecycleState.fromValue(lifecycleState).value,
      'createdByUserId': createdByUserId.trim(),
      'createdByName': createdByName.trim(),
      'createdByEmail': createdByEmail.trim(),
      'createdByDepartmentId': createdByDepartmentId.trim(),
      'createdByDepartmentName': createdByDepartmentName.trim(),
      'createdByServiceId': createdByServiceId.trim(),
      'createdByServiceName': createdByServiceName.trim(),
      'affectedUserId': affectedUserId.trim(),
      'affectedUserName': affectedUserName.trim(),
      'affectedUserEmail': affectedUserEmail.trim(),
      'affectedServiceId': affectedServiceId.trim(),
      'affectedServiceName': affectedServiceName.trim(),
      'location': location.trim(),
      'deviceType': deviceType.trim(),
      'assetId': assetId.trim(),
      'userImpactDescription': userImpactDescription.trim(),
      'isBlocking': isBlocking,
      'categoryId': categoryId.trim(),
      'categoryName': categoryName.trim(),
      'subcategoryId': subcategoryId.trim(),
      'subcategoryName': subcategoryName.trim(),
      'impact': impact.trim(),
      'urgency': urgency.trim(),
      'priority': IncidentPriority.fromValue(priority).value,
      'assignedToUserId': assignedToUserId.trim(),
      'assignedToName': assignedToName.trim(),
      'assignedToEmail': assignedToEmail.trim(),
      'resolutionSummary': resolutionSummary.trim(),
      'resolutionCode': resolutionCode.trim(),
      'closedByUserId': closedByUserId.trim(),
      'closedByName': closedByName.trim(),
      'closedAt': dateTimeToFirestore(closedAt),
      'archivedAt': dateTimeToFirestore(archivedAt),
      'archiveEligibleAt': dateTimeToFirestore(archiveEligibleAt),
      'createdAt': dateTimeToFirestore(createdAt),
      'updatedAt': dateTimeToFirestore(updatedAt),
      'lastCommentAt': dateTimeToFirestore(lastCommentAt),
      'lastStatusChangedAt': dateTimeToFirestore(lastStatusChangedAt),
      'attachmentCount': attachmentCount,
      'commentCount': commentCount,
      'isDeleted': isDeleted,
    };
  }

  IncidentTicket copyWith({
    String? id,
    String? ticketNumber,
    String? title,
    String? description,
    String? status,
    String? lifecycleState,
    String? createdByUserId,
    String? createdByName,
    String? createdByEmail,
    String? createdByDepartmentId,
    String? createdByDepartmentName,
    String? createdByServiceId,
    String? createdByServiceName,
    String? affectedUserId,
    String? affectedUserName,
    String? affectedUserEmail,
    String? affectedServiceId,
    String? affectedServiceName,
    String? location,
    String? deviceType,
    String? assetId,
    String? userImpactDescription,
    bool? isBlocking,
    String? categoryId,
    String? categoryName,
    String? subcategoryId,
    String? subcategoryName,
    String? impact,
    String? urgency,
    String? priority,
    String? assignedToUserId,
    String? assignedToName,
    String? assignedToEmail,
    String? resolutionSummary,
    String? resolutionCode,
    String? closedByUserId,
    String? closedByName,
    DateTime? closedAt,
    DateTime? archivedAt,
    DateTime? archiveEligibleAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCommentAt,
    DateTime? lastStatusChangedAt,
    int? attachmentCount,
    int? commentCount,
    bool? isDeleted,
  }) {
    return IncidentTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdByDepartmentId:
          createdByDepartmentId ?? this.createdByDepartmentId,
      createdByDepartmentName:
          createdByDepartmentName ?? this.createdByDepartmentName,
      createdByServiceId: createdByServiceId ?? this.createdByServiceId,
      createdByServiceName: createdByServiceName ?? this.createdByServiceName,
      affectedUserId: affectedUserId ?? this.affectedUserId,
      affectedUserName: affectedUserName ?? this.affectedUserName,
      affectedUserEmail: affectedUserEmail ?? this.affectedUserEmail,
      affectedServiceId: affectedServiceId ?? this.affectedServiceId,
      affectedServiceName: affectedServiceName ?? this.affectedServiceName,
      location: location ?? this.location,
      deviceType: deviceType ?? this.deviceType,
      assetId: assetId ?? this.assetId,
      userImpactDescription:
          userImpactDescription ?? this.userImpactDescription,
      isBlocking: isBlocking ?? this.isBlocking,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      impact: impact ?? this.impact,
      urgency: urgency ?? this.urgency,
      priority: priority ?? this.priority,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      resolutionSummary: resolutionSummary ?? this.resolutionSummary,
      resolutionCode: resolutionCode ?? this.resolutionCode,
      closedByUserId: closedByUserId ?? this.closedByUserId,
      closedByName: closedByName ?? this.closedByName,
      closedAt: closedAt ?? this.closedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      archiveEligibleAt: archiveEligibleAt ?? this.archiveEligibleAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastCommentAt: lastCommentAt ?? this.lastCommentAt,
      lastStatusChangedAt: lastStatusChangedAt ?? this.lastStatusChangedAt,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      commentCount: commentCount ?? this.commentCount,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
