import 'package:flutter/foundation.dart';
import '../data/models/profile_models.dart';
import 'text_normalizer.dart';

/// Utility class for matching TeacherClass objects based on user selections
class TeacherClassMatcher {
  /// Finds a matching TeacherClass based on user selections
  /// Uses fuzzy matching to handle Arabic text variations
  static TeacherClass? findMatchingTeacherClass(
    List<TeacherClass> classes,
    String? selectedSchool,
    String? selectedLevel,
    String? selectedSection,
    String? selectedSubject,
  ) {
    if (classes.isEmpty) {
      print('❌ No teacher classes available');
      return null;
    }

    print('🔍 Searching for matching TeacherClass:');
    print('   School: $selectedSchool');
    print('   Level: $selectedLevel');
    print('   Section: $selectedSection');
    print('   Subject: $selectedSubject');

    // Phase 1: Try exact match after normalization
    for (final teacherClass in classes) {
      if (_isExactMatch(teacherClass, selectedSchool, selectedLevel, selectedSection, selectedSubject)) {
        print('✅ Found exact match: ${teacherClass.toString()}');
        return teacherClass;
      }
    }

    // Phase 2: Try partial match (especially for subjects)
    for (final teacherClass in classes) {
      if (_isPartialMatch(teacherClass, selectedSchool, selectedLevel, selectedSection, selectedSubject)) {
        print('✅ Found partial match: ${teacherClass.toString()}');
        return teacherClass;
      }
    }

    // Phase 3: Try match without spaces as last resort
    for (final teacherClass in classes) {
      if (_isMatchWithoutSpaces(teacherClass, selectedSchool, selectedLevel, selectedSection, selectedSubject)) {
        print('✅ Found match without spaces: ${teacherClass.toString()}');
        return teacherClass;
      }
    }

    print('❌ No matching TeacherClass found');
    return null;
  }

  /// Checks for exact match after text normalization
  static bool _isExactMatch(
    TeacherClass teacherClass,
    String? selectedSchool,
    String? selectedLevel,
    String? selectedSection,
    String? selectedSubject,
  ) {
    return TextNormalizer.isMatch(teacherClass.schoolName, selectedSchool) &&
           TextNormalizer.isMatch(teacherClass.levelName, selectedLevel) &&
           TextNormalizer.isMatch(teacherClass.className, selectedSection) &&
           TextNormalizer.isMatch(teacherClass.subjectName, selectedSubject);
  }

  /// Checks for partial match (useful for subjects with long names)
  static bool _isPartialMatch(
    TeacherClass teacherClass,
    String? selectedSchool,
    String? selectedLevel,
    String? selectedSection,
    String? selectedSubject,
  ) {
    return TextNormalizer.isMatch(teacherClass.schoolName, selectedSchool) &&
           TextNormalizer.isMatch(teacherClass.levelName, selectedLevel) &&
           TextNormalizer.isMatch(teacherClass.className, selectedSection) &&
           (TextNormalizer.contains(teacherClass.subjectName, selectedSubject) ||
            TextNormalizer.contains(selectedSubject, teacherClass.subjectName));
  }

  /// Checks for match without spaces (last resort)
  static bool _isMatchWithoutSpaces(
    TeacherClass teacherClass,
    String? selectedSchool,
    String? selectedLevel,
    String? selectedSection,
    String? selectedSubject,
  ) {
    final schoolMatch = _removeSpaces(teacherClass.schoolName) == _removeSpaces(selectedSchool);
    final levelMatch = _removeSpaces(teacherClass.levelName) == _removeSpaces(selectedLevel);
    final sectionMatch = _removeSpaces(teacherClass.className) == _removeSpaces(selectedSection);
    final subjectMatch = _removeSpaces(teacherClass.subjectName) == _removeSpaces(selectedSubject);

    return schoolMatch && levelMatch && sectionMatch && subjectMatch;
  }

  /// Removes all spaces from text
  static String _removeSpaces(String? text) {
    return TextNormalizer.normalize(text).replaceAll(' ', '');
  }

  /// Gets unique schools from teacher classes
  static List<String> getUniqueSchools(List<TeacherClass> classes) {
    final schools = <String>{};
    for (final teacherClass in classes) {
      if (teacherClass.schoolName != null && teacherClass.schoolName!.trim().isNotEmpty) {
        schools.add(teacherClass.schoolName!.trim());
      }
    }
    return schools.toList()..sort();
  }

  /// Gets unique levels for a specific school
  static List<String> getUniqueLevels(List<TeacherClass> classes, String? selectedSchool) {
    if (selectedSchool == null) return [];
    
    final levels = <String>{};
    for (final teacherClass in classes) {
      if (TextNormalizer.isMatch(teacherClass.schoolName, selectedSchool) &&
          teacherClass.levelName != null && 
          teacherClass.levelName!.trim().isNotEmpty) {
        levels.add(teacherClass.levelName!.trim());
      }
    }
    return levels.toList()..sort();
  }

  /// Gets unique sections for a specific school and level
  static List<String> getUniqueSections(List<TeacherClass> classes, String? selectedSchool, String? selectedLevel) {
    if (selectedSchool == null || selectedLevel == null) return [];
    
    final sections = <String>{};
    for (final teacherClass in classes) {
      if (TextNormalizer.isMatch(teacherClass.schoolName, selectedSchool) &&
          TextNormalizer.isMatch(teacherClass.levelName, selectedLevel) &&
          teacherClass.className != null && 
          teacherClass.className!.trim().isNotEmpty) {
        sections.add(teacherClass.className!.trim());
      }
    }
    return sections.toList()..sort();
  }

  /// Gets unique subjects for a specific school, level, and section
  static List<String> getUniqueSubjects(List<TeacherClass> classes, String? selectedSchool, String? selectedLevel, String? selectedSection) {
    if (selectedSchool == null || selectedLevel == null || selectedSection == null) return [];
    
    final subjects = <String>{};
    for (final teacherClass in classes) {
      if (TextNormalizer.isMatch(teacherClass.schoolName, selectedSchool) &&
          TextNormalizer.isMatch(teacherClass.levelName, selectedLevel) &&
          TextNormalizer.isMatch(teacherClass.className, selectedSection) &&
          teacherClass.subjectName != null && 
          teacherClass.subjectName!.trim().isNotEmpty) {
        subjects.add(teacherClass.subjectName!.trim());
      }
    }
    return subjects.toList()..sort();
  }
}
