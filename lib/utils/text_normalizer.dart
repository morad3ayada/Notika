/// Text normalization utilities for Arabic text matching
/// Handles Arabic diacritics, hamza variations, and whitespace normalization
class TextNormalizer {
  /// Normalizes Arabic text by removing diacritics, extra spaces, and standardizing hamza
  static String normalize(String? text) {
    if (text == null || text.isEmpty) return '';
    
    String normalized = text.trim().toLowerCase();
    
    // Remove Arabic diacritics (tashkeel)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '');
    
    // Normalize different forms of hamza
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');
    normalized = normalized.replaceAll(RegExp(r'[ؤ]'), 'و');
    normalized = normalized.replaceAll(RegExp(r'[ئ]'), 'ي');
    
    // Remove extra whitespace
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove punctuation
    normalized = normalized.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
    
    return normalized.trim();
  }
  
  /// Checks if two strings match after normalization
  static bool isMatch(String? text1, String? text2) {
    if (text1 == null || text2 == null) return false;
    return normalize(text1) == normalize(text2);
  }
  
  /// Checks if text1 contains text2 after normalization
  static bool contains(String? text1, String? text2) {
    if (text1 == null || text2 == null) return false;
    return normalize(text1).contains(normalize(text2));
  }
  
  /// Finds the best matching string from a list
  static String? findBestMatch(String? target, List<String> candidates) {
    if (target == null || candidates.isEmpty) return null;
    
    final normalizedTarget = normalize(target);
    
    // First try exact match
    for (final candidate in candidates) {
      if (normalize(candidate) == normalizedTarget) {
        return candidate;
      }
    }
    
    // Then try partial match
    for (final candidate in candidates) {
      if (contains(candidate, target) || contains(target, candidate)) {
        return candidate;
      }
    }
    
    return null;
  }
}
