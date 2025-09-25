import 'package:equatable/equatable.dart';

class Schedule extends Equatable {
  final String subjectName;
  final String schoolLocation;
  final String levelName;
  final String className;
  final int classOrder;
  final String startTime; // expected format from API, e.g., "08:00"
  final String endTime;   // expected format from API, e.g., "09:00"
  final int day; // 0 = Saturday ... 5 = Thursday

  const Schedule({
    required this.subjectName,
    required this.schoolLocation,
    this.levelName = '',
    this.className = '',
    required this.classOrder,
    required this.startTime,
    required this.endTime,
    required this.day,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      subjectName: json['subjectName']?.toString() ?? json['subject']?.toString() ?? '',
      schoolLocation: json['schoolLocation']?.toString() ?? json['school']?.toString() ?? '',
      levelName: json['levelName']?.toString() ?? json['level']?.toString() ?? '',
      className: json['className']?.toString() ?? json['class']?.toString() ?? '',
      classOrder: _toInt(json['classOrder'] ?? json['order'] ?? 0),
      startTime: json['startTime']?.toString() ?? json['start']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? json['end']?.toString() ?? '',
      day: _toInt(json['day'] ?? json['weekday'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectName': subjectName,
        'schoolLocation': schoolLocation,
        'levelName': levelName,
        'className': className,
        'classOrder': classOrder,
        'startTime': startTime,
        'endTime': endTime,
        'day': day,
      };

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [subjectName, schoolLocation, levelName, className, classOrder, startTime, endTime, day];
}
