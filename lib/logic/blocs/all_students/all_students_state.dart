import 'package:equatable/equatable.dart';
import '../../../data/models/all_students_model.dart';

abstract class AllStudentsState extends Equatable {
  const AllStudentsState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class AllStudentsInitial extends AllStudentsState {
  const AllStudentsInitial();
}

/// حالة التحميل
class AllStudentsLoading extends AllStudentsState {
  const AllStudentsLoading();
}

/// حالة النجاح - تم جلب الطلاب
class AllStudentsLoaded extends AllStudentsState {
  final List<AllStudent> students;
  final String message;

  const AllStudentsLoaded({
    required this.students,
    this.message = 'تم جلب الطلاب بنجاح',
  });

  @override
  List<Object?> get props => [students, message];
}

/// حالة القائمة الفارغة
class AllStudentsEmpty extends AllStudentsState {
  final String message;

  const AllStudentsEmpty({
    this.message = 'لا يوجد طلاب',
  });

  @override
  List<Object?> get props => [message];
}

/// حالة الخطأ
class AllStudentsError extends AllStudentsState {
  final String message;

  const AllStudentsError(this.message);

  @override
  List<Object?> get props => [message];
}
