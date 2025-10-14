import 'package:equatable/equatable.dart';

/// نموذج بيانات الطالب الواحد
class Student extends Equatable {
  final String? id;
  final String? fullName;
  final String? userName;
  final String? phone;
  final String? email;
  final String? levelId;
  final String? classId;
  final String? levelName;
  final String? className;
  final String? studentClassSubjectId;  // ✅ إضافة studentClassSubjectId
  final bool? isActive;
  final DateTime? createdAt;

  const Student({
    this.id,
    this.fullName,
    this.userName,
    this.phone,
    this.email,
    this.levelId,
    this.classId,
    this.levelName,
    this.className,
    this.studentClassSubjectId,
    this.isActive,
    this.createdAt,
  });

  /// إنشاء من JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    // طباعة البيانات الخام للتشخيص
    print('🔍 تحليل JSON للطالب: $json');
    
    // بناء الاسم الكامل من الحقول المنفصلة
    String? constructedFullName;
    final firstName = json['firstName']?.toString()?.trim();
    final secondName = json['secondName']?.toString()?.trim();
    final thirdName = json['thirdName']?.toString()?.trim();
    final fourthName = json['fourthName']?.toString()?.trim();
    final nickName = json['nickName']?.toString()?.trim();
    
    if (firstName != null && firstName.isNotEmpty) {
      List<String> nameParts = [firstName];
      
      if (secondName != null && secondName.isNotEmpty && secondName != 'l') {
        nameParts.add(secondName);
      }
      if (thirdName != null && thirdName.isNotEmpty && thirdName != 'l') {
        nameParts.add(thirdName);
      }
      if (fourthName != null && fourthName.isNotEmpty && fourthName != 'l') {
        nameParts.add(fourthName);
      }
      
      constructedFullName = nameParts.join(' ');
      print('✅ تم بناء الاسم الكامل: $constructedFullName من الأجزاء: $nameParts');
    }
    
    return Student(
      id: json['id']?.toString() ?? 
          json['studentId']?.toString() ??
          json['Id']?.toString(),
      fullName: constructedFullName ??
                json['fullName']?.toString() ?? 
                json['full_name']?.toString() ??
                json['name']?.toString() ??
                json['studentName']?.toString() ??
                json['Name']?.toString() ??
                json['FullName']?.toString() ??
                json['StudentName']?.toString() ??
                json['displayName']?.toString() ??
                json['DisplayName']?.toString() ??
                nickName,
      userName: json['userName']?.toString() ?? 
                json['user_name']?.toString() ??
                json['username']?.toString() ??
                json['UserName']?.toString(),
      phone: json['phone']?.toString() ?? 
             json['phoneNumber']?.toString() ??
             json['Phone']?.toString(),
      email: json['email']?.toString() ?? 
             json['Email']?.toString(),
      levelId: json['levelId']?.toString() ?? 
               json['LevelId']?.toString(),
      classId: json['classId']?.toString() ?? 
               json['ClassId']?.toString(),
      levelName: json['levelName']?.toString() ?? 
                 json['LevelName']?.toString(),
      className: json['className']?.toString() ?? 
                 json['ClassName']?.toString(),
      studentClassSubjectId: json['studentClassSubjectId']?.toString() ??
                           json['StudentClassSubjectId']?.toString(),
      isActive: json['isActive'] as bool? ?? 
                json['IsActive'] as bool? ?? 
                true, // افتراضي true
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : json['CreatedAt'] != null 
              ? DateTime.tryParse(json['CreatedAt'].toString())
              : null,
    
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'userName': userName,
      'phone': phone,
      'email': email,
      'levelId': levelId,
      'classId': classId,
      'levelName': levelName,
      'className': className,
      'studentClassSubjectId': studentClassSubjectId,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// الحصول على الاسم المختصر للعرض
  String get displayName {
    // طباعة البيانات للتشخيص
    print('🔍 بيانات الطالب: fullName="$fullName", userName="$userName", id="$id"');
    
    if (fullName != null && fullName!.trim().isNotEmpty) {
      final result = fullName!.trim();
      print('📝 سيتم عرض الاسم الكامل: "$result"');
      return result;
    } else if (userName != null && userName!.trim().isNotEmpty) {
      final result = userName!.trim();
      print('📝 سيتم عرض اسم المستخدم: "$result"');
      return result;
    } else if (id != null && id!.trim().isNotEmpty) {
      // عرض جزء من المعرف بدون كلمة "طالب"
      final result = id!.length > 8 ? id!.substring(0, 8) : id!;
      print('📝 سيتم عرض المعرف: "$result"');
      return result;
    } else {
      print('📝 سيتم عرض: "غير محدد"');
      return 'غير محدد';
    }
  }

  /// الحصول على الحرف الأول للاسم
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final names = fullName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}';
      } else {
        return fullName![0];
      }
    } else if (userName != null && userName!.isNotEmpty) {
      return userName![0];
    } else {
      return '؟';
    }
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        userName,
        phone,
        email,
        levelId,
        classId,
        levelName,
        className,
        studentClassSubjectId,
        isActive,
        createdAt,
      ];
}

/// نموذج استجابة جلب طلاب الفصل
class ClassStudentsResponse extends Equatable {
  final bool success;
  final String message;
  final List<Student> students;
  final int totalCount;

  const ClassStudentsResponse({
    required this.success,
    required this.message,
    required this.students,
    this.totalCount = 0,
  });

  factory ClassStudentsResponse.success({
    required List<Student> students,
    String message = 'تم جلب الطلاب بنجاح',
  }) {
    return ClassStudentsResponse(
      success: true,
      message: message,
      students: students,
      totalCount: students.length,
    );
  }

  factory ClassStudentsResponse.error(String message) {
    return ClassStudentsResponse(
      success: false,
      message: message,
      students: const [],
      totalCount: 0,
    );
  }

  /// إنشاء من JSON
  factory ClassStudentsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> studentsJson = json['students'] ?? json['data'] ?? [];
    final students = studentsJson.map((studentJson) => Student.fromJson(studentJson)).toList();
    
    return ClassStudentsResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'تم جلب الطلاب بنجاح',
      students: students,
      totalCount: json['totalCount'] ?? students.length,
    );
  }

  @override
  List<Object?> get props => [success, message, students, totalCount];
}

/// نموذج طلب جلب طلاب الفصل
class ClassStudentsRequest extends Equatable {
  final String levelId;
  final String classId;

  const ClassStudentsRequest({
    required this.levelId,
    required this.classId,
  });

  /// تحويل إلى query parameters
  Map<String, String> toQueryParams() {
    return {
      'LevelId': levelId,
      'ClassId': classId,
    };
  }

  @override
  List<Object?> get props => [levelId, classId];
}
