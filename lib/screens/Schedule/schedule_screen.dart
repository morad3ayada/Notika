import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();

  // بيانات جدول الحصص - أسبوعين
  final Map<String, List<Map<String, dynamic>>> lessons = {
    // الأسبوع الأول - الأحد
    '2025-07-12': [
      {
        'subject': 'اللغة العربية',
        'school': 'مدرسة النور',
        'stage': 'الأول ابتدائي',
        'section': 'شعبة أ',
        'time': '8:00 - 9:00',
      },
      {
        'subject': 'التربية الإسلامية',
        'school': 'مدرسة النور',
        'stage': 'الأول ابتدائي',
        'section': 'شعبة ب',
        'time': '9:15 - 10:15',
      },
    ],
    // الأسبوع الأول - الاثنين
    '2025-07-13': [
      {
        'subject': 'اللغة العربية',
        'school': 'مدرسة النور',
        'stage': 'الثاني ابتدائي',
        'section': 'شعبة أ',
        'time': '8:00 - 9:00',
      },
    ],
    // الأسبوع الأول - الثلاثاء
    '2025-07-14': [
      {
        'subject': 'التربية الإسلامية',
        'school': 'مدرسة النور',
        'stage': 'الثاني ابتدائي',
        'section': 'شعبة ب',
        'time': '9:15 - 10:15',
      },
    ],
    // الأسبوع الأول - الأربعاء
    '2025-07-15': [
      {
        'subject': 'اللغة العربية',
        'school': 'مدرسة النور',
        'stage': 'الثالث ابتدائي',
        'section': 'شعبة أ',
        'time': '10:30 - 11:30',
      },
    ],
    // الأسبوع الأول - الخميس
    '2025-07-16': [
      {
        'subject': 'التربية الإسلامية',
        'school': 'مدرسة النور',
        'stage': 'الثالث ابتدائي',
        'section': 'شعبة ب',
        'time': '8:00 - 9:00',
      },
    ],
    // الأسبوع الأول - السبت
    '2025-07-18': [
      {
        'subject': 'التربية الإسلامية',
        'school': 'مدرسة النور',
        'stage': 'الرابع ابتدائي',
        'section': 'شعبة أ',
        'time': '10:30 - 11:30',
      },
    ],
    // الأسبوع الثاني - الأحد
    '2025-07-19': [
      {
        'subject': 'اللغة العربية',
        'school': 'مدرسة النور',
        'stage': 'الرابع ابتدائي',
        'section': 'شعبة ب',
        'time': '8:00 - 9:00',
      },
    ],
    // الأسبوع الثاني - الاثنين
    '2025-07-20': [
      {
        'subject': 'التربية الإسلامية',
        'school': 'مدرسة النور',
        'stage': 'الخامس ابتدائي',
        'section': 'شعبة أ',
        'time': '9:15 - 10:15',
      },
    ],
    // الأسبوع الثاني - الثلاثاء
    '2025-07-21': [
      {
        'subject': 'اللغة العربية',
        'school': 'مدرسة النور',
        'stage': 'الخامس ابتدائي',
        'section': 'شعبة ب',
        'time': '10:30 - 11:30',
      },
    ],
    // الأسبوع الثاني - الأربعاء
    '2025-07-22': [
      {
        'subject': 'التربية الإسلامية',
        'school': 'مدرسة النور',
        'stage': 'السادس ابتدائي',
        'section': 'شعبة أ',
        'time': '8:00 - 9:00',
      },
    ],
    // الأسبوع الثاني - الخميس
    '2025-07-23': [
      {
        'subject': 'اللغة العربية',
        'school': 'مدرسة النور',
        'stage': 'السادس ابتدائي',
        'section': 'شعبة ب',
        'time': '9:15 - 10:15',
      },
    ],
    // الأسبوع الثاني - السبت
    '2025-07-25': [
      {
        'subject': 'اللغة العربية',
        'school': 'مدرسة النور',
        'stage': 'الأول ابتدائي',
        'section': 'شعبة أ',
        'time': '8:00 - 9:00',
      },
    ],
  };

  List<Map<String, dynamic>> get _dayLessons {
    final key = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return lessons[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = (DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            // تقويم أفقي عصري
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withAlpha(220),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(Icons.calendar_today,
                        color: Color(0xFF1976D2), size: 22),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        separatorBuilder: (context, index) => SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          // Skip Fridays
                          int added = 0;
                          DateTime day = DateTime.now();
                          while (added <= index) {
                            if (day.weekday != DateTime.friday) {
                              if (added == index) break;
                              added++;
                            }
                            day = day.add(const Duration(days: 1));
                          }
                          final isSelected =
                              DateFormat('yyyy-MM-dd').format(day) ==
                                  DateFormat('yyyy-MM-dd').format(_selectedDay);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = day),
                            child: AnimatedScale(
                              scale: isSelected ? 1.18 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: Container(
                                width: 48,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF1976D2),
                                            Color(0xFF64B5F6)
                                          ],
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                        )
                                      : null,
                                  color: isSelected ? null : Theme.of(context).cardColor,
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: Color(0xFF1976D2).withAlpha(40),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                  ],
                                  border: Border.all(
                                    color: isToday(day)
                                        ? const Color(0xFF1976D2)
                                        : Colors.transparent,
                                    width: isToday(day) ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat('d').format(day),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF233A5A),
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('E', 'ar').format(day),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1976D2),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (isToday(day))
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1976D2),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF1976D2)
                                                  .withAlpha(80),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // عنوان اليوم
            Center(
              child: Text(
                'حصص يوم ${DateFormat('EEEE, d MMMM', 'ar').format(_selectedDay)}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF233A5A),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // كروت الحصص أو رسالة ودية
            if (_dayLessons.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: const [
                    Icon(Icons.hourglass_empty,
                        size: 60, color: Color(0xFFB0BEC5)),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد حصص لهذا اليوم',
                      style: TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._dayLessons.map((lesson) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF1976D2).withAlpha(30),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 28,
                        child: Icon(
                          Icons.location_on,
                          color: Color(0xFF1976D2),
                          size: 32,
                        ),
                      ),
                      title: Text(
                        lesson['subject'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: 0.2,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                      subtitle: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المدرسة: ${lesson['school'] ?? 'غير محددة'}',
                              style: const TextStyle(
                                color: Color(0xFFE3F2FD),
                                fontSize: 15,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            if (lesson['stage'] != null)
                              Text(
                                'المرحلة: ${lesson['stage']}',
                                style: const TextStyle(
                                  color: Color(0xFFE3F2FD),
                                  fontSize: 15,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            if (lesson['section'] != null)
                              Text(
                                'الشعبة: ${lesson['section']}',
                                style: const TextStyle(
                                  color: Color(0xFFE3F2FD),
                                  fontSize: 15,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            Text(
                              'الوقت: ${lesson['time']}',
                              style: const TextStyle(
                                color: Color(0xFFE3F2FD),
                                fontSize: 15,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
