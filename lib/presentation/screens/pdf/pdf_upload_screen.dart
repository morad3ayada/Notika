import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/file_classification/file_classification_bloc.dart';
import '../../../logic/blocs/file_classification/file_classification_event.dart';
import '../../../logic/blocs/file_classification/file_classification_state.dart';
import '../../../logic/blocs/pdf_upload/pdf_upload_barrel.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/models/file_classification_model.dart';
import '../../../data/models/chapter_unit_model.dart';
import '../../../data/models/pdf_upload_model.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/file_classification_repository.dart';
import '../../../data/repositories/chapter_unit_repository.dart';
import '../../../data/repositories/pdf_upload_repository.dart';
import '../../../data/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/teacher_class_matcher.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  State<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final String unitName;
  final Function(bool) onConfirm;

  const _DeleteConfirmationDialog({
    super.key,
    required this.unitName,
    required this.onConfirm,
  });

  @override
  _DeleteConfirmationDialogState createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isConfirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تأكيد حذف الوحدة/الفصل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF233A5A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لحذف "${widget.unitName}" يرجى كتابة الاسم للتأكيد',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _isConfirmed = value == widget.unitName;
                });
              },
              decoration: InputDecoration(
                hintText: 'اكتب "${widget.unitName}"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1976D2)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Color(0xFF233A5A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConfirmed
                        ? () {
                            widget.onConfirm(true);
                            Navigator.pop(context, true);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'تأكيد الحذف',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {
  File? selectedFile;
  File? selectedAudio;
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  String? selectedUnit; // الفصل/الوحدة المختارة
  final List<String> units = []; // قائمة الفصول/الوحدات التي ينشئها المستخدم
  late final ProfileBloc _profileBloc;
  late final FileClassificationBloc _fileClassificationBloc;
  late final PdfUploadBloc _pdfUploadBloc; // إضافة PdfUploadBloc عشان نتعامل مع رفع الملفات
  
  // متغيرات جديدة للوحدات/الفصول من السيرفر
  List<ChapterUnit> serverUnits = [];
  bool isLoadingUnits = false;
  String? unitsErrorMessage;

  // Helpers to derive dynamic lists from TeacherClass
  List<String> _buildSchools(List<TeacherClass> classes) {
    final set = <String>{};
    for (final c in classes) {
      if ((c.schoolName ?? '').trim().isNotEmpty) set.add(c.schoolName!.trim());
    }
    return set.toList();
  }

  List<String> _buildStages(List<TeacherClass> classes, String? school) {
    if (school == null) return const [];
    final set = <String>{};
    for (final c in classes.where((e) => e.schoolName == school)) {
      if ((c.levelName ?? '').trim().isNotEmpty) set.add(c.levelName!.trim());
    }
    return set.toList();
  }

  List<String> _buildSections(
      List<TeacherClass> classes, String? school, String? stage) {
    if (school == null || stage == null) return const [];
    final set = <String>{};
    for (final c in classes
        .where((e) => e.schoolName == school && e.levelName == stage)) {
      if ((c.className ?? '').trim().isNotEmpty) set.add(c.className!.trim());
    }
    return set.toList();
  }

  List<String> _buildSubjects(List<TeacherClass> classes, String? school,
      String? stage, String? section) {
    if (school == null || stage == null || section == null) return const [];
    final set = <String>{};
    for (final c in classes.where((e) =>
        e.schoolName == school &&
        e.levelName == stage &&
        e.className == section)) {
      if ((c.subjectName ?? '').trim().isNotEmpty)
        set.add(c.subjectName!.trim());
    }
    return set.toList();
  }

  final TextEditingController detailsController = TextEditingController();

  // File Classification Controllers
  final TextEditingController _fileClassificationNameController =
      TextEditingController();

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;

  // دالة لجلب الوحدات/الفصول من السيرفر
  Future<void> fetchChapterUnits() async {
    if (selectedSubject == null || selectedStage == null || selectedSection == null) {
      return;
    }
    
    setState(() {
      isLoadingUnits = true;
      unitsErrorMessage = null;
    });
    
    try {
      // الحصول على معرف المستخدم والتوكن
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.token;
      
      // الحصول على معرفات المرحلة والشعبة والمادة
      final classes = await _getTeacherClasses();
      final matchedClass = TeacherClassMatcher.findMatchingTeacherClass(
        classes,
        selectedSchool,
        selectedStage,
        selectedSection,
        selectedSubject,
      );
      
      if (matchedClass == null || token == null) {
        setState(() {
          isLoadingUnits = false;
          unitsErrorMessage = 'لم يتم العثور على بيانات الفصل أو المستخدم';
        });
        return;
      }

      print('✅ Found TeacherClass:');
      print('   School: ${matchedClass.schoolName ?? ''}');
      print('   Level: ${matchedClass.levelName ?? ''}');
      print('   Section: ${matchedClass.className ?? ''}');
      print('   Subject: ${matchedClass.subjectName ?? ''}');

      // تحقق من وجود قيم صالحة
      if (matchedClass.levelSubjectId == null || matchedClass.levelSubjectId!.isEmpty ||
          matchedClass.levelId == null || matchedClass.levelId!.isEmpty ||
          matchedClass.classId == null || matchedClass.classId!.isEmpty) {
        setState(() {
          isLoadingUnits = false;
          unitsErrorMessage = 'بيانات الفصل غير مكتملة';
        });
        return;
      }

      // استدعاء الخدمة لجلب الوحدات/الفصول
      final repository = sl<ChapterUnitRepository>();
      final response = await repository.getChapterUnits(
        levelSubjectId: matchedClass.levelSubjectId!,
        levelId: matchedClass.levelId!,
        classId: matchedClass.classId!,
      );
      
      setState(() {
        serverUnits = response.data;
        isLoadingUnits = false;
        if (!response.success) {
          unitsErrorMessage = response.message;
        }
      });
    } catch (e) {
      setState(() {
        isLoadingUnits = false;
        unitsErrorMessage = 'حدث خطأ أثناء جلب البيانات: $e';
      });
    }
  }
  
  // دالة مساعدة للحصول على فصول المعلم
  Future<List<TeacherClass>> _getTeacherClasses() async {
    final state = _profileBloc.state;
    if (state is ProfileLoaded) {
      return state.classes;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())
      ..add(const FetchProfile());
    _fileClassificationBloc =
        FileClassificationBloc(sl<FileClassificationRepository>());
    // إنشاء PdfUploadBloc مع الـ Repository من dependency injection
    _pdfUploadBloc = PdfUploadBloc(sl<PdfUploadRepository>());
  }

  @override
  void dispose() {
    _profileBloc.close();
    _fileClassificationBloc.close();
    _pdfUploadBloc.close(); // إغلاق PdfUploadBloc عشان منسربش الذاكرة
    _recorder?.closeRecorder();
    _fileClassificationNameController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  /// دالة اختيار الملف مع معالجة شاملة للأخطاء والصلاحيات
  Future<void> pickFile() async {
    try {
      print('🔍 بدء عملية اختيار الملف...');
      
      // طلب الصلاحيات أولاً (مهم لأندرويد 11+)
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showPermissionDeniedMessage();
        return;
      }

      print('✅ الصلاحيات متاحة، فتح منتقي الملفات...');
      
      // فتح منتقي الملفات مع معالجة آمنة
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
        allowMultiple: false, // ملف واحد فقط
        withData: false, // عدم تحميل البيانات في الذاكرة لتوفير الأداء
        withReadStream: false, // عدم استخدام stream للقراءة
      );

      // التحقق من أن المستخدم اختار ملف فعلاً
      if (result == null) {
        print('ℹ️ المستخدم ألغى اختيار الملف');
        return;
      }

      // التحقق من وجود ملفات في النتيجة
      if (result.files.isEmpty) {
        print('⚠️ لا توجد ملفات في النتيجة');
        _showErrorMessage('لم يتم اختيار أي ملف');
        return;
      }

      final PlatformFile platformFile = result.files.first;
      
      // التحقق من وجود مسار الملف
      if (platformFile.path == null || platformFile.path!.isEmpty) {
        print('❌ مسار الملف غير متاح');
        _showErrorMessage('لا يمكن الوصول لمسار الملف المختار');
        return;
      }

      // إنشاء كائن File والتحقق من وجوده
      final File file = File(platformFile.path!);
      if (!await file.exists()) {
        print('❌ الملف غير موجود في المسار: ${platformFile.path}');
        _showErrorMessage('الملف المختار غير موجود');
        return;
      }

      // التحقق من حجم الملف (أقل من 50 ميجا)
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      if (fileSizeInMB > 50) {
        print('❌ حجم الملف كبير جداً: ${fileSizeInMB.toStringAsFixed(2)} MB');
        _showErrorMessage('حجم الملف كبير جداً (أقصى حد 50 ميجابايت)\nحجم الملف الحالي: ${fileSizeInMB.toStringAsFixed(2)} MB');
        return;
      }

      // كل شيء تمام، حفظ الملف
      setState(() {
        selectedFile = file;
      });

      print('✅ تم اختيار الملف بنجاح:');
      print('   الاسم: ${platformFile.name}');
      print('   المسار: ${platformFile.path}');
      print('   الحجم: ${fileSizeInMB.toStringAsFixed(2)} MB');
      print('   النوع: ${platformFile.extension ?? 'غير محدد'}');

      // إظهار رسالة نجاح للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم اختيار الملف: ${platformFile.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

    } catch (e, stackTrace) {
      print('❌ خطأ أثناء اختيار الملف: $e');
      print('Stack trace: $stackTrace');
      
      // معالجة أنواع مختلفة من الأخطاء
      String errorMessage = 'حدث خطأ أثناء اختيار الملف';
      
      if (e.toString().contains('permission')) {
        errorMessage = 'ليس لديك صلاحية للوصول للملفات';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'تم إلغاء اختيار الملف';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'الملف المختار غير موجود';
      }
      
      _showErrorMessage(errorMessage);
    }
  }

  /// طلب صلاحيات الوصول للتخزين (مهم لأندرويد 11+)
  Future<bool> _requestStoragePermission() async {
    try {
      // التحقق من إصدار أندرويد
      if (Platform.isAndroid) {
        // لأندرويد 11+ (API 30+) نحتاج MANAGE_EXTERNAL_STORAGE
        var status = await Permission.manageExternalStorage.status;
        
        if (status.isDenied || status.isPermanentlyDenied) {
          print('🔐 طلب صلاحية MANAGE_EXTERNAL_STORAGE...');
          status = await Permission.manageExternalStorage.request();
        }
        
        if (status.isGranted) {
          print('✅ تم منح صلاحية MANAGE_EXTERNAL_STORAGE');
          return true;
        }
        
        // إذا فشلت، جرب الصلاحيات العادية
        print('🔐 طلب صلاحية READ_EXTERNAL_STORAGE...');
        var readStatus = await Permission.storage.status;
        
        if (readStatus.isDenied || readStatus.isPermanentlyDenied) {
          readStatus = await Permission.storage.request();
        }
        
        if (readStatus.isGranted) {
          print('✅ تم منح صلاحية READ_EXTERNAL_STORAGE');
          return true;
        }
        
        print('❌ لم يتم منح أي صلاحيات للتخزين');
        return false;
      }
      
      // لـ iOS أو منصات أخرى
      return true;
      
    } catch (e) {
      print('❌ خطأ أثناء طلب الصلاحيات: $e');
      return false;
    }
  }

  /// إظهار رسالة خطأ للمستخدم
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// إظهار رسالة رفض الصلاحيات
  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('يجب السماح بالوصول للملفات لاختيار الملفات'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'الإعدادات',
          textColor: Colors.white,
          onPressed: () async {
            await openAppSettings(); // فتح إعدادات التطبيق
          },
        ),
      ),
    );
  }

  /// دالة اختيار ملف صوتي مع معالجة آمنة للأخطاء
  Future<void> pickAudio() async {
    try {
      print('🎵 بدء عملية اختيار الملف الصوتي...');
      
      // طلب الصلاحيات أولاً
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showPermissionDeniedMessage();
        return;
      }

      // فتح منتقي الملفات الصوتية
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      // التحقق من النتيجة
      if (result == null) {
        print('ℹ️ المستخدم ألغى اختيار الملف الصوتي');
        return;
      }

      if (result.files.isEmpty) {
        _showErrorMessage('لم يتم اختيار أي ملف صوتي');
        return;
      }

      final PlatformFile platformFile = result.files.first;
      
      if (platformFile.path == null || platformFile.path!.isEmpty) {
        _showErrorMessage('لا يمكن الوصول لمسار الملف الصوتي');
        return;
      }

      final File file = File(platformFile.path!);
      if (!await file.exists()) {
        _showErrorMessage('الملف الصوتي المختار غير موجود');
        return;
      }

      // التحقق من حجم الملف الصوتي (أقل من 20 ميجا)
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      if (fileSizeInMB > 20) {
        _showErrorMessage('حجم الملف الصوتي كبير جداً (أقصى حد 20 ميجابايت)\nحجم الملف الحالي: ${fileSizeInMB.toStringAsFixed(2)} MB');
        return;
      }

      // حفظ الملف الصوتي
      setState(() {
        selectedAudio = file;
      });

      print('✅ تم اختيار الملف الصوتي بنجاح: ${platformFile.name}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم اختيار الملف الصوتي: ${platformFile.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('❌ خطأ أثناء اختيار الملف الصوتي: $e');
      _showErrorMessage('حدث خطأ أثناء اختيار الملف الصوتي');
    }
  }

  Future<void> startRecording() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب السماح باستخدام الميكروفون')),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recording_${Random().nextInt(100000)}.aac';
    await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
      _audioPath = null;
    });
  }

  Future<void> stopRecording() async {
    final path = await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  void submit() {
    // التحقق من وجود جميع البيانات المطلوبة
    if (selectedFile == null ||
        selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null ||
        selectedSubject == null ||
        selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار جميع الحقول ورفع ملف واختيار الفصل/الوحدة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // الحصول على TeacherClass المطابق للاختيارات
    final profileState = _profileBloc.state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تحميل بيانات المعلم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final classes = profileState.classes;
    final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
      classes,
      selectedSchool!,
      selectedStage!,
      selectedSection!,
      selectedSubject!,
    );

    if (matchingClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على الفصل المطابق للاختيارات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // البحث عن FileClassificationId من الوحدات المحملة
    String? fileClassificationId;
    for (final unit in serverUnits) {
      if (unit.name == selectedUnit) {
        fileClassificationId = unit.id;
        break;
      }
    }

    if (fileClassificationId == null || fileClassificationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على معرف الوحدة المختارة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🎯 بدء إعداد بيانات الرفع:');
    print('   المدرسة: $selectedSchool');
    print('   المرحلة: $selectedStage');
    print('   الشعبة: $selectedSection');
    print('   المادة: $selectedSubject');
    print('   الوحدة: $selectedUnit');
    print('   الملف: ${selectedFile!.path}');

    // إنشاء نموذج البيانات للرفع (مع الملف الصوتي إذا كان موجود)
    final uploadModel = PdfUploadModel(
      levelSubjectId: matchingClass.levelSubjectId ?? 
                     matchingClass.subjectId ?? 
                     '00000000-0000-0000-0000-000000000000',
      levelId: matchingClass.levelId ?? '00000000-0000-0000-0000-000000000000',
      classId: matchingClass.classId ?? '00000000-0000-0000-0000-000000000000',
      fileClassificationId: fileClassificationId,
      title: selectedFile!.path.split(Platform.pathSeparator).last, // اسم الملف كعنوان
      fileType: PdfUploadModel.getFileTypeFromExtension(selectedFile!.path),
      path: 'uploads/chapters', // المسار الثابت كما في الـ cURL
      note: detailsController.text.trim().isNotEmpty ? detailsController.text.trim() : null,
      file: selectedFile!,
      voiceFile: selectedAudio ?? (_audioPath != null ? File(_audioPath!) : null), // إضافة الملف الصوتي
    );

    print('📋 بيانات النموذج:');
    print('   levelSubjectId: ${uploadModel.levelSubjectId}');
    print('   levelId: ${uploadModel.levelId}');
    print('   classId: ${uploadModel.classId}');
    print('   fileClassificationId: ${uploadModel.fileClassificationId}');
    print('   title: ${uploadModel.title}');
    print('   fileType: ${uploadModel.fileType}');
    
    // طباعة معلومات الملف الصوتي إذا كان موجود
    if (uploadModel.voiceFile != null) {
      print('🎵 الملف الصوتي:');
      print('   المسار: ${uploadModel.voiceFile!.path}');
      print('   الاسم: ${uploadModel.voiceFile!.path.split(Platform.pathSeparator).last}');
      print('   النوع: ${PdfUploadModel.getFileTypeFromExtension(uploadModel.voiceFile!.path)}');
    } else {
      print('ℹ️ لا يوجد ملف صوتي مرفق');
    }

    // إرسال حدث الرفع للـ BLoC
    _pdfUploadBloc.add(UploadPdfEvent(uploadModel: uploadModel));
  }

  Future<void> _openUnitSelector() async {
    final controller = TextEditingController();
    final localUnits = List<String>.from(units);
    String? localSelectedUnit = selectedUnit;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 16,
                right: 16,
                left: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الفصل / الوحدة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'أضف خيارًا جديدًا (مثال: الفصل الأول)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<FileClassificationBloc,
                          FileClassificationState>(
                        bloc: _fileClassificationBloc,
                        builder: (context, fileClassificationState) {
                          final isLoading = fileClassificationState
                              is AddFileClassificationLoading;
                          return ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    final text = controller.text.trim();
                                    if (text.isNotEmpty &&
                                        !localUnits.contains(text)) {
                                      // Set the name in the controller for BLoC submission
                                      _fileClassificationNameController.text =
                                          text;
                                      // Submit via BLoC
                                      _submitFileClassification();
                                      controller.clear();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('إضافة',
                                    style: TextStyle(color: Colors.white)),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // عرض الوحدات من السيرفر مع حالات التحميل والخطأ
                  if (isLoadingUnits)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1976D2),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (unitsErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            unitsErrorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                fetchChapterUnits();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'إعادة المحاولة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (serverUnits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('لا توجد وحدات متاحة لهذا الفصل'),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: serverUnits.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (_, i) {
                          final unit = serverUnits[i];
                          final isSelected = localSelectedUnit == unit.name;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(unit.name),
                            subtitle: unit.description != null
                                ? Text(
                                    unit.description!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: const Color(0xFF1976D2),
                            ),
                            onTap: () {
                              setModalState(() {
                                localSelectedUnit = unit.name;
                              });
                              // إغلاق الـ modal فوراً بعد اختيار الوحدة
                              Navigator.of(ctx).pop();

                              // تطبيق التغييرات فوراً
                              setState(() {
                                units.clear();
                                units.addAll(localUnits);
                                selectedUnit = localSelectedUnit;
                              });
                            },
                          );
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  units.clear();
                                  units.addAll(localUnits);
                                  if (localSelectedUnit != selectedUnit) {
                                    selectedUnit = localSelectedUnit;
                                  }
                                });
                                Navigator.of(ctx).pop();

                                // جلب الوحدات من السيرفر عند تغيير المادة
                                if (selectedSubject != null) {
                                  fetchChapterUnits();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'حفظ التغييرات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            
                          );
                  const SizedBox(height: 8);
                        },
                      ),
                    ),  
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitFileClassification() {
    // Validation
    if (_fileClassificationNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفصل/الوحدة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المدرسة والمرحلة والشعبة والمادة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get teacher classes from ProfileBloc
    final profileState = _profileBloc.state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تحميل بيانات المعلم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final classes = profileState.classes;

    // Find matching TeacherClass using TeacherClassMatcher
    final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
      classes,
      selectedSchool!,
      selectedStage!,
      selectedSection!,
      selectedSubject!,
    );

    if (matchingClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على الفصل المطابق للاختيارات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dispatch AddFileClassificationEvent to BLoC
    _fileClassificationBloc.add(AddFileClassificationEvent(
      levelSubjectId: matchingClass.levelSubjectId ??
          matchingClass.subjectId ??
          '00000000-0000-0000-0000-000000000000',
      levelId: matchingClass.levelId ?? '00000000-0000-0000-0000-000000000000',
      classId: matchingClass.classId ?? '00000000-0000-0000-0000-000000000000',
      name: _fileClassificationNameController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF233A5A), Color(0xFF1976D2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      "رفع الملفات",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(children: [
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
          painter: _GridPainter(
              gridColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
        ),
        SafeArea(
            child: BlocBuilder<ProfileBloc, ProfileState>(
                bloc: _profileBloc,
                builder: (context, state) {
                  if (state is ProfileLoading || state is ProfileInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ProfileError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  final loaded = state as ProfileLoaded;
                  final classes = loaded.classes;
                  final schoolsList = _buildSchools(classes);
                  final stagesList = _buildStages(classes, selectedSchool);
                  final sectionsList =
                      _buildSections(classes, selectedSchool, selectedStage);
                  final subjectsList = _buildSubjects(
                      classes, selectedSchool, selectedStage, selectedSection);

                  // إضافة BlocConsumer للـ PdfUploadBloc عشان نسمع لحالات الرفع
                  return BlocConsumer<PdfUploadBloc, PdfUploadState>(
                    bloc: _pdfUploadBloc,
                    listener: (context, pdfUploadState) {
                      // معالجة حالات رفع الملف
                      if (pdfUploadState is PdfUploadSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(pdfUploadState.response.message),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // تنظيف الفورم بعد النجاح
                        setState(() {
                          selectedFile = null;
                          selectedAudio = null;
                          _audioPath = null; // تنظيف مسار التسجيل الصوتي
                          selectedSchool = null;
                          selectedStage = null;
                          selectedSection = null;
                          selectedSubject = null;
                          selectedUnit = null;
                          detailsController.clear();
                        });
                        
                        // إعادة تعيين حالة الـ BLoC
                        _pdfUploadBloc.add(const ResetPdfUploadEvent());
                        
                      } else if (pdfUploadState is PdfUploadFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(pdfUploadState.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (pdfUploadState is PdfUploadValidationFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(pdfUploadState.message),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    builder: (context, pdfUploadState) {
                      return BlocConsumer<FileClassificationBloc,
                          FileClassificationState>(
                        bloc: _fileClassificationBloc,
                    listener: (context, fileClassificationState) {
                      if (fileClassificationState
                          is AddFileClassificationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(fileClassificationState.message),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Add the new unit to the local list
                        setState(() {
                          units.add(
                              fileClassificationState.fileClassification.name);
                          selectedUnit =
                              fileClassificationState.fileClassification.name;
                        });

                        // Clear the form
                        _fileClassificationNameController.clear();
                      } else if (fileClassificationState
                          is AddFileClassificationFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(fileClassificationState.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, fileClassificationState) {
                      return Directionality(
                        textDirection: TextDirection.rtl,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 32, bottom: 32),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // اختيارات المدرسة والمرحلة والشعبة والمادة في الأعلى
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: schoolsList.map((school) {
                                          final isSelected =
                                              selectedSchool == school;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                onTap: () {
                                                  setState(() {
                                                    selectedSchool = school;
                                                    selectedStage = null;
                                                    selectedSection = null;
                                                    selectedSubject = null;
                                                  });
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                  decoration: BoxDecoration(
                                                    gradient: isSelected
                                                        ? const LinearGradient(
                                                            colors: [
                                                              Color(0xFF1976D2),
                                                              Color(0xFF64B5F6)
                                                            ],
                                                            begin: Alignment
                                                                .centerLeft,
                                                            end: Alignment
                                                                .centerRight,
                                                          )
                                                        : null,
                                                    color: isSelected
                                                        ? null
                                                        : Theme.of(context)
                                                            .cardColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    school,
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.color ??
                                                              const Color(
                                                                  0xFF233A5A),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  if (selectedSchool != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: stagesList.map((stage) {
                                            final isSelected =
                                                selectedStage == stage;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                  onTap: () {
                                                    setState(() {
                                                      selectedStage = stage;
                                                      selectedSection = null;
                                                      selectedSubject = null;
                                                    });
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xFF1976D2),
                                                                Color(
                                                                    0xFF64B5F6)
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
                                                            )
                                                          : null,
                                                      color: isSelected
                                                          ? null
                                                          : Theme.of(context)
                                                              .cardColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              25),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      stage,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Theme.of(context)
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.color ??
                                                                const Color(
                                                                    0xFF233A5A),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  if (selectedStage != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: sectionsList.map((section) {
                                            final isSelected =
                                                selectedSection == section;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                  onTap: () {
                                                    setState(() {
                                                      selectedSection = section;
                                                      selectedSubject = null;
                                                    });
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xFF1976D2),
                                                                Color(
                                                                    0xFF64B5F6)
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
                                                            )
                                                          : null,
                                                      color: isSelected
                                                          ? null
                                                          : Theme.of(context)
                                                              .cardColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              25),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      section,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Theme.of(context)
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.color ??
                                                                const Color(
                                                                    0xFF233A5A),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  if (selectedSection != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: subjectsList.map((subject) {
                                            final isSelected =
                                                selectedSubject == subject;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                  onTap: () {
                                                    setState(() {
                                                      selectedSubject = subject;
                                                    });

                                                    // جلب الوحدات من السيرفر عند اختيار مادة جديدة
                                                    SchedulerBinding.instance.addPostFrameCallback((_) {
                                                      fetchChapterUnits();
                                                    });
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xFF1976D2),
                                                                Color(
                                                                    0xFF64B5F6)
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
                                                            )
                                                          : null,
                                                      color: isSelected
                                                          ? null
                                                          : Theme.of(context)
                                                              .cardColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              25),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      subject,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Theme.of(context)
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.color ??
                                                                const Color(
                                                                    0xFF233A5A),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),

                                  if (selectedSubject != null) ...[
                                    const SizedBox(height: 20),
                                    // اختيار ملف (صورة/فيديو/PDF)
                                    GestureDetector(
                                      onTap: pickFile,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 22, horizontal: 18),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(
                                              color: Color(0xFF1976D2),
                                              width: 1.2),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.attach_file,
                                                color: Color(0xFF1976D2),
                                                size: 32),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                selectedFile != null
                                                    ? selectedFile!.path
                                                        .split(Platform
                                                            .pathSeparator)
                                                        .last
                                                    : 'اختر ملف (PDF/صورة/فيديو)...',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.color ??
                                                      const Color(0xFF233A5A),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // حقل الفصل/الوحدة (بتصميم مشابه لزر رفع الملف)
                                    GestureDetector(
                                      onTap: _openUnitSelector,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: Border.all(
                                              color: const Color(0xFF1976D2),
                                              width: 1.2),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.book_outlined,
                                                color: Color(0xFF1976D2),
                                                size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'الفصل / الوحدة',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    selectedUnit ??
                                                        'اضغط لإضافة أو اختيار فصل/وحدة',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.color ??
                                                          const Color(
                                                              0xFF233A5A),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Color(0xFF1976D2)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // حقل التفاصيل أو الرابط (بتصميم مشابه لزر رفع الملف)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: const Color(0xFF1976D2),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 16, top: 12, left: 16),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.link,
                                                    color: Color(0xFF1976D2),
                                                    size: 24),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'تفاصيل أو رابط',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.color ??
                                                        const Color(0xFF233A5A),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16)
                                                .copyWith(top: 8),
                                            child: TextFormField(
                                              controller: detailsController,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'أدخل وصفًا أو رابطًا إضافيًا...',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 12),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[900]
                                                    : Colors.grey[100],
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFF1976D2),
                                                      width: 1.5),
                                                ),
                                              ),
                                              minLines: 3,
                                              maxLines: 5,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              style:
                                                  const TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // تسجيل صوتي داخل التطبيق
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isRecording
                                                ? Colors.red
                                                : const Color(0xFF1976D2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 28, vertical: 12),
                                          ),
                                          icon: Icon(
                                              _isRecording
                                                  ? Icons.stop
                                                  : Icons.mic,
                                              color: Colors.white),
                                          label: Text(
                                              _isRecording
                                                  ? 'إيقاف التسجيل'
                                                  : 'تسجيل صوتي',
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          onPressed: _isRecording
                                              ? stopRecording
                                              : startRecording,
                                        ),
                                        if (_audioPath != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'تم تسجيل الصوت: ${_audioPath!.split(Platform.pathSeparator).last}',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.color ??
                                                        const Color(0xFF233A5A),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '🎵 سيتم رفع الملف الصوتي مع الملف الأساسي',
                                                  style: TextStyle(
                                                    color: const Color(0xFF1976D2),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // زر الإرسال مع حالات التحميل من PdfUploadBloc
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: pdfUploadState is PdfUploadLoading 
                                          ? Colors.grey 
                                          : const Color(0xFF1976D2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 38, vertical: 16),
                                      elevation: 4,
                                    ),
                                    icon: pdfUploadState is PdfUploadLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.upload_file, color: Colors.white),
                                    label: Text(
                                      pdfUploadState is PdfUploadLoading 
                                          ? 'جاري الرفع...' 
                                          : 'إرسال',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    // تعطيل الزر أثناء الرفع عشان منرفعش أكتر من مرة
                                    onPressed: pdfUploadState is PdfUploadLoading ? null : submit,
                                  ),
                                ]),
                          ),
                        ),
                      );
                    },
                  ); // إغلاق FileClassificationBloc BlocConsumer
                    },
                  ); // إغلاق PdfUploadBloc BlocConsumer
                }))
      ]),
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
