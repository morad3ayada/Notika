import 'package:equatable/equatable.dart';
/// نموذج بيانات عنوان الدرجة الواحد
class DailyGradeTitle extends Equatable {
  final String? id;
  String? title;  // Made non-final for editing
  final String? description;
  double? maxGrade;  // Made non-final for editing, and changed from int to double for decimal support
  final int? order;
  final bool? isActive;
  final String? levelSubjectId;
  final String? levelId;
  final String? classId;
  final DateTime? createdAt;

  DailyGradeTitle({
    this.id,
    this.title,
    this.description,
    this.maxGrade,
    this.order,
    this.isActive,
    this.levelSubjectId,
    this.levelId,
    this.classId,
    this.createdAt,
  });

  /// نسخ الكائن مع تعديل بعض الخصائص
  DailyGradeTitle copyWith({
    String? id,
    String? title,
    String? description,
    double? maxGrade,
    int? order,
    bool? isActive,
    String? levelSubjectId,
    String? levelId,
    String? classId,
    DateTime? createdAt,
  }) {
    return DailyGradeTitle(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      maxGrade: maxGrade ?? this.maxGrade,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      levelSubjectId: levelSubjectId ?? this.levelSubjectId,
      levelId: levelId ?? this.levelId,
      classId: classId ?? this.classId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// إنشاء من JSON بطريقة آمنة ومرنة
  factory DailyGradeTitle.fromJson(Map<String, dynamic> json) {
    print('🔍 تحليل JSON لعنوان الدرجة: $json');
    
    // دالة مساعدة لتحويل الأرقام بشكل آمن
    double? parseMaxGrade(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    return DailyGradeTitle(
      id: json['id']?.toString() ?? 
          json['Id']?.toString(),
      title: json['title']?.toString() ?? 
             json['Title']?.toString() ??
             json['name']?.toString() ??
             json['Name']?.toString(),
      description: json['description']?.toString() ?? 
                   json['Description']?.toString(),
      maxGrade: parseMaxGrade(json['maxGrade']) ?? 
                parseMaxGrade(json['MaxGrade']) ??
                parseMaxGrade(json['max_grade']) ??
                0.0,
      order: parseInt(json['order']) ?? 
             parseInt(json['Order']) ??
             parseInt(json['sort_order']) ??
             0,
      isActive: json['isActive'] as bool? ?? 
                json['IsActive'] as bool? ?? 
                true,
      levelSubjectId: json['levelSubjectId']?.toString() ?? 
                      json['LevelSubjectId']?.toString(),
      levelId: json['levelId']?.toString() ?? 
               json['LevelId']?.toString(),
      classId: json['classId']?.toString() ?? 
               json['ClassId']?.toString(),
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
      'title': title,
      'description': description,
      'maxGrade': maxGrade,
      'order': order,
      'isActive': isActive,
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// الحصول على العنوان للعرض
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    } else {
      return 'عنوان غير محدد';
    }
  }

  @override
  List<Object?> get props => [
        id,
        // title, // Removed because it's mutable
        description,
        // maxGrade, // Removed because it's mutable
        order,
        isActive,
        levelSubjectId,
        levelId,
        classId,
        createdAt,
      ];
}

/// نموذج استجابة جلب عناوين الدرجات
class DailyGradeTitlesResponse extends Equatable {
  final bool success;
  final String message;
  final List<DailyGradeTitle> titles;
  final int totalCount;

  const DailyGradeTitlesResponse({
    required this.success,
    required this.message,
    required this.titles,
    this.totalCount = 0,
  });

  factory DailyGradeTitlesResponse.success({
    required List<DailyGradeTitle> titles,
    String message = 'تم جلب عناوين الدرجات بنجاح',
  }) {
    return DailyGradeTitlesResponse(
      success: true,
      message: message,
      titles: titles,
      totalCount: titles.length,
    );
  }

  factory DailyGradeTitlesResponse.error(String message) {
    return DailyGradeTitlesResponse(
      success: false,
      message: message,
      titles: const [],
      totalCount: 0,
    );
  }

  /// إنشاء من JSON
  factory DailyGradeTitlesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> titlesJson = json['titles'] ?? json['data'] ?? [];
    final titles = titlesJson.map((titleJson) => DailyGradeTitle.fromJson(titleJson)).toList();
    
    return DailyGradeTitlesResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'تم جلب عناوين الدرجات بنجاح',
      titles: titles,
      totalCount: json['totalCount'] ?? titles.length,
    );
  }

  @override
  List<Object?> get props => [success, message, titles, totalCount];
}

/// نموذج طلب جلب عناوين الدرجات
class DailyGradeTitlesRequest extends Equatable {
  final String levelSubjectId;
  final String levelId;
  final String classId;

  const DailyGradeTitlesRequest({
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
  });

  /// تحويل إلى query parameters
  Map<String, String> toQueryParams() {
    return {
      'LevelSubjectId': levelSubjectId,
      'LevelId': levelId,
      'ClassId': classId,
    };
  }

  @override
  List<Object?> get props => [levelSubjectId, levelId, classId];
}
