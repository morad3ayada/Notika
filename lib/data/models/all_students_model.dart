import 'package:equatable/equatable.dart';

/// نموذج بيانات الطالب من API جميع الطلاب
class AllStudent extends Equatable {
  final String? userId;
  final String? studentId;
  final String? studentClassId;
  final String? picture;
  final String? firstName;
  final String? secondName;
  final String? thirdName;
  final String? fourthName;
  final String? nickName;
  final String? religion;
  final String? gender;

  const AllStudent({
    this.userId,
    this.studentId,
    this.studentClassId,
    this.picture,
    this.firstName,
    this.secondName,
    this.thirdName,
    this.fourthName,
    this.nickName,
    this.religion,
    this.gender,
  });

  /// الحصول على الاسم الكامل
  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.trim().isNotEmpty) {
      parts.add(firstName!.trim());
    }
    if (secondName != null && secondName!.trim().isNotEmpty) {
      parts.add(secondName!.trim());
    }
    if (thirdName != null && thirdName!.trim().isNotEmpty) {
      parts.add(thirdName!.trim());
    }
    if (fourthName != null && fourthName!.trim().isNotEmpty) {
      parts.add(fourthName!.trim());
    }
    
    if (parts.isEmpty) return 'غير محدد';
    return parts.join(' ');
  }

  /// الحصول على الاسم للعرض (مع fallback للـ nickName)
  String get displayName {
    final full = fullName;
    if (full != 'غير محدد') return full;
    if (nickName != null && nickName!.trim().isNotEmpty) {
      return nickName!.trim();
    }
    return 'طالب';
  }

  /// الحصول على الحرف الأول من الاسم
  String get initial {
    if (firstName != null && firstName!.trim().isNotEmpty) {
      return firstName!.trim().substring(0, 1);
    }
    if (nickName != null && nickName!.trim().isNotEmpty) {
      return nickName!.trim().substring(0, 1);
    }
    return 'ط';
  }

  /// إنشاء من JSON
  factory AllStudent.fromJson(Map<String, dynamic> json) {
    print('🔍 تحليل JSON للطالب: $json');
    
    return AllStudent(
      userId: json['userId']?.toString(),
      studentId: json['studentId']?.toString(),
      studentClassId: json['studentClassId']?.toString(),
      picture: json['picture']?.toString(),
      firstName: json['firstName']?.toString(),
      secondName: json['secondName']?.toString(),
      thirdName: json['thirdName']?.toString(),
      fourthName: json['fourthName']?.toString(),
      nickName: json['nickName']?.toString(),
      religion: json['religin']?.toString() ?? json['religion']?.toString(),
      gender: json['gender']?.toString(),
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'studentId': studentId,
      'studentClassId': studentClassId,
      'picture': picture,
      'firstName': firstName,
      'secondName': secondName,
      'thirdName': thirdName,
      'fourthName': fourthName,
      'nickName': nickName,
      'religion': religion,
      'gender': gender,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        studentId,
        studentClassId,
        picture,
        firstName,
        secondName,
        thirdName,
        fourthName,
        nickName,
        religion,
        gender,
      ];
}

/// نموذج استجابة جلب جميع الطلاب
class AllStudentsResponse extends Equatable {
  final bool success;
  final String message;
  final List<AllStudent> students;
  final int totalCount;

  const AllStudentsResponse({
    required this.success,
    required this.message,
    required this.students,
    this.totalCount = 0,
  });

  factory AllStudentsResponse.success({
    required List<AllStudent> students,
    String message = 'تم جلب الطلاب بنجاح',
  }) {
    return AllStudentsResponse(
      success: true,
      message: message,
      students: students,
      totalCount: students.length,
    );
  }

  factory AllStudentsResponse.error(String message) {
    return AllStudentsResponse(
      success: false,
      message: message,
      students: const [],
      totalCount: 0,
    );
  }

  @override
  List<Object?> get props => [success, message, students, totalCount];
}
