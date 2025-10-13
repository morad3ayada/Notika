import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../logic/blocs/schedule/schedule_bloc.dart';
import '../../../logic/blocs/schedule/schedule_event.dart';
import '../../../logic/blocs/schedule/schedule_state.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/models/schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDay = DateTime.now();

  int _dayIndex(DateTime d) {
    switch (d.weekday) {
      case DateTime.saturday:
        return 0; // السبت
      case DateTime.sunday:
        return 1; // الأحد
      case DateTime.monday:
        return 2; // الاثنين
      case DateTime.tuesday:
        return 3; // الثلاثاء
      case DateTime.wednesday:
        return 4; // الأربعاء
      case DateTime.thursday:
        return 5; // الخميس
      default:
        return 6; // الجمعة (نتجاهلها)
    }
  }

  @override
  Widget build(BuildContext context) {
    // أسماء الأيام بالعربية (0 السبت -> 5 الخميس)
    const dayNames = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];

    return BlocProvider(
      create: (_) => ScheduleBloc(repository: ScheduleRepository())
        ..add(const FetchScheduleEvent()),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              // التقويم الأفقي العصري (كما كان سابقًا)
              Builder(
                builder: (context) {
                  final today = DateTime.now();
                  bool isToday(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withAlpha(220),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.0),
                          child: Icon(Icons.calendar_today, color: Color(0xFF1976D2), size: 22),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 64,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 7,
                              separatorBuilder: (context, index) => const SizedBox(width: 4),
                              itemBuilder: (context, index) {
                                // تخطي الجمعة
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
                                    DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(_selectedDay);
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
                                                colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                                begin: Alignment.topRight,
                                                end: Alignment.bottomLeft,
                                              )
                                            : null,
                                        color: isSelected ? null : Theme.of(context).cardColor,
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: const Color(0xFF1976D2).withAlpha(40),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                        ],
                                        border: Border.all(
                                          color: isToday(day) ? const Color(0xFF1976D2) : Colors.transparent,
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
                                              color: isSelected ? Colors.white : const Color(0xFF1976D2),
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
                                                    color: const Color(0xFF1976D2).withAlpha(80),
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
                  );
                },
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
              // قسم الحصص (بواسطة BLoC)
              BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  if (state is ScheduleLoading) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is ScheduleError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<ScheduleBloc>().add(const FetchScheduleEvent()),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is ScheduleLoaded) {
                    final dayIdx = _dayIndex(_selectedDay);
                    final dayLessons = state.schedules
                        .where((s) => s.day == dayIdx)
                        .toList()
                      ..sort((a, b) => a.classOrder.compareTo(b.classOrder));

                    if (dayLessons.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty, size: 60, color: Color(0xFFB0BEC5)),
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
                      );
                    }

                    return Column(
                      children: dayLessons.map((s) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1976D2).withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 28,
                              child: Icon(Icons.location_on, color: Color(0xFF1976D2), size: 32),
                            ),
                            title: Text(
                              s.subjectName,
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
                                    'الموقع: ${s.schoolLocation.isEmpty ? 'غير محدد' : s.schoolLocation}${(s.levelName.isNotEmpty || s.className.isNotEmpty) ? ' - ${s.levelName} ${s.className}' : ''}',
                                    style: const TextStyle(color: Color(0xFFE3F2FD), fontSize: 15),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  Text(
                                    'رقم الدرس: ${s.classOrder}',
                                    style: const TextStyle(color: Color(0xFFE3F2FD), fontSize: 15),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  Text(
                                    'الوقت: ${s.startTime} - ${s.endTime}',
                                    style: const TextStyle(color: Color(0xFFE3F2FD), fontSize: 15),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
