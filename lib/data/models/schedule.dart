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
    print('📅 Schedule.fromJson:');
    print('   - Raw JSON: $json');
    print('   - startTime: ${json['startTime']} (${json['startTime'].runtimeType})');
    print('   - endTime: ${json['endTime']} (${json['endTime'].runtimeType})');
    
    return Schedule(
      subjectName: json['subjectName']?.toString() ?? json['subject']?.toString() ?? '',
      schoolLocation: json['schoolLocation']?.toString() ?? json['school']?.toString() ?? '',
      levelName: json['levelName']?.toString() ?? json['level']?.toString() ?? '',
      className: json['className']?.toString() ?? json['class']?.toString() ?? '',
      classOrder: _toInt(json['classOrder'] ?? json['order'] ?? 0),
      startTime: _parseTime(json['startTime'] ?? json['start']),
      endTime: _parseTime(json['endTime'] ?? json['end']),
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

  static String _parseTime(dynamic time) {
    if (time == null) {
      print('   ⚠️ Time is null, returning empty string');
      return '';
    }
    
    print('   🕐 Parsing time: $time (type: ${time.runtimeType})');
    
    // إذا كان String بالفعل
    if (time is String) {
      // إذا كانت الصيغة ISO 8601 مثل "2025-10-14T08:30:00"
      if (time.contains('T')) {
        try {
          final dateTime = DateTime.parse(time);
          final formatted = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          print('   ✅ Parsed from ISO8601: $formatted');
          return formatted;
        } catch (e) {
          print('   ❌ Failed to parse ISO8601: $e');
        }
      }
      
      // إذا كانت بالفعل بصيغة HH:mm أو H:mm
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          try {
            final hour = int.parse(parts[0]).toString().padLeft(2, '0');
            final minute = int.parse(parts[1]).toString().padLeft(2, '0');
            final formatted = '$hour:$minute';
            print('   ✅ Formatted time: $formatted');
            return formatted;
          } catch (e) {
            print('   ❌ Failed to parse HH:mm: $e');
          }
        }
      }
      
      print('   ℹ️ Returning time as is: $time');
      return time;
    }
    
    // إذا كان DateTime object
    if (time is DateTime) {
      final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      print('   ✅ Parsed from DateTime: $formatted');
      return formatted;
    }
    
    // إذا كان Map (قد يحتوي على hour و minute)
    if (time is Map) {
      try {
        final hour = (time['hour'] ?? time['Hour'] ?? 0).toString().padLeft(2, '0');
        final minute = (time['minute'] ?? time['Minute'] ?? 0).toString().padLeft(2, '0');
        final formatted = '$hour:$minute';
        print('   ✅ Parsed from Map: $formatted');
        return formatted;
      } catch (e) {
        print('   ❌ Failed to parse Map: $e');
      }
    }
    
    // fallback: حاول toString()
    final str = time.toString();
    print('   ⚠️ Fallback to toString(): $str');
    return str;
  }

  @override
  List<Object?> get props => [subjectName, schoolLocation, levelName, className, classOrder, startTime, endTime, day];
}
