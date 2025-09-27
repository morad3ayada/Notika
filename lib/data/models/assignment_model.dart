import 'package:equatable/equatable.dart';

class AssignmentModel extends Equatable {
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String title;
  final String deadline;
  final int maxGrade;
  final String contentType;
  final String content;

  const AssignmentModel({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.title,
    required this.deadline,
    required this.maxGrade,
    required this.contentType,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'title': title,
      'deadline': deadline,
      'maxGrade': maxGrade,
      'contentType': contentType,
      'content': content,
    };
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      levelSubjectId: json['levelSubjectId'] ?? '',
      levelId: json['levelId'] ?? '',
      classId: json['classId'] ?? '',
      title: json['title'] ?? '',
      deadline: json['deadline'] ?? '',
      maxGrade: json['maxGrade'] ?? 0,
      contentType: json['contentType'] ?? '',
      content: json['content'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        levelSubjectId,
        levelId,
        classId,
        title,
        deadline,
        maxGrade,
        contentType,
        content,
      ];
}

class CreateAssignmentRequest extends Equatable {
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String title;
  final String deadline;
  final int maxGrade;
  final String contentType;
  final String content;

  const CreateAssignmentRequest({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.title,
    required this.deadline,
    required this.maxGrade,
    required this.contentType,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'title': title,
      'deadline': deadline,
      'maxGrade': maxGrade,
      'contentType': contentType,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [
        levelSubjectId,
        levelId,
        classId,
        title,
        deadline,
        maxGrade,
        contentType,
        content,
      ];
}
