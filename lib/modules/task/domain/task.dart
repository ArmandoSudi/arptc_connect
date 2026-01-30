import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String label;
  final String observation;
  final DateTime creationDate;
  final DateTime? receptionDate;
  final DateTime emissionDate;
  final String status;      // 'doing', 'done', 'archived'
  final String type;        // 'mail', 'task'
  final String? sender;
  final String? receiver;
  final String? mailScanUrl;
  final String? reportFileUrl;
  final String department;
  final Map<String, String>? annotations;

  Task({
    required this.id,
    required this.label,
    required this.observation,
    required this.creationDate,
    this.receptionDate,
    required this.emissionDate,
    required this.status,
    required this.type,
    this.sender,
    this.receiver,
    this.mailScanUrl,
    this.reportFileUrl,
    required this.department,
    this.annotations
  });

  /// Convert a Firestore map into our Task model,
  /// parsing all Timestamp fields via `.toDate()`.
  factory Task.fromMap(Map<String, dynamic> map, {String? id}) {
    final Timestamp tsCreation = map['creation_date'] as Timestamp;
    final Timestamp tsEmission  = map['emission_date']  as Timestamp;
    final Timestamp? tsReception = map['reception_date'] as Timestamp?;

    return Task(
      id:         id ?? map['id'] as String,
      label:      map['label']        as String,
      observation:map['observation']  as String,
      creationDate:  tsCreation.toDate(),
      emissionDate:  tsEmission.toDate(),
      receptionDate: tsReception?.toDate(),
      status:     map['status']       as String,
      type:       map['type']         as String,
      sender:     map['sender']       as String?,
      receiver:   map['receiver']     as String?,
      mailScanUrl:   map['mail_scan_url']   as String?,
      reportFileUrl: map['report_file_url'] as String?,
      department: map['department']   as String,
      annotations: (map['annotations'] as Map<dynamic, dynamic>?)
          ?.map((key, value) => MapEntry(key as String, value as String)),
    );
  }

  /// Convert our Task into a Firestore‑friendly map,
  /// encoding our DateTimes as Timestamps.
  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'observation': observation,
    'creation_date': Timestamp.fromDate(creationDate),
    'emission_date': Timestamp.fromDate(emissionDate),
    // if receptionDate is null, you can either omit the field entirely:
    if (receptionDate != null)
      'reception_date': Timestamp.fromDate(receptionDate!),
    'status': status,
    'type': type,
    'sender': sender,
    'receiver': receiver,
    'mail_scan_url': mailScanUrl,
    'report_file_url': reportFileUrl,
    'department': department,
    'annotations': annotations,
  };
}
