import 'package:equatable/equatable.dart';
import '../../../data/models/file_classification_model.dart';

abstract class FileClassificationState extends Equatable {
  const FileClassificationState();

  @override
  List<Object?> get props => [];
}

class FileClassificationInitial extends FileClassificationState {
  const FileClassificationInitial();
}

class FileClassificationLoading extends FileClassificationState {
  const FileClassificationLoading();
}

class AddFileClassificationLoading extends FileClassificationState {
  const AddFileClassificationLoading();
}

class AddFileClassificationSuccess extends FileClassificationState {
  final FileClassification fileClassification;
  final String message;

  const AddFileClassificationSuccess({
    required this.fileClassification,
    this.message = 'تم إضافة الفصل/الوحدة بنجاح',
  });

  @override
  List<Object> get props => [fileClassification, message];
}

class AddFileClassificationFailure extends FileClassificationState {
  final String message;

  const AddFileClassificationFailure({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

class FileClassificationsLoaded extends FileClassificationState {
  final List<FileClassification> fileClassifications;

  const FileClassificationsLoaded({
    required this.fileClassifications,
  });

  @override
  List<Object> get props => [fileClassifications];
}

class FileClassificationError extends FileClassificationState {
  final String message;

  const FileClassificationError({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}
