import 'package:flutter/material.dart';

class ExamQuestionsScreen extends StatefulWidget {
  const ExamQuestionsScreen({Key? key}) : super(key: key);

  @override
  State<ExamQuestionsScreen> createState() => _ExamQuestionsScreenState();
}

class _ExamQuestionsScreenState extends State<ExamQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedClass;
  final List<String> classes = [
    'الصف الأول',
    'الصف الثاني',
    'الصف الثالث',
    'الصف الرابع',
  ];

  final List<Map<String, dynamic>> questionTypes = [
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
  Map<String, List<Map<String, dynamic>>> questionsByType = {
    "choice": [],
    "truefalse": [],
    "complete": [],
    "essay": [],
  };

  // عدد الأسئلة لكل نوع
  Map<String, int> questionCounts = {
    "choice": 0,
    "truefalse": 0,
    "complete": 0,
    "essay": 0,
  };

  void _addQuestion(String type) {
    setState(() {
      questionsByType[type]!.add({
        "question": "",
        "options": ["", ""],
        "correctOption": null,
        "trueFalseAnswer": null,
        "completeAnswer": "",
        "essayAnswer": "",
      });
    });
  }

  void _removeQuestion(String type, int index) {
    setState(() {
      questionsByType[type]!.removeAt(index);
    });
  }

  void _updateQuestion(String type, int index, String field, dynamic value) {
    setState(() {
      questionsByType[type]![index][field] = value;
    });
  }

  void _addOption(String type, int questionIndex) {
    setState(() {
      questionsByType[type]![questionIndex]["options"].add("");
    });
  }

  void _removeOption(String type, int questionIndex, int optionIndex) {
    setState(() {
      questionsByType[type]![questionIndex]["options"].removeAt(optionIndex);
      if (questionsByType[type]![questionIndex]["correctOption"] != null &&
          questionsByType[type]![questionIndex]["correctOption"] >= questionsByType[type]![questionIndex]["options"].length) {
        questionsByType[type]![questionIndex]["correctOption"] = null;
      }
    });
  }

  void _submit() {
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الفصل')),
      );
      return;
    }

    int totalQuestions = 0;
    for (var questions in questionsByType.values) {
      totalQuestions += questions.length;
    }

    if (totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة أسئلة')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال $totalQuestions سؤال للفصل $selectedClass'),
        backgroundColor: const Color(0xFF43A047),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  Widget _buildQuestionInput(String type, int questionIndex) {
    final question = questionsByType[type]![questionIndex];

    switch (type) {
      case "choice":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'نص السؤال',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                maxLines: 2,
                initialValue: question["question"],
                onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
                validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFE3F2FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radio_button_checked, color: Color(0xFF1976D2), size: 20),
                      SizedBox(width: 8),
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
                  SizedBox(height: 12),
                  ...List.generate(question["options"].length, (optionIndex) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: question["correctOption"] == optionIndex 
                                ? Color(0xFF1976D2) 
                                : Theme.of(context).cardColor,
                            border: Border.all(
                              color: question["correctOption"] == optionIndex 
                                  ? Color(0xFF1976D2) 
                                  : Color(0xFFE0E0E0),
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
                        SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'اختيار ${optionIndex + 1}',
                              labelStyle: TextStyle(color: Color(0xFF607D8B)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                            ),
                            initialValue: question["options"][optionIndex],
                            onChanged: (val) {
                              question["options"][optionIndex] = val;
                              setState(() {});
                            },
                            validator: (val) => val == null || val.isEmpty ? 'أدخل نص الاختيار' : null,
                          ),
                        ),
                        if (question["options"].length > 2)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            child: IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                              onPressed: () => _removeOption(type, questionIndex, optionIndex),
                            ),
                          ),
                      ],
                    ),
                  )),
                  Container(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _addOption(type, questionIndex),
                      icon: Icon(Icons.add_circle_outline, color: Color(0xFF1976D2)),
                      label: Text(
                        'إضافة اختيار',
                        style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Color(0xFF1976D2), width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case "truefalse":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'نص السؤال',
                  labelStyle: TextStyle(color: Color(0xFF233A5A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                ),
                maxLines: 2,
                initialValue: question["question"],
                onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
                validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFC8E6C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF1976D2), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'الإجابة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF233A5A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: question["trueFalseAnswer"] == true ? Color(0xFF1976D2) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: question["trueFalseAnswer"] == true ? Color(0xFF1976D2) : Color(0xFFE0E0E0),
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
                                color: question["trueFalseAnswer"] == true ? Colors.white : Color(0xFF233A5A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            activeColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: question["trueFalseAnswer"] == false ? Color(0xFF1976D2) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: question["trueFalseAnswer"] == false ? Color(0xFF1976D2) : Color(0xFFE0E0E0),
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
                                color: question["trueFalseAnswer"] == false ? Colors.white : Color(0xFF233A5A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            activeColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      case "complete":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'نص السؤال',
                  labelStyle: TextStyle(color: Color(0xFF233A5A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                ),
                maxLines: 2,
                initialValue: question["question"],
                onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
                validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'الإجابة الصحيحة',
                  labelStyle: TextStyle(color: Color(0xFF233A5A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                ),
                initialValue: question["completeAnswer"],
                onChanged: (val) => _updateQuestion(type, questionIndex, "completeAnswer", val),
                validator: (val) => val == null || val.isEmpty ? 'أدخل الإجابة' : null,
              ),
            ),
          ],
        );
      case "essay":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'نص السؤال',
                  labelStyle: TextStyle(color: Color(0xFF233A5A)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                ),
                maxLines: 3,
                initialValue: question["question"],
                onChanged: (val) => _updateQuestion(type, questionIndex, "question", val),
                validator: (val) => val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'الإجابة النموذجية (اختياري)',
                  labelStyle: TextStyle(color: Color(0xFF607D8B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                ),
                maxLines: 4,
                initialValue: question["essayAnswer"],
                onChanged: (val) => _updateQuestion(type, questionIndex, "essayAnswer", val),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      "إرسال أسئلة امتحانات",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 0.2,
                      ),
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
          CustomPaint(
            size: Size.infinite,
            painter: _MeshBackgroundPainter(),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(gridColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اختيار الفصل
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: classes.map((className) {
                            final isSelected = selectedClass == className;
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () {
                                    setState(() {
                                      selectedClass = className;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
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
                                      className,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                        fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.quiz,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'أنواع الأسئلة',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.headlineSmall?.color ?? const Color(0xFF233A5A),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: questionTypes.length,
                        itemBuilder: (context, index) {
                          final type = questionTypes[index];
                          final typeValue = type['value'] as String;
                          final questions = questionsByType[typeValue]!;
                          final iconColor = type['iconColor'] as Color;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1976D2),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          type['icon'] as IconData,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              type['label'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${questions.length} سؤال',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${questions.length}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      ...List.generate(questions.length, (questionIndex) => Container(
                                        margin: const EdgeInsets.only(bottom: 20),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Theme.of(context).dividerColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: iconColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.question_mark,
                                                    color: iconColor,
                                                    size: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'سؤال ${questionIndex + 1}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: IconButton(
                                                    icon: Icon(Icons.delete, color: Colors.red[400], size: 20),
                                                    onPressed: () => _removeQuestion(typeValue, questionIndex),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            _buildQuestionInput(typeValue, questionIndex),
                                          ],
                                        ),
                                      )),
                                      Container(
                                        width: double.infinity,
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
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 20),
                        ),
                        icon: Icon(Icons.send, color: Colors.white, size: 24),
                        label: Text(
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

