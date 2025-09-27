import 'package:equatable/equatable.dart';

class FileClassification extends Equatable {
  final String? id;
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String name;
  final DateTime? createdAt;

  const FileClassification({
    this.id,
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.name,
    this.createdAt,
  });

  factory FileClassification.fromJson(Map<String, dynamic> json) {
    return FileClassification(
      id: json['id']?.toString(),
      levelSubjectId: json['levelSubjectId']?.toString() ?? '',
      levelId: json['levelId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'name': name,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        levelSubjectId,
        levelId,
        classId,
        name,
        createdAt,
      ];
}

class CreateFileClassificationRequest extends Equatable {
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String name;

  const CreateFileClassificationRequest({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'name': name,
    };
  }

  @override
  List<Object> get props => [
        levelSubjectId,
        levelId,
        classId,
        name,
      ];
}
