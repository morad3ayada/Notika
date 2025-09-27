import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ConferenceModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String levelSubjectId;
  final String subjectId;
  final String subjectName;
  final String levelId;
  final String levelName;
  final String classId;
  final String className;
  final String title;
  final String link;
  final DateTime createdAt;
  final DateTime startAt;
  final int durationMinutes;
  final bool isTemporary;

  const ConferenceModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.levelSubjectId,
    required this.subjectId,
    required this.subjectName,
    required this.levelId,
    required this.levelName,
    required this.classId,
    required this.className,
    required this.title,
    required this.link,
    required this.createdAt,
    required this.startAt,
    required this.durationMinutes,
    this.isTemporary = false,
  });

  factory ConferenceModel.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null || json['id'].toString().isEmpty) {
        debugPrint('⚠️ Conference missing id field, skipping...');
        throw const FormatException('Missing required field: id');
      }

      if (json['startAt'] == null || json['startAt'].toString().isEmpty) {
        debugPrint('⚠️ Conference missing startAt field, skipping...');
        throw const FormatException('Missing required field: startAt');
      }

      if (json['createdAt'] == null || json['createdAt'].toString().isEmpty) {
        debugPrint('⚠️ Conference missing createdAt field, skipping...');
        throw const FormatException('Missing required field: createdAt');
      }

      DateTime parsedStartAt;
      DateTime parsedCreatedAt;

      try {
        parsedStartAt = DateTime.parse(json['startAt'].toString());
        parsedCreatedAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        debugPrint('⚠️ Conference date parsing error: $e, skipping...');
        throw FormatException('Invalid date format: $e');
      }

      return ConferenceModel(
        id: json['id']?.toString() ?? '',
        teacherId: json['teacherId']?.toString() ?? '',
        teacherName: json['teacherName']?.toString() ?? '',
        levelSubjectId: json['levelSubjectId']?.toString() ?? '',
        subjectId: json['subjectId']?.toString() ?? '',
        subjectName: json['subjectName']?.toString() ?? '',
        levelId: json['levelId']?.toString() ?? '',
        levelName: json['levelName']?.toString() ?? '',
        classId: json['classId']?.toString() ?? '',
        className: json['className']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        link: json['link']?.toString() ?? '',
        createdAt: parsedCreatedAt,
        startAt: parsedStartAt,
        durationMinutes: json['durationMinutes'] is int 
            ? json['durationMinutes'] 
            : int.tryParse(json['durationMinutes']?.toString() ?? '0') ?? 0,
        isTemporary: json['isTemporary'] == true,
      );
    } catch (e) {
      debugPrint('⚠️ Error parsing conference from JSON: $e');
      rethrow;
    }
  }

  /// Creates a temporary conference from request data when server doesn't return full object
  factory ConferenceModel.fromRequestData(Map<String, dynamic> requestData) {
    final now = DateTime.now();
    final uuid = const Uuid();
    
    return ConferenceModel(
      id: uuid.v4(), // Generate temporary UUID
      teacherId: '', // Will be filled from current user context
      teacherName: '', // Will be filled from current user context
      levelSubjectId: requestData['levelSubjectId']?.toString() ?? '',
      subjectId: requestData['levelSubjectId']?.toString() ?? '', // Fallback
      subjectName: '', // Will be filled from context
      levelId: requestData['levelId']?.toString() ?? '',
      levelName: '', // Will be filled from context
      classId: requestData['classId']?.toString() ?? '',
      className: '', // Will be filled from context
      title: requestData['title']?.toString() ?? '',
      link: requestData['link']?.toString() ?? '',
      createdAt: now,
      startAt: requestData['startAt'] != null 
          ? DateTime.parse(requestData['startAt'].toString())
          : now,
      durationMinutes: requestData['durationMinutes'] is int
          ? requestData['durationMinutes']
          : int.tryParse(requestData['durationMinutes']?.toString() ?? '0') ?? 60,
      isTemporary: true, // Mark as temporary
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'levelSubjectId': levelSubjectId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'levelId': levelId,
      'levelName': levelName,
      'classId': classId,
      'className': className,
      'title': title,
      'link': link,
      'createdAt': createdAt.toIso8601String(),
      'startAt': startAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isTemporary': isTemporary,
    };
  }

  @override
  String toString() {
    return 'ConferenceModel(id: $id, title: $title, startAt: $startAt, durationMinutes: $durationMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConferenceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
