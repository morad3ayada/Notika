import 'package:equatable/equatable.dart';

abstract class FileClassificationEvent extends Equatable {
  const FileClassificationEvent();

  @override
  List<Object> get props => [];
}

class AddFileClassificationEvent extends FileClassificationEvent {
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String name;

  const AddFileClassificationEvent({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    required this.name,
  });

  @override
  List<Object> get props => [levelSubjectId, levelId, classId, name];
}

class LoadFileClassificationsEvent extends FileClassificationEvent {
  final String levelSubjectId;
  final String levelId;
  final String classId;

  const LoadFileClassificationsEvent({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object> get props => [levelSubjectId, levelId, classId];
}

class ResetFileClassificationEvent extends FileClassificationEvent {
  const ResetFileClassificationEvent();
}
