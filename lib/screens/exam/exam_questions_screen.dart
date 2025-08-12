import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../pdf/pdf_upload_screen.dart';

class ExamQuestionsScreen extends StatefulWidget {
  const ExamQuestionsScreen({Key? key}) : super(key: key);

  @override
  State<ExamQuestionsScreen> createState() => _ExamQuestionsScreenState();
}

class _ExamQuestionsScreenState extends State<ExamQuestionsScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  final _formKey = GlobalKey<FormState>();
  
  // --- selectors state and lists ---
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  
  // استخدام const للقوائم الثابتة
  static const List<String> schools = [
    'مدرسة بغداد',
    'مدرسة الكوفة',
    'مدرسة البصرة',
  ];
  static const List<String> stages = [
    'الأول ابتدائي',
    'الثاني ابتدائي',
    'الثالث ابتدائي',
    'الرابع ابتدائي',
    'الخامس ابتدائي',
    'السادس ابتدائي',
  ];
  static const List<String> sections = ['شعبة أ', 'شعبة ب', 'شعبة ج', 'شعبة د'];
  static const List<String> subjects = [
    'الرياضيات',
    'العلوم',
    'اللغة العربية',
    'اللغة الإنجليزية',
    'الدراسات الاجتماعية',
    'الحاسوب',
  ];
  
  String? selectedClass;
  static const List<String> classes = [
    'الصف الأول',
    'الصف الثاني',
    'الصف الثالث',
    'الصف الرابع',
  ];

  static const List<Map<String, dynamic>> questionTypes = [
    {
      "label": "اختياري", 
      "value": "choice", 
      "icon": Icons.radio_button_checked,
      "iconColor": Color(0xFF1976D2),
    },
    {
      "label": "صح أو خطأ", 
      "value": "truefalse", 
      "icon": Icons.check_circle,
      "iconColor": Color(0xFF1976D2),
    },
    {
      "label": "أكمل الفراغ", 
      "value": "complete", 
      "icon": Icons.edit,
      "iconColor": Color(0xFF1976D2),
    },
    {
      "label": "مقالي", 
      "value": "essay", 
      "icon": Icons.article,
      "iconColor": Color(0xFF1976D2),
    },
  ];

  // أسئلة من كل نوع
  final Map<String, List<Map<String, dynamic>>> questionsByType = {
    "choice": [],
    "truefalse": [],
    "complete": [],
    "essay": [],
  };

  // عدد الأسئلة لكل نوع
  final Map<String, int> questionCounts = {
    "choice": 0,
    "truefalse": 0,
    "complete": 0,
    "essay": 0,
  };

  // Cache للـ widgets المتكررة
  final Map<String, Widget> _cachedSelectors = {};
  final Map<String, Widget> _cachedQuestionInputs = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cachedSelectors.clear();
    _cachedQuestionInputs.clear();
    super.dispose();
  }

  // دالة لاختيار ملف PDF
  Future<void> _pickPdfFile() async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      
      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            selectedFile = file;
            isFileSelected = true;
            questionInputType = 'pdf';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم اختيار الملف: ${file.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // إخفاء مؤشر التحميل في حالة الخطأ
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // دالة لإلغاء الملف المختار
  void _cancelFile() {
    setState(() {
      selectedFile = null;
      isFileSelected = false;
      questionInputType = null;
    });
  }

  // دالة لإرسال الملف
  void _submitFile() {
    if (selectedFile == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال الملف: ${selectedFile!.name}'),
        backgroundColor: const Color(0xFF43A047),
        duration: const Duration(seconds: 2),
      ),
    );

    // يمكنك إضافة معالجة إضافية للملف هنا
    print('تم إرسال الملف: ${selectedFile!.path}');
    print('اسم الملف: ${selectedFile!.name}');
    print('حجم الملف: ${selectedFile!.size} bytes');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _addQuestion(String type) {
    if (mounted) {
      setState(() {
        questionsByType[type]!.add({
          "question": "",
          "options": ["", ""],
          "correctOption": null,
          "trueFalseAnswer": null,
          "completeAnswer": "",
          "essayAnswer": "",
        });
        // تحديث العداد
        questionCounts[type] = questionsByType[type]!.length;
      });
    }
  }

  void _removeQuestion(String type, int index) {
    if (mounted) {
      setState(() {
        questionsByType[type]!.removeAt(index);
        // تحديث العداد
        questionCounts[type] = questionsByType[type]!.length;
      });
    }
  }

  void _updateQuestion(String type, int index, String field, dynamic value) {
    if (mounted) {
      setState(() {
        questionsByType[type]![index][field] = value;
      });
    }
  }

  void _addOption(String type, int questionIndex) {
    if (mounted) {
      setState(() {
        questionsByType[type]![questionIndex]["options"].add("");
      });
    }
  }

  void _removeOption(String type, int questionIndex, int optionIndex) {
    if (mounted) {
      setState(() {
        questionsByType[type]![questionIndex]["options"].removeAt(optionIndex);
        if (questionsByType[type]![questionIndex]["correctOption"] != null &&
            questionsByType[type]![questionIndex]["correctOption"] >= questionsByType[type]![questionIndex]["options"].length) {
          questionsByType[type]![questionIndex]["correctOption"] = null;
        }
      });
    }
  }

  void _submit() {
    if (!mounted) return;
    
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الفصل'), duration: Duration(seconds: 1)),
      );
      return;
    }

    int totalQuestions = 0;
    for (var questions in questionsByType.values) {
      totalQuestions += questions.length;
    }

    if (totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أسئلة'), duration: Duration(seconds: 1)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال $totalQuestions سؤال للفصل $selectedClass'),
        backgroundColor: const Color(0xFF43A047),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // تحسين بناء حقول الأسئلة مع caching
  Widget _buildQuestionInput(String type, int questionIndex) {
    final cacheKey = '${type}_$questionIndex';
    if (_cachedQuestionInputs.containsKey(cacheKey)) {
      return _cachedQuestionInputs[cacheKey]!;
    }

    final question = questionsByType[type]![questionIndex];
    Widget widget;

    switch (type) {
      case "choice":
        widget = _buildChoiceQuestion(question, type, questionIndex);
        break;
      case "truefalse":
        widget = _buildTrueFalseQuestion(question, type, questionIndex);
        break;
      case "complete":
        widget = _buildCompleteQuestion(question, type, questionIndex);
        break;
      case "essay":
        widget = _buildEssayQuestion(question, type, questionIndex);
        break;
      default:
        widget = const SizedBox.shrink();
    }

    _cachedQuestionInputs[cacheKey] = widget;
    return widget;
  }

  Widget _buildChoiceQuestion(Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          maxLines: 2,
          initialValue: question["question"],
          onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
          validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_checked, color: Color(0xFF1976D2), size: 20),
                const SizedBox(width: 8),
                Text(
                  'الاختيارات:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: question["options"].length,
              itemBuilder: (context, optionIndex) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: question["correctOption"] == optionIndex 
                            ? const Color(0xFF1976D2) 
                            : Theme.of(context).cardColor,
                        border: Border.all(
                          color: question["correctOption"] == optionIndex 
                              ? const Color(0xFF1976D2) 
                              : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      child: Radio<int>(
                        value: optionIndex,
                        groupValue: question["correctOption"],
                        onChanged: (val) => _updateQuestion(type, questionIndex, "correctOption", val),
                        activeColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'اختيار ${optionIndex + 1}',
                          labelStyle: const TextStyle(color: Color(0xFF607D8B)),
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
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                        initialValue: question["options"][optionIndex],
                        onChanged: (val) {
                          _updateQuestion(type, questionIndex, "options", List<String>.from(question["options"])..[optionIndex] = val);
                        },
                        validator: (val) => val == null || val.isEmpty ? 'أدخل نص الاختيار' : null,
                      ),
                    ),
                    if (question["options"].length > 2)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                          onPressed: () => _removeOption(type, questionIndex, optionIndex),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _addOption(type, questionIndex),
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1976D2)),
                label: const Text(
                  'إضافة اختيار',
                  style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF1976D2), width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrueFalseQuestion(Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: const TextStyle(color: Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 2,
          initialValue: question["question"],
          onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
          validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF1976D2), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'الإجابة:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF233A5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: question["trueFalseAnswer"] == true ? const Color(0xFF1976D2) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: question["trueFalseAnswer"] == true ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      value: true,
                      groupValue: question["trueFalseAnswer"],
                      onChanged: (val) => _updateQuestion(type, questionIndex, "trueFalseAnswer", val),
                      title: Text(
                        'صح',
                        style: TextStyle(
                          color: question["trueFalseAnswer"] == true ? Colors.white : const Color(0xFF233A5A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      activeColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: question["trueFalseAnswer"] == false ? const Color(0xFF1976D2) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: question["trueFalseAnswer"] == false ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                    ),
                    child: RadioListTile<bool>(
                      value: false,
                      groupValue: question["trueFalseAnswer"],
                      onChanged: (val) => _updateQuestion(type, questionIndex, "trueFalseAnswer", val),
                      title: Text(
                        'خطأ',
                        style: TextStyle(
                          color: question["trueFalseAnswer"] == false ? Colors.white : const Color(0xFF233A5A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      activeColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteQuestion(Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: const TextStyle(color: Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 2,
          initialValue: question["question"],
          onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
          validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'الإجابة الصحيحة',
            labelStyle: const TextStyle(color: Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          initialValue: question["completeAnswer"],
          onChanged: (val) => _updateQuestion(type, questionIndex, "completeAnswer", val),
          validator: (val) => val == null || val.isEmpty ? 'أدخل الإجابة' : null,
        ),
      ],
    );
  }

  Widget _buildEssayQuestion(Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: const TextStyle(color: Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 3,
          initialValue: question["question"],
          onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
          validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'الإجابة النموذجية (اختياري)',
            labelStyle: const TextStyle(color: Color(0xFF607D8B)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 4,
          initialValue: question["essayAnswer"],
          onChanged: (val) => _updateQuestion(type, questionIndex, "essayAnswer", val),
        ),
      ],
    );
  }

  bool showManualForm = false;
  String? questionInputType; // 'manual' or 'pdf'
  
  // متغيرات لإدارة الملف المختار
  PlatformFile? selectedFile;
  bool isFileSelected = false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "أسئلة الامتحان",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              width: double.infinity,
              height: double.infinity,
            ),
            // تحسين CustomPaint - استخدام RepaintBoundary مع تحسين الأداء
            RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: const _MeshBackgroundPainter(),
                isComplex: false,
                willChange: false,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _GridPainter(gridColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                isComplex: false,
                willChange: false,
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- selectors ---
                        // (تظهر دائماً)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: schools.map((school) {
                                final isSelected = selectedSchool == school;
                                return Container(
                                  margin: const EdgeInsets.only(left: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                                                              onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedSchool = school;
                                              selectedStage = null;
                                              selectedSection = null;
                                              selectedSubject = null;
                                              questionInputType = null;
                                            });
                                          }
                                        },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                                  begin: Alignment.centerRight,
                                                  end: Alignment.centerLeft,
                                                )
                                              : null,
                                          color: isSelected ? null : Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          school,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textDirection: TextDirection.rtl,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: stages.map((stage) {
                                  final isSelected = selectedStage == stage;
                                  return Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedStage = stage;
                                              selectedSection = null;
                                              selectedSubject = null;
                                              questionInputType = null;
                                            });
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                                    begin: Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                  )
                                                : null,
                                            color: isSelected ? null : Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            stage,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            textDirection: TextDirection.rtl,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: sections.map((section) {
                                  final isSelected = selectedSection == section;
                                  return Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedSection = section;
                                              selectedSubject = null;
                                              questionInputType = null;
                                            });
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                                    begin: Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                  )
                                                : null,
                                            color: isSelected ? null : Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            section,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            textDirection: TextDirection.rtl,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: classes.map((cls) {
                                  final isSelected = selectedClass == cls;
                                  return Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedClass = cls;
                                              selectedSubject = null;
                                              questionInputType = null;
                                            });
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                                    begin: Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                  )
                                                : null,
                                            color: isSelected ? null : Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            cls,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        if (selectedClass != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: subjects.map((subject) {
                                  final isSelected = selectedSubject == subject;
                                  return Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedSubject = subject;
                                              questionInputType = null;
                                            });
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? const LinearGradient(
                                                    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                                    begin: Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                  )
                                                : null,
                                            color: isSelected ? null : Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            subject,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        // --- نهاية الاختيارات ---

                        // بعد اختيار المادة فقط تظهر خيارات نوع الأسئلة
                        if (selectedSubject != null && questionInputType == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    label: const Text('إنشاء الأسئلة يدويًا', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                    ),
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          questionInputType = 'manual';
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                                    label: const Text('رفع ملف PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                    ),
                                                                                                                onPressed: _pickPdfFile,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // إذا اختار يدوي تظهر واجهة الأسئلة
                        if (questionInputType == 'manual')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              ...questionTypes.map((type) {
                                final typeValue = type['value'] as String;
                                final questions = questionsByType[typeValue]!;
                                final iconColor = type['iconColor'] as Color;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(type['icon'] as IconData, color: iconColor, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          type['label'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${questions.length} سؤال',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: questions.length,
                                      addAutomaticKeepAlives: false,
                                      addRepaintBoundaries: true,
                                      itemBuilder: (context, questionIndex) => Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.question_mark, color: iconColor, size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                'سؤال ${questionIndex + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                                onPressed: () => _removeQuestion(typeValue, questionIndex),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildQuestionInput(typeValue, questionIndex),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 24),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: iconColor,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(color: iconColor, width: 2),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        icon: Icon(Icons.add_circle_outline, color: iconColor),
                                        label: Text(
                                          'إضافة سؤال ${type['label']}',
                                          style: TextStyle(
                                            color: iconColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        onPressed: () => _addQuestion(typeValue),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 20),
                                  ),
                                  icon: const Icon(Icons.send, color: Colors.white, size: 24),
                                  label: const Text(
                                    'إرسال الأسئلة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  onPressed: _submit,
                                ),
                              ),
                            ],
                          ),
                        // إذا اختار PDF يظهر الملف المختار أو حقل رفع PDF
                        if (questionInputType == 'pdf')
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 12),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 500),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (!isFileSelected) ...[
                                      // حالة عدم اختيار ملف
                                      const Icon(Icons.picture_as_pdf, color: Color(0xFF1976D2), size: 48),
                                      const SizedBox(height: 18),
                                      Text(
                                        'رفع ملف PDF لأسئلة الامتحان',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF233A5A)),
                                      ),
                                      const SizedBox(height: 18),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.upload_file, color: Colors.white),
                                        label: const Text('اختر ملف PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1976D2),
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                        ),
                                        onPressed: _pickPdfFile,
                                      ),
                                    ] else ...[
                                      // حالة اختيار ملف
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF1976D2), width: 2),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.picture_as_pdf, color: Color(0xFF1976D2), size: 48),
                                            const SizedBox(height: 16),
                                            Text(
                                              selectedFile!.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1976D2),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // زر إلغاء
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.cancel, color: Colors.white),
                                              label: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red[400],
                                                foregroundColor: Colors.white,
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                              ),
                                              onPressed: _cancelFile,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // زر اختيار ملف آخر
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.file_upload, color: Colors.white),
                                              label: const Text('ملف آخر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFF9800),
                                                foregroundColor: Colors.white,
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                              ),
                                              onPressed: _pickPdfFile,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // زر إرسال
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.send, color: Colors.white),
                                              label: const Text('إرسال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4CAF50),
                                                foregroundColor: Colors.white,
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                              ),
                                              onPressed: _submitFile,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// تحسين CustomPaint مع const constructors
class _MeshBackgroundPainter extends CustomPainter {
  const _MeshBackgroundPainter();
  
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFB0BEC5).withAlpha(33)
      ..strokeWidth = 1;
    final paintDot = Paint()
      ..color = const Color(0xFF3B5998).withAlpha(25)
      ..style = PaintingStyle.fill;
    
    // تحسين الحلقات
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
  
  const _GridPainter({required this.gridColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withAlpha(16)
      ..strokeWidth = 1;
    
    const step = 40.0;
    
    // تحسين رسم الخطوط
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

