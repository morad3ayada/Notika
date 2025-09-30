import 'package:equatable/equatable.dart';

abstract class AllStudentsEvent extends Equatable {
  const AllStudentsEvent();

  @override
  List<Object?> get props => [];
}

/// حدث جلب جميع الطلاب
class LoadAllStudentsEvent extends AllStudentsEvent {
  const LoadAllStudentsEvent();
}

/// حدث البحث عن طلاب
class SearchAllStudentsEvent extends AllStudentsEvent {
  final String query;

  const SearchAllStudentsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// حدث تحديث قائمة الطلاب
class RefreshAllStudentsEvent extends AllStudentsEvent {
  const RefreshAllStudentsEvent();
}
