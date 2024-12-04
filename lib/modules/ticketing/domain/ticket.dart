import 'dart:developer';

import 'package:arptc_connect/extensions/date_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String? id;
  final String author;
  final String subject;
  final String category;
  final String agent;
  final String? solution;
  final bool isSolved;
  final DateTime creationDate;

  final DateTime? closureDate;

//<editor-fold desc="Data Methods">
  const Ticket({
    this.id,
    required this.author,
    required this.subject,
    required this.agent,
    required this.category,
    this.solution,
    required this.isSolved,
    required this.creationDate,
    this.closureDate,
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
          creationDate == other.creationDate &&
          closureDate == other.closureDate );

  @override
  int get hashCode =>
      id.hashCode ^
      author.hashCode ^
      subject.hashCode ^
      category.hashCode ^
      agent.hashCode ^
      solution.hashCode ^
      isSolved.hashCode ^
      creationDate.hashCode^
    closureDate.hashCode;

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
        ' closureDate: $closureDate,' +
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
      closureDate: closureDate ?? this.closureDate,
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
      // 'closureDate': Timestamp.fromDate(this.closureDate),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map, {String? id}) {

    final timestampCreationDate = map['creationDate'] as Timestamp;
    var closureDate;

    if (map['closureDate'] == null) {
      closureDate = null;
    } else {
      closureDate = (map['closureDate'] as Timestamp).toDate(); // Convert to DateTime
    }

    return Ticket(
      id: id ?? map['id'] as String,
      author: map['author'] as String,
      subject: map['subject'] as String,
      category: map['category'] as String,
      agent: map['agent'] as String,
      solution: map['solution'],
      isSolved: map['isSolved'] as bool,
      creationDate: timestampCreationDate.toDate(),
      closureDate: closureDate,
    );
  }

//</editor-fold>

  String getField(int row, int col) {
    switch (col) {
      case 0:
        return (row+1).toString();
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