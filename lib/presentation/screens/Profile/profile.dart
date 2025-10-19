import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../providers/user_provider.dart';
import '../../../data/services/auth_service.dart';
import '../auth/sign_in.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/repositories/daily_grade_titles_repository.dart';
import '../../../di/injector.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/teacher_class_settings/teacher_class_settings_barrel.dart';
import '../../../data/repositories/teacher_class_settings_repository.dart';
import '../../../data/models/teacher_class_setting_model.dart';
import '../../../data/models/daily_grade_titles_model.dart';

class ProfileScreen extends StatefulWidget {
  // Accept legacy parameter to keep backward compatibility; it's unused now
  final Object? profile;
  const ProfileScreen({Key? key, this.profile}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileResult? _profileResult;
  bool _loading = true;
  String? _error;
  late final TeacherClassSettingsBloc _settingsBloc;
  // Expanded palette to minimize repetition
  final List<Color> _palette = const [
    Color(0xFF1976D2), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFFC107), // Amber
    Color(0xFFE53935), // Red
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFFB8C00), // Orange
    Color(0xFF7CB342), // Light Green
    Color(0xFF3949AB), // Indigo
    Color(0xFFF06292), // Pink
    Color(0xFF00897B), // Teal
    Color(0xFFA1887F), // Brown
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF039BE5), // Light Blue
    Color(0xFF6D4C41), // Brown Dark
    Color(0xFFAFB42B), // Lime
  ];

  /// التحقق من وجود بيانات عناوين الدرجات للفصل
  Future<bool> _hasGradeTitlesData(TeacherClass teacherClass) async {
    try {
      if (teacherClass.levelId == null ||
          teacherClass.classId == null ||
          teacherClass.levelSubjectId == null) {
        return false;
      }

      final repository = sl<DailyGradeTitlesRepository>();
      final response = await repository.getDailyGradeTitles(
        levelSubjectId: teacherClass.levelSubjectId!,
        levelId: teacherClass.levelId!,
        classId: teacherClass.classId!,
      );

      return response.success && response.titles.isNotEmpty;
    } catch (e) {
      print('خطأ في التحقق من بيانات عناوين الدرجات: $e');
      return false;
    }
  }

  /// بناء عنصر الفصل مع علامة مميزة إذا لم يكن له بيانات
  Widget _buildClassItem(TeacherClass cls, int idx, int total, Color color, bool showIndicator) {
    final display = '${cls.levelName ?? ''} ${cls.className ?? ''} ${cls.subjectName ?? ''}'.trim();
    final icon = idx == 0 ? Icons.looks_one : idx == 1 ? Icons.looks_two : Icons.looks_3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showIndicator) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.warning, size: 8, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  final List<String> _gradeComponents = [
    'كويز 1',
    'كويز 2',
    'كويز 3',
    'تحريري 1',
    'تحريري 2',
    'تحريري 3',
    'واجب بيتي',
    'السلوك',
    'المشاركات',
    'النشاطات',
    'التقارير',
    'دفتر',
    'اصغاء',
    'قراءة',
    'محادثة',
    'مجموعات',
    'درجات اضافية'
  ];

  Future<void> _showGradeDistributionSheet(BuildContext context, String className, Color color, TeacherClass teacherClass) async {
    final List<DailyGradeTitle> existingTitles = [];
    final List<Map<String, dynamic>> newComponents = [];
    final TextEditingController newTitleController = TextEditingController();
    final TextEditingController newGradeController = TextEditingController();
    String? selectedComponent;
    bool _isInitialized = false;
    bool _isLoading = true;
    bool _isSaving = false;
    bool _hasExistingData = false;
    String? _errorMessage;

    // جلب العناوين الموجودة أولاً
    Future<void> _loadExistingTitles() async {
      try {
        if (teacherClass.levelId == null ||
            teacherClass.classId == null ||
            teacherClass.levelSubjectId == null) {
          throw Exception('بيانات الفصل غير مكتملة');
        }

        final repository = sl<DailyGradeTitlesRepository>();
        final response = await repository.getDailyGradeTitles(
          levelSubjectId: teacherClass.levelSubjectId!,
          levelId: teacherClass.levelId!,
          classId: teacherClass.classId!,
        );

        if (response.success && response.titles.isNotEmpty) {
          existingTitles.addAll(response.titles);
          _hasExistingData = true;
          print('✅ تم جلب ${response.titles.length} عنوان موجود');
        } else {
          _hasExistingData = false;
          print('ℹ️ لا توجد عناوين موجودة أو فشل في الجلب: ${response.message}');
        }
      } catch (e) {
        print('❌ خطأ في جلب العناوين الموجودة: $e');
        _errorMessage = 'خطأ في جلب البيانات الموجودة';
      } finally {
        _isLoading = false;
      }
    }

    Future<void> _saveChanges() async {
      if (!mounted) return;

      // التحقق من وجود تغييرات
      bool hasChanges = false;

      // التحقق من التعديلات على العناوين الموجودة
      for (int i = 0; i < existingTitles.length; i++) {
        final title = existingTitles[i];
        if (title.id != null) {
          // هنا يمكن إضافة منطق للتحقق من التغييرات في العنوان أو الدرجة
          hasChanges = true; // مؤقتاً نفترض وجود تغييرات
          break;
        }
      }

      // التحقق من العناوين الجديدة
      if (newComponents.isNotEmpty) {
        hasChanges = true;
      }

      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد تغييرات لحفظها'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        final repository = sl<DailyGradeTitlesRepository>();
        int successCount = 0;
        int totalOperations = existingTitles.length + newComponents.length;

        // تحديث العناوين الموجودة المُعدّلة
        for (int i = 0; i < existingTitles.length; i++) {
          final title = existingTitles[i];
          if (title.id != null) {
            final success = await repository.updateDailyGradeTitle(
              titleId: title.id!,
              title: title.title ?? '',
              maxGrade: title.maxGrade ?? 0,
              description: title.description,
              order: title.order ?? (i + 1),
            );

            if (success) {
              successCount++;
            }
          }
        }

        // إضافة العناوين الجديدة
        for (int i = 0; i < newComponents.length; i++) {
          final component = newComponents[i];
          final success = await repository.createDailyGradeTitle(
            title: component['name'],
            maxGrade: component['grade'],
            levelId: teacherClass.levelId!,
            classId: teacherClass.classId!,
            levelSubjectId: teacherClass.levelSubjectId!,
            order: existingTitles.length + i + 1,
          );

          if (success) {
            successCount++;
          }
        }

        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });

        if (successCount == totalOperations) {
          if (!mounted) return;
          // إعادة جلب البيانات بدلاً من إغلاق الشيت مباشرة
          await _loadExistingTitles();
          setState(() {
            _isSaving = false;
            newComponents.clear();
            selectedComponent = null;
            newGradeController.clear();
          });

          // عرض رسالة نجاح مؤقتة
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ $successCount عنصر بنجاح ✅'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
          
          // إغلاق النافذة بعد الحفظ الناجح
          Navigator.pop(context);
        } else {
          if (!mounted) return;
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ $successCount من $totalOperations عنصر'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    Future<void> _deleteTitle(int index) async {
      final title = existingTitles[index];

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف "${title.displayTitle}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('حذف'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true && title.id != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          final repository = sl<DailyGradeTitlesRepository>();
          final success = await repository.deleteDailyGradeTitle(title.id!);

          if (success) {
            // إعادة جلب البيانات بدلاً من الحذف المحلي فقط
            await _loadExistingTitles();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حذف "${title.displayTitle}" بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل في حذف العنوان'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    void _addNewComponent() {
      if (selectedComponent != null && newGradeController.text.isNotEmpty) {
        final int grade = int.tryParse(newGradeController.text) ?? 0;
        if (grade <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الدرجة يجب أن تكون أكبر من صفر'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          newComponents.add({
            'name': selectedComponent!,
            'grade': grade,
          });
          newGradeController.clear();
          selectedComponent = null;
        });
      }
    }

    // جلب البيانات أولاً قبل فتح الشيت لضمان ظهورها فورًا
    await _loadExistingTitles();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header indicator
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header
                        Row(
                          children: [
                            Icon(Icons.assignment, color: color, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'توزيع درجات $className',
                              style: TextStyle(
                                color: color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Loading state
                        if (_isLoading) ...[
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                          const SizedBox(height: 16),
                        ]

                        // Error message
                        else if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]

                        // Existing titles list
                        else if (existingTitles.isNotEmpty) ...[
                          const Text(
                            'العناوين الموجودة (تعديل وحذف فقط):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...existingTitles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final title = entry.value;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: title.title ?? '',
                                            decoration: const InputDecoration(
                                              labelText: 'العنوان',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              title.title = value;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: TextFormField(
                                            initialValue: title.maxGrade?.toString() ?? '',
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'الدرجة',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              title.maxGrade = double.tryParse(value) ?? 0;
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteTitle(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                        ]

                        // No data message
                        else ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey, size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  'لا توجد عناوين درجات محددة لهذا الفصل حالياً',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'يمكنك إضافة عناوين جديدة باستخدام قسم "إضافة عنوان جديد" أدناه',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // الانتقال مباشرة إلى قسم الإضافة
                                    setState(() {
                                      _hasExistingData = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text(
                                    'إضافة عناوين جديدة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Add new component section - only show if no existing data
                        if (!_hasExistingData) ...[
                          const Text(
                            'إضافة عنوان جديد:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedComponent,
                                  decoration: const InputDecoration(
                                    labelText: 'اختر المكون',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _gradeComponents
                                      .where((component) => !newComponents.any((c) => c['name'] == component))
                                      .map((component) => DropdownMenuItem(
                                            value: component,
                                            child: Text(component),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedComponent = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  controller: newGradeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'الدرجة',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: _addNewComponent,
                              ),
                            ],
                          ),

                          // New components list
                          if (newComponents.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'العناوين الجديدة المضافة:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...newComponents.map((component) => ListTile(
                              title: Text(component['name']),
                              trailing: Text('${component['grade']}%'),
                              leading: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    newComponents.remove(component);
                                  });
                                },
                              ),
                            )).toList(),
                          ],
                        ],

                        // Buttons section
                        if (_hasExistingData && newComponents.isEmpty) ...[
                          // عندما توجد بيانات موجودة فقط - زرين: حفظ وإغلاق
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: color),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(Icons.close, color: color),
                                  label: Text(
                                    'إغلاق',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving || _isLoading ? null : _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save, color: Colors.white),
                                  label: const Text(
                                    'حفظ التغييرات',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Save button for new components
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving || _isLoading ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'حفظ التغييرات',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildGradeItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
    
    // Initialize TeacherClassSettings BLoC
    _settingsBloc = TeacherClassSettingsBloc(sl<TeacherClassSettingsRepository>());
    
    // Fetch profile data on open using stored token
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final token = context.read<UserProvider>().token;
        if (token == null || token.isEmpty) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = 'لم يتم العثور على رمز الدخول';
          });
          return;
        }
        final result = await ProfileService().getProfile(token);
        if (!mounted) return;
        setState(() {
          _profileResult = result;
          _loading = false;
        });
        
        // جلب صلاحيات الطلاب بعد جلب البروفايل
        _settingsBloc.add(const LoadTeacherClassSettingsEvent());
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _settingsBloc.close();
    super.dispose();
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF1976D2) : null,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isTotal ? const Color(0xFF1976D2) : null,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionRow(String permission, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? const Color(0xFF43A047) : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            permission,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _MeshBackgroundPainter(),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(gridColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_loading) const Center(child: CircularProgressIndicator()),
                  if (_error != null && !_loading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  // صورة رمزية أكبر مع ظل وحد ملون
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Color(0xFF1976D2), width: 5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 62,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        (_profileResult?.profile.fullName.isNotEmpty == true)
                            ? _profileResult!.profile.fullName.characters.first
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 54,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // بيانات المعلم في كارت أفقي عصري متجاوب
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 350;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Color(0xFF1976D2), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF1976D2), size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_profileResult?.profile.fullName ?? ''}',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : (Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF233A5A)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Username Row
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, color: Color(0xFF1976D2), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            ' ${_profileResult?.profile.userName ?? ''}',
                                            style: TextStyle(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : const Color(0xFF233A5A),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Phone Row
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, color: Color(0xFF1976D2), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            _profileResult?.profile.phone ?? '',
                                            style: TextStyle(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : const Color(0xFF233A5A),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.badge, color: Color(0xFF43A047), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        (_profileResult?.profile.userType == 'Teacher') ? 'أستاذ' : (_profileResult?.profile.userType ?? ''),
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Color(0xFF1976D2),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.school, color: Color(0xFF43A047), size: 18),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Consumer<UserProvider>(
                                          builder: (context, userProvider, _) {
                                            final orgName = userProvider.organization?.name ?? 'مدرسة الانامل الواعدة';
                                            return Text(
                                              orgName,
                                              style: TextStyle(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Color(0xFF1976D2),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Removed phone number from the right side
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // كارت الفصول بشكل عصري
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Color(0xFF1976D2), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الفصول التي تدرّسها:',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        ...?_profileResult?.classes.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final cls = entry.value;
                          final total = _profileResult?.classes.length ?? 0;
                          final color = total <= 0 ? _palette[0] : _palette[idx % _palette.length];
                          return _buildClassItem(cls, idx, total, color, false); // No indicator for main classes list
                        }).toList(),
                      ],
                    ),
                  ),
                  // Daily Grades Distribution Section
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF1976D2), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'توزيع درجات الطلاب اليومية',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 10),
                        ...?_profileResult?.classes.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final cls = entry.value;
                          final total = _profileResult?.classes.length ?? 0;
                          final color = total <= 0 ? _palette[0] : _palette[idx % _palette.length];
                          final name = '${cls.subjectName ?? ''} ${cls.levelName ?? ''} ${cls.className ?? ''}'.trim();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      _showGradeDistributionSheet(context, name, color, cls);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.assignment, color: color, size: 26),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'توزيع $name',
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: 'Tajawal',
                                                    ),
                                                    textDirection: TextDirection.rtl,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                FutureBuilder<bool>(
                                                  future: _hasGradeTitlesData(cls),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                      return const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      );
                                                    }

                                                    final hasData = snapshot.data ?? false;
                                                    return Tooltip(
                                                      message: hasData ? 'يحتوي على بيانات' : 'لا يحتوي على بيانات',
                                                      child: Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: hasData ? Colors.green : Colors.orange,
                                                          border: Border.all(
                                                            color: Colors.white,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: hasData
                                                            ? const Icon(Icons.check, size: 8, color: Colors.white)
                                                            : const Icon(Icons.warning, size: 8, color: Colors.white),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 22),
                                  color: color,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: AlertDialog(
                                            title: Text('توزيع $name'),
                                            content: Text(
                                              'هنا يمكنك إدارة درجات طلاب $name. اضغط على اسم الصف لفتح نافذة إدارة التوزيع.',
                                              textDirection: TextDirection.rtl,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('حسناً'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  // Student Permissions Section
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF1976D2), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: Color(0xFF1976D2), size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'صلاحيات الطلاب',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Tajawal',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'يمكنك التحكم في الصلاحيات التي تتيح للطلاب التواصل معك لكل صف',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontFamily: 'Tajawal',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        BlocConsumer<TeacherClassSettingsBloc, TeacherClassSettingsState>(
                          bloc: _settingsBloc,
                          listener: (context, state) {
                            if (state is TeacherClassSettingsUpdateSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else if (state is TeacherClassSettingsError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            // حالة التحميل
                            if (state is TeacherClassSettingsLoading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            // حالة الخطأ أو فارغة - نستخدم البيانات المحلية
                            if (state is TeacherClassSettingsError || 
                                state is TeacherClassSettingsEmpty ||
                                state is TeacherClassSettingsInitial) {
                              // Fallback: عرض الفصول من البروفايل بدون صلاحيات
                              return Column(
                                children: _profileResult?.classes.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final cls = entry.value;
                                  final total = _profileResult?.classes.length ?? 0;
                                  final color = total <= 0 ? _palette[0] : _palette[idx % _palette.length];
                                  final name = '${cls.levelName ?? ''} ${cls.className ?? ''}'.trim();
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Tajawal',
                                            ),
                                            textDirection: TextDirection.rtl,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'غير متاح',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                                fontFamily: 'Tajawal',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: false,
                                              onChanged: null, // معطل
                                              activeColor: color,
                                              activeTrackColor: color.withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList() ?? [],
                              );
                            }
                            
                            // حالة النجاح - عرض الصلاحيات من السيرفر
                            if (state is TeacherClassSettingsLoaded || 
                                state is TeacherClassSettingsUpdating) {
                              final settings = state is TeacherClassSettingsLoaded
                                  ? state.settings
                                  : (state as TeacherClassSettingsUpdating).currentSettings;
                              
                              // دمج البيانات من البروفايل والإعدادات
                              return Column(
                                children: _profileResult?.classes.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final cls = entry.value;
                                  final total = _profileResult?.classes.length ?? 0;
                                  final color = total <= 0 ? _palette[0] : _palette[idx % _palette.length];
                                  final name = '${cls.levelName ?? ''} ${cls.className ?? ''}'.trim();
                                  
                                  // البحث عن الإعداد المقابل
                                  final setting = settings.firstWhere(
                                    (s) => s.levelId == cls.levelId && s.classId == cls.classId,
                                    orElse: () => TeacherClassSetting(
                                      classId: cls.classId ?? '',
                                      levelId: cls.levelId ?? '',
                                      studentChatPermission: false,
                                    ),
                                  );
                                  
                                  final isUpdating = state is TeacherClassSettingsUpdating;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Tajawal',
                                            ),
                                            textDirection: TextDirection.rtl,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (isUpdating)
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            else
                                              Text(
                                                setting.studentChatPermission ? 'مفعل' : 'معطل',
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 14,
                                                  fontFamily: 'Tajawal',
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: setting.studentChatPermission,
                                              onChanged: isUpdating ? null : (value) {
                                                _settingsBloc.add(
                                                  ToggleStudentChatPermissionEvent(
                                                    classId: setting.classId,
                                                    levelId: setting.levelId,
                                                    newValue: value,
                                                  ),
                                                );
                                              },
                                              activeColor: color,
                                              activeTrackColor: color.withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList() ?? [],
                              );
                            }
                            
                            // حالة افتراضية
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Change Password Button
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.lock_reset, color: Colors.white),
                    label: const Text(
                      'تغيير كلمة المرور',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    onPressed: () {
                      final currentPasswordController = TextEditingController();
                      final newPasswordController = TextEditingController();
                      final confirmPasswordController = TextEditingController();
                      final formKey = GlobalKey<FormState>();

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                                left: 24,
                                right: 24,
                                top: 24,
                              ),
                              child: Form(
                                key: formKey,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 50,
                                          height: 5,
                                          margin: const EdgeInsets.only(bottom: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'تغيير كلمة المرور',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                          fontFamily: 'Tajawal',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 25),
                                      TextFormField(
                                        controller: currentPasswordController,
                                        obscureText: true,
                                        style: const TextStyle(fontFamily: 'Tajawal'),
                                        decoration: InputDecoration(
                                          labelText: 'كلمة المرور الحالية',
                                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!), 
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                          ),
                                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال كلمة المرور الحالية';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: newPasswordController,
                                        obscureText: true,
                                        style: const TextStyle(fontFamily: 'Tajawal'),
                                        decoration: InputDecoration(
                                          labelText: 'كلمة المرور الجديدة',
                                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!), 
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                          ),
                                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال كلمة المرور الجديدة';
                                          }
                                          if (value.length < 6) {
                                            return 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: confirmPasswordController,
                                        obscureText: true,
                                        style: const TextStyle(fontFamily: 'Tajawal'),
                                        decoration: InputDecoration(
                                          labelText: 'تأكيد كلمة المرور الجديدة',
                                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!), 
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                          ),
                                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء تأكيد كلمة المرور الجديدة';
                                          }
                                          if (value != newPasswordController.text) {
                                            return 'كلمة المرور غير متطابقة';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 30),
                                      SizedBox(
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (formKey.currentState!.validate()) {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    title: const Text(
                                                      'تأكيد التغيير',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: 'Tajawal',
                                                      ),
                                                    ),
                                                    content: const Text(
                                                      'هل أنت متأكد من تغيير كلمة المرور؟',
                                                      style: TextStyle(
                                                        fontFamily: 'Tajawal',
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                        child: const Text(
                                                          'إلغاء',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontFamily: 'Tajawal',
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF1976D2),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          Navigator.of(ctx).pop(true);
                                                          // Show loading dialog
                                                          showDialog(
                                                            context: context,
                                                            barrierDismissible: false,
                                                            builder: (_) => const Center(child: CircularProgressIndicator()),
                                                          );
                                                          try {
                                                            await AuthService().changePassword(
                                                              currentPassword: currentPasswordController.text.trim(),
                                                              newPassword: newPasswordController.text.trim(),
                                                            );
                                                            if (mounted) {
                                                              Navigator.of(context).pop(); // close loading
                                                              Navigator.of(context).pop(); // close bottom sheet
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: const Text(
                                                                    'تم تغيير كلمة المرور بنجاح',
                                                                    style: TextStyle(fontFamily: 'Tajawal'),
                                                                  ),
                                                                  backgroundColor: const Color(0xFF1976D2),
                                                                  behavior: SnackBarBehavior.floating,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                  ),
                                                                  margin: const EdgeInsets.all(16),
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            if (mounted) {
                                                              Navigator.of(context).pop(); // close loading
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    e.toString().replaceAll('Exception: ', ''),
                                                                    style: const TextStyle(fontFamily: 'Tajawal'),
                                                                  ),
                                                                  backgroundColor: Colors.red,
                                                                  behavior: SnackBarBehavior.floating,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                  ),
                                                                  margin: const EdgeInsets.all(16),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        },
                                                        child: const Text(
                                                          'تأكيد',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily: 'Tajawal',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1976D2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'حفظ التغييرات',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: 'Tajawal',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Logout Button
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('تأكيد تسجيل الخروج'),
                          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('لا'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop(true); // يقفل النافذة

                                // عرض مؤشر تقدم
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                );

                                try {
                                  // محاولة تسجيل الخروج من السيرفر
                                  await AuthService().serverLogout(requireUserAction: true);
                                } catch (_) {
                                  // تجاهل أخطاء السيرفر والمتابعة
                                }

                                // مسح البيانات من Provider
                                await context.read<UserProvider>().logout();
                                
                                // إرسال حدث تسجيل الخروج إلى AuthBloc
                                if (!mounted) return;
                                context.read<AuthBloc>().add(const LogoutRequested());

                                if (mounted) {
                                  Navigator.of(context).pop(); // يقفل الـ progress dialog
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              child: const Text('نعم'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _MeshBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFB0BEC5).withAlpha(33)
      ..strokeWidth = 1;
    final paintDot = Paint()
      ..color = const Color(0xFF3B5998).withAlpha(25)
      ..style = PaintingStyle.fill;
    for (double y = 40; y < size.height; y += 120) {
      for (double x = 0; x < size.width; x += 180) {
        canvas.drawLine(Offset(x, y), Offset(x + 120, y + 40), paintLine);
        canvas.drawLine(Offset(x + 60, y + 80), Offset(x + 180, y), paintLine);
      }
    }
    for (double y = 30; y < size.height; y += 100) {
      for (double x = 20; x < size.width; x += 140) {
        canvas.drawCircle(Offset(x, y), 3, paintDot);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  final Color gridColor;
  
  _GridPainter({this.gridColor = Colors.white});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withAlpha(16)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
