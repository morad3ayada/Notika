import 'package:equatable/equatable.dart';
import '../../../data/models/quick_tests_model.dart';

abstract class QuickTestsState extends Equatable {
  const QuickTestsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class QuickTestsInitial extends QuickTestsState {
  const QuickTestsInitial();
}

/// Loading state for any operation
class QuickTestsLoading extends QuickTestsState {
  const QuickTestsLoading();
}

/// Success state for adding a quick test
class QuickTestsSuccess extends QuickTestsState {
  final QuickTestModel quickTest;
  final String message;

  const QuickTestsSuccess({
    required this.quickTest,
    this.message = 'تم إضافة الاختبار بنجاح',
  });

  @override
  List<Object?> get props => [quickTest, message];
}

/// Failure state for any operation
class QuickTestsFailure extends QuickTestsState {
  final String message;

  const QuickTestsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// State for loaded quick tests
class QuickTestsLoaded extends QuickTestsState {
  final List<QuickTestModel> quickTests;

  const QuickTestsLoaded(this.quickTests);

  @override
  List<Object?> get props => [quickTests];
}

/// State for validation in progress
class QuickTestsValidating extends QuickTestsState {
  const QuickTestsValidating();
}

/// State for successful validation
class QuickTestsValidationSuccess extends QuickTestsState {
  final String message;

  const QuickTestsValidationSuccess({
    this.message = 'البيانات صحيحة',
  });

  @override
  List<Object?> get props => [message];
}

/// State for validation failure
class QuickTestsValidationFailure extends QuickTestsState {
  final String message;

  const QuickTestsValidationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
