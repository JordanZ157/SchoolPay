/// School constants for fixed class and major options
/// These values are used throughout the app for consistency
class SchoolConstants {
  // Available class levels (Kelas)
  static const List<String> classes = ['X', 'XI', 'XII'];
  
  // Available majors (Jurusan)
  static const List<String> majors = ['TKR', 'TKJ'];
  
  // Default values
  static const String defaultClass = 'X';
  static const String defaultMajor = 'TKR';
  
  // Display labels for UI
  static String getClassLabel(String className) => 'Kelas $className';
  static String getMajorLabel(String major) {
    switch (major) {
      case 'TKR':
        return 'Teknik Kendaraan Ringan';
      case 'TKJ':
        return 'Teknik Komputer dan Jaringan';
      default:
        return major;
    }
  }
  
  // Get full display class (e.g., "X - TKR")
  static String getDisplayClass(String className, String? major) {
    if (major != null && major.isNotEmpty) {
      return '$className - $major';
    }
    return className;
  }
}
