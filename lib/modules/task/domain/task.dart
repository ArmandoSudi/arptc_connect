import 'package:cloud_firestore/cloud_firestore.dart';

class Task{
  String? id;
  String title;
  String observation;
  bool isDone;
  final DateTime creationDate;

//<editor-fold desc="Data Methods">
  Task({
    this.id,
    required this.title,
    required this.observation,
    required this.isDone,
    required this.creationDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          observation == other.observation &&
          isDone == other.isDone &&
          creationDate == other.creationDate);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      observation.hashCode ^
      isDone.hashCode ^
      creationDate.hashCode;

  @override
  String toString() {
    return 'Task{' +
        ' id: $id,' +
        ' title: $title,' +
        ' observation: $observation,' +
        ' isDone: $isDone,' +
        ' creationDate: $creationDate,' +
        '}';
  }

  Task copyWith({
    String? id,
    String? title,
    String? observation,
    bool? isDone,
    DateTime? creationDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      observation: observation ?? this.observation,
      isDone: isDone ?? this.isDone,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': this.id,
      'title': this.title,
      'observation': this.observation,
      'is_done': this.isDone,
      'creation_date': this.creationDate,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, {String? id}) {

    final timestampCreationDate = map['creation_date'] as Timestamp;

    return Task(
      id: id ?? map['id'] as String,
      title: map['title'] as String,
      observation: map['observation'] as String,
      isDone: map['is_done'] as bool,
      creationDate: timestampCreationDate.toDate(),
    );
  }

//</editor-fold>
}