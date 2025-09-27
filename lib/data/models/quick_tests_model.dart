import 'package:equatable/equatable.dart';

class QuickTestModel extends Equatable {
  final String? id;
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String title;
  final DateTime deadline;
  final String questionsJson;
  final String answersJson;
  final int durationMinutes;
  final int maxGrade;
  final DateTime? createdAt;

  const QuickTestModel({
    this.id,
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.title,
    required this.deadline,
    required this.questionsJson,
    required this.answersJson,
    required this.durationMinutes,
    required this.maxGrade,
    this.createdAt,
  });

  factory QuickTestModel.fromJson(Map<String, dynamic> json) {
    return QuickTestModel(
      id: json['id']?.toString(),
      levelSubjectId: json['levelSubjectId']?.toString() ?? '',
      levelId: json['levelId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'].toString())
          : DateTime.now(),
      questionsJson: json['questionsJson']?.toString() ?? '[]',
      answersJson: json['answersJson']?.toString() ?? '[]',
      durationMinutes: json['durationMinutes'] is int 
          ? json['durationMinutes'] 
          : int.tryParse(json['durationMinutes']?.toString() ?? '0') ?? 0,
      maxGrade: json['maxGrade'] is int 
          ? json['maxGrade'] 
          : int.tryParse(json['maxGrade']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'title': title,
      'deadline': deadline.toIso8601String(),
      'questionsJson': questionsJson,
      'answersJson': answersJson,
      'durationMinutes': durationMinutes,
      'maxGrade': maxGrade,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  QuickTestModel copyWith({
    String? id,
    String? levelSubjectId,
    String? levelId,
    String? classId,
    String? title,
    DateTime? deadline,
    String? questionsJson,
    String? answersJson,
    int? durationMinutes,
    int? maxGrade,
    DateTime? createdAt,
  }) {
    return QuickTestModel(
      id: id ?? this.id,
      levelSubjectId: levelSubjectId ?? this.levelSubjectId,
      levelId: levelId ?? this.levelId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      questionsJson: questionsJson ?? this.questionsJson,
      answersJson: answersJson ?? this.answersJson,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxGrade: maxGrade ?? this.maxGrade,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        levelSubjectId,
        levelId,
        classId,
        title,
        deadline,
        questionsJson,
        answersJson,
        durationMinutes,
        maxGrade,
        createdAt,
      ];
}

/// DTO for creating a new quick test
class CreateQuickTestRequest extends Equatable {
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String title;
  final DateTime deadline;
  final String questionsJson;
  final String answersJson;
  final int durationMinutes;
  final int maxGrade;

  const CreateQuickTestRequest({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.title,
    required this.deadline,
    required this.questionsJson,
    required this.answersJson,
    required this.durationMinutes,
    required this.maxGrade,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'title': title,
      'deadline': deadline.toIso8601String(),
      'questionsJson': questionsJson,
      'answersJson': answersJson,
      'durationMinutes': durationMinutes,
      'maxGrade': maxGrade,
    };
  }

  @override
  List<Object?> get props => [
        levelSubjectId,
        levelId,
        classId,
        title,
        deadline,
        questionsJson,
        answersJson,
        durationMinutes,
        maxGrade,
      ];
}
