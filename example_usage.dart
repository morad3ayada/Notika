import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notika_teacher/data/models/daily_grades_model.dart';
import 'package:notika_teacher/data/repositories/daily_grades_repository.dart';
import 'package:notika_teacher/di/injector.dart';

class ExampleUsageWidget extends StatefulWidget {
  const ExampleUsageWidget({super.key});

  @override
  State<ExampleUsageWidget> createState() => _ExampleUsageWidgetState();
}

class _ExampleUsageWidgetState extends State<ExampleUsageWidget> {
  bool _isLoading = false;
  String _resultMessage = '';

  /// مثال على كيفية استخدام UpdateBulk API
  Future<void> _updateBulkGrades() async {
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      // إنشاء البيانات المطلوبة
      final request = BulkDailyGradesRequest(
        levelId: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        classId: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        subjectId: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        date: DateTime.now(),
        studentsDailyGrades: [
          StudentDailyGrades(
            studentId: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
            date: DateTime.now(),
            dailyGrades: [
              DailyGrade(
                dailyGradeTitleId: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                grade: 85.5,
                note: "درجة ممتازة",
              ),
            ],
          ),
        ],
      );

      // استدعاء الـ API
      final repository = sl<DailyGradesRepository>();
      final response = await repository.updateBulkDailyGrades(request);

      // معالجة النتيجة
      if (response.success) {
        setState(() {
          _resultMessage = '✅ تم حفظ الدرجات بنجاح: ${response.message}';
        });

        // يمكنك هنا إضافة أي تحديثات إضافية مثل إعادة تحميل البيانات
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _resultMessage = '❌ فشل في حفظ الدرجات: ${response.message}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _resultMessage = '❌ خطأ غير متوقع: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ غير متوقع: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال استخدام UpdateBulk API'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _updateBulkGrades,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('تحديث الدرجات'),
            ),
            const SizedBox(height: 20),
            if (_resultMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _resultMessage.contains('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _resultMessage.contains('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _resultMessage,
                  style: TextStyle(
                    color: _resultMessage.contains('✅')
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
