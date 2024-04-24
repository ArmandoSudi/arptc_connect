import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String? id;
  final String author;
  final String subject;
  final String category;
  final String agent;
  final String solution;
  final bool isSolved;
  final DateTime creationDate;

//<editor-fold desc="Data Methods">
  const Ticket({
    this.id,
    required this.author,
    required this.subject,
    required this.agent,
    required this.category,
    required this.solution,
    required this.isSolved,
    required this.creationDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ticket &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          author == other.author &&
          subject == other.subject &&
          category == other.category &&
          agent == other.agent &&
          solution == other.solution &&
          isSolved == other.isSolved &&
          creationDate == other.creationDate);

  @override
  int get hashCode =>
      id.hashCode ^
      author.hashCode ^
      subject.hashCode ^
      category.hashCode ^
      agent.hashCode ^
      solution.hashCode ^
      isSolved.hashCode ^
      creationDate.hashCode;

  @override
  String toString() {
    return 'Ticket{' +
        ' id: $id,' +
        ' author: $author,' +
        ' subject: $subject,' +
        ' category: $category,' +
        ' agent: $agent,' +
        ' solution: $solution,' +
        ' isSolved: $isSolved,' +
        ' creationDate: $creationDate,' +
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
  }) {
    return Ticket(
      id: id ?? this.id,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      agent: agent ?? this.agent,
      solution: solution ?? this.solution,
      isSolved: isSolved ?? this.isSolved,
      creationDate: creationDate ?? this.creationDate,
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'author': this.author,
      'subject': this.subject,
      'agent': this.agent,
      'category': this.category,
      'solution': this.solution,
      'isSolved': this.isSolved,
      'creationDate': Timestamp.fromDate(this.creationDate),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map, {String? id}) {

    final timestampCreationDate = map['creationDate'] as Timestamp;

    return Ticket(
      id: id ?? map['id'] as String,
      author: map['author'] as String,
      subject: map['subject'] as String,
      category: map['category'] as String,
      agent: map['agent'] as String,
      solution: map['solution'] as String,
      isSolved: map['isSolved'] as bool,
      creationDate: timestampCreationDate.toDate(),
    );
  }

//</editor-fold>

  String getIndex(int index) {
    switch (index) {
      case 0:
        return index.toString();
      case 1:
        return creationDate.formatedDate;
      case 2:
        return this.author;
      case 3:
        return this.agent;
      case 4:
        return this.subject;
    }
    return '';
  }
}