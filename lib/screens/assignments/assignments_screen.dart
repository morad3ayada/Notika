import 'package:flutter/material.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedClass;
  final List<String> classes = [
    'الصف الأول',
    'الصف الثاني',
    'الصف الثالث',
    'الصف الرابع',
  ];

  // قائمة الواجبات
  List<Map<String, dynamic>> assignments = [];

  // حقول الواجب الجديد
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController _questionNumberController = TextEditingController();
  final TextEditingController _questionTextController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  void _addAssignment() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        assignments.add({
          'page': _pageController.text,
          'questionNumber': _questionNumberController.text,
          'questionText': _questionTextController.text,
          'details': _detailsController.text,
          'class': selectedClass,
        });
        
        // مسح الحقول
        _pageController.clear();
        _questionNumberController.clear();
        _questionTextController.clear();
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
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الفصل')),
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
        content: Text('تم إرسال ${assignments.length} واجب للفصل $selectedClass'),
        backgroundColor: const Color(0xFF1976D2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Column(
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

          // نموذج إضافة الواجب
          if (selectedClass != null) ...[
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // رقم الصفحة
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  controller: _pageController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'رقم الصفحة',
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
                                    prefixIcon: const Icon(Icons.pageview, color: Color(0xFF1976D2)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'أدخل رقم الصفحة';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // رقم السؤال
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  controller: _questionNumberController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'رقم السؤال',
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
                                    prefixIcon: const Icon(Icons.question_mark, color: Color(0xFF1976D2)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'أدخل رقم السؤال';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // نص السؤال
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                  controller: _questionTextController,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'نص السؤال',
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
                                    prefixIcon: const Icon(Icons.text_fields, color: Color(0xFF1976D2)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'أدخل نص السؤال';
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
                                        'صفحة ${assignment['page']} - سؤال ${assignment['questionNumber']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        assignment['questionText'],
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
            // رسالة عند عدم اختيار فصل
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اختر الفصل لتحديد الواجبات',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _questionNumberController.dispose();
    _questionTextController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}
