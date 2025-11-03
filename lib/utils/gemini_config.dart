class GeminiConfig {
  // https://aistudio.google.com/app/apikey
  static const String apiKey = 'AIzaSyDpBqwYn6Zz6d78jpC95te9HEW5QIWj8sg';
  
  static const String model = 'gemini-2.0-flash';
  
  // Check API Key Availabe
  static bool get isConfigured {
    if (apiKey.isEmpty) return false;
    
    final trimmedKey = apiKey.trim();
    

    final isValid = trimmedKey.length > 30 && trimmedKey.startsWith('AIza');
    
    // Debug:
    print('Gemini API Key Check:');
    print('  API Key (first 20 chars): ${trimmedKey.substring(0, trimmedKey.length > 20 ? 20 : trimmedKey.length)}...');
    print('  Length: ${trimmedKey.length}');
    print('  Starts with AIza: ${trimmedKey.startsWith('AIza')}');
    print('  Is Valid: $isValid');
    
    return isValid;
  }
}

