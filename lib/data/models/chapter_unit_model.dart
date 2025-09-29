class ChapterUnit {
  final String  id;
  final String name;
  final String levelSubjectId;
  final String levelId;
  final String classId;
  final String? description;
  final bool isActive;

  ChapterUnit({
    required this.id,
    required this.name,
    required this.levelSubjectId,
    required this.levelId,
    required this.classId,
    this.description,
    required this.isActive,
  });

  factory ChapterUnit.fromJson(Map<String, dynamic> json) {
    return ChapterUnit(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      levelSubjectId: json['levelSubjectId']?.toString() ?? '',
      levelId: json['levelId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'levelSubjectId': levelSubjectId,
      'levelId': levelId,
      'classId': classId,
      'description': description,
      'isActive': isActive,
    };
  }
}

class ChapterUnitResponse {
  final bool success;
  final String message;
  final List<ChapterUnit> data;

  ChapterUnitResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ChapterUnitResponse.fromJson(Map<String, dynamic> json) {
    return ChapterUnitResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((item) => ChapterUnit.fromJson(item))
              .toList() ??
          [],
    );
  }

  // Constructor للحالة التي يرجع فيها الـ API List مباشرة
  factory ChapterUnitResponse.fromList(List<dynamic> list) {
    return ChapterUnitResponse(
      success: true,
      message: 'تم جلب البيانات بنجاح',
      data: list.map((item) => ChapterUnit.fromJson(item)).toList(),
    );
  }
}