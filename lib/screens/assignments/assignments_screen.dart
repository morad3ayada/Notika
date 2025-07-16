import 'package:flutter/material.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;

  final List<String> schools = [
    'مدرسة بغداد',
    'مدرسة الكوفة',
    'مدرسة البصرة',
  ];
  final List<String> stages = [
    'الأول ابتدائي',
    'الثاني ابتدائي',
    'الثالث ابتدائي',
    'الرابع ابتدائي',
    'الخامس ابتدائي',
    'السادس ابتدائي',
  ];
  final List<String> sections = ['شعبة أ', 'شعبة ب', 'شعبة ج', 'شعبة د'];
  final List<String> subjects = ['اللغة العربية', 'التربية الإسلامية'];

  // قائمة الواجبات
  List<Map<String, dynamic>> assignments = [];

  // حقول الواجب الجديد
  final TextEditingController _pageFromController = TextEditingController();
  final TextEditingController _pageToController = TextEditingController();
  final TextEditingController _questionNumberController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  void _addAssignment() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        assignments.add({
          'pageFrom': _pageFromController.text,
          'pageTo': _pageToController.text,
          'questionNumber': _questionNumberController.text,
          'details': _detailsController.text,
          'class': selectedSection,
        });
        
        // مسح الحقول
        _pageFromController.clear();
        _pageToController.clear();
        _questionNumberController.clear();
        _detailsController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الواجب بنجاح'),
          backgroundColor: Color(0xFF1976D2),
        ),
      );
    }
  }

  void _removeAssignment(int index) {
    setState(() {
      assignments.removeAt(index);
    });
  }

  void _submitAssignments() {
    if (selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الشعبة')),
      );
      return;
    }

    if (assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة واجبات')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال ${assignments.length} واجب للشعبة $selectedSection'),
        backgroundColor: const Color(0xFF1976D2),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  Widget buildHorizontalSelector({
    required List<String> items,
    required String? selected,
    required Function(String) onSelect,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final isSelected = selected == item;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => onSelect(item),
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
                        item,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        "تحديد الواجبات",
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اختيارات المدرسة والمرحلة والشعبة
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                  child: buildHorizontalSelector(
                    items: schools,
                    selected: selectedSchool,
                    onSelect: (val) {
                      setState(() {
                        selectedSchool = val;
                        selectedStage = null;
                        selectedSection = null;
                      });
                    },
                    label: 'المدرسة',
                  ),
                ),
                if (selectedSchool != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                    child: buildHorizontalSelector(
                      items: stages,
                      selected: selectedStage,
                      onSelect: (val) {
                        setState(() {
                          selectedStage = val;
                          selectedSection = null;
                        });
                      },
                      label: 'المرحلة',
                    ),
                  ),
                if (selectedStage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                    child: buildHorizontalSelector(
                      items: sections,
                      selected: selectedSection,
                      onSelect: (val) {
                        setState(() {
                          selectedSection = val;
                          selectedSubject = null;
                        });
                      },
                      label: 'الشعبة',
                    ),
                  ),
                if (selectedSection != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                    child: buildHorizontalSelector(
                      items: subjects,
                      selected: selectedSubject,
                      onSelect: (val) {
                        setState(() {
                          selectedSubject = val;
                        });
                      },
                      label: 'المادة',
                    ),
                  ),
                if (selectedSubject != null) ...[
                  const SizedBox(height: 12),
                  // رأس النموذج
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.assignment_add,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'إضافة واجب جديد',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // النموذج
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // رقم الصفحة
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pageFromController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'من صفحة',
                                    labelStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A)),
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
                                    prefixIcon: const Icon(Icons.arrow_back, color: Color(0xFF1976D2)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'أدخل رقم الصفحة من';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _pageToController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'إلى صفحة',
                                    labelStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A)),
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
                                    prefixIcon: const Icon(Icons.arrow_forward, color: Color(0xFF1976D2)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'أدخل رقم الصفحة إلى';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // عنوان الواجب
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _questionNumberController,
                              keyboardType: TextInputType.text,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              decoration: InputDecoration(
                                labelText: 'عنوان الواجب',
                                labelStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A)),
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
                                prefixIcon: const Icon(Icons.title, color: Color(0xFF1976D2)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'أدخل عنوان الواجب';
                                }
                                return null;
                              },
                            ),
                          ),
                          // التفاصيل
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: TextFormField(
                              controller: _detailsController,
                              maxLines: 3,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              decoration: InputDecoration(
                                labelText: 'تفاصيل إضافية',
                                labelStyle: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A)),
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
                                prefixIcon: const Icon(Icons.info_outline, color: Color(0xFF1976D2)),
                              ),
                            ),
                          ),
                          // زر إضافة الواجب
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addAssignment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'إضافة الواجب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // قائمة الواجبات المضافة
                  if (assignments.isNotEmpty) ...[
                    Container(
                      height: 200,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.list,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'الواجبات المضافة (${assignments.length})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = assignments[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'من صفحة ${assignment['pageFrom']} إلى ${assignment['pageTo']} - سؤال ${assignment['questionNumber']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              assignment['details'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Color(0xFFE53935)),
                                        onPressed: () => _removeAssignment(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // زر إرسال الواجبات
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _submitAssignments,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text(
                        'إرسال الواجبات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // رسالة عند عدم اختيار شعبة
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'اختر الشعبة لتحديد الواجبات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageFromController.dispose();
    _pageToController.dispose();
    _questionNumberController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}
