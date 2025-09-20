import 'package:flutter/foundation.dart';

class GradeComponents with ChangeNotifier {
  static final GradeComponents _instance = GradeComponents._internal();
  
  factory GradeComponents() {
    return _instance;
  }
  
  GradeComponents._internal();

  // Default components
  List<String> _components = ['الأنشطة', 'الاختبارات القصيرة', 'أعمال السنة'];
  
  // Get current components
  List<String> get components => List.unmodifiable(_components);
  
  // Update components
  void updateComponents(List<String> newComponents) {
    _components = List.from(newComponents);
    notifyListeners();
  }
  
  // Clear components (reset to default)
  void resetToDefault() {
    _components = ['الأنشطة', 'الاختبارات القصيرة', 'أعمال السنة'];
    notifyListeners();
  }
}
