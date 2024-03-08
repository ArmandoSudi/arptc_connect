import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String? id;
  final String author;
  final String subject;
  final String agent;
  final String solution;
  final bool isSolved;
  final DateTime creationDate;
  final DateTime closingDate;

//<editor-fold desc="Data Methods">
  const Ticket({
    this.id,
    required this.author,
    required this.subject,
    required this.agent,
    required this.solution,
    required this.isSolved,
    required this.creationDate,
    required this.closingDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ticket &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          author == other.author &&
          subject == other.subject &&
          agent == other.agent &&
          solution == other.solution &&
          isSolved == other.isSolved &&
          creationDate == other.creationDate &&
          closingDate == other.closingDate);

  @override
  int get hashCode =>
      id.hashCode ^
      author.hashCode ^
      subject.hashCode ^
      agent.hashCode ^
      solution.hashCode ^
      isSolved.hashCode ^
      creationDate.hashCode ^
      closingDate.hashCode;

  @override
  String toString() {
    return 'Ticket{' +
        ' id: $id,' +
        ' author: $author,' +
        ' subject: $subject,' +
        ' agent: $agent,' +
        ' solution: $solution,' +
        ' isSolved: $isSolved,' +
        ' creationDate: $creationDate,' +
        ' closingDate: $closingDate,' +
        '}';
  }

  Ticket copyWith({
    String? id,
    String? author,
    String? subject,
    String? agent,
    String? solution,
    bool? isSolved,
    DateTime? creationDate,
    DateTime? closingDate,
  }) {
    return Ticket(
      id: id ?? this.id,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      agent: agent ?? this.agent,
      solution: solution ?? this.solution,
      isSolved: isSolved ?? this.isSolved,
      creationDate: creationDate ?? this.creationDate,
      closingDate: closingDate ?? this.closingDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'author': this.author,
      'subject': this.subject,
      'agent': this.agent,
      'solution': this.solution,
      'isSolved': this.isSolved,
      'creationDate': Timestamp.fromDate(this.creationDate),
      'closingDate': Timestamp.fromDate(this.closingDate),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map, {String? id}) {

    final timestampCreationDate = map['creationDate'] as Timestamp;
    final timestampClosingDate = map['closingDate'] as Timestamp;

    return Ticket(
      id: id ?? map['id'] as String,
      author: map['author'] as String,
      subject: map['subject'] as String,
      agent: map['agent'] as String,
      solution: map['solution'] as String,
      isSolved: map['isSolved'] as bool,
      creationDate: timestampCreationDate.toDate(),
      closingDate: timestampClosingDate.toDate(),
    );
  }

//</editor-fold>
}