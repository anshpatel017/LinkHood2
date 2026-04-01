/// Item categories for RentNear MVP
class CategoryConstants {
  CategoryConstants._();

  static const List<String> allCategories = [
    'tools',
    'cleaning',
    'garden',
    'electrical',
    'av_equipment',
    'access_equipment',
  ];

  static const Map<String, String> categoryLabels = {
    'tools': 'Power Tools',
    'cleaning': 'Cleaning',
    'garden': 'Garden & Outdoor',
    'electrical': 'Heavy-Duty Electrical',
    'av_equipment': 'AV Equipment',
    'access_equipment': 'Access Equipment',
  };

  static const Map<String, String> categoryIcons = {
    'tools': '🔧',
    'cleaning': '🧹',
    'garden': '🌱',
    'electrical': '🔌',
    'av_equipment': '📽️',
    'access_equipment': '🪜',
  };

  /// Example items per category (for onboarding checklist)
  static const Map<String, List<String>> categoryExamples = {
    'tools': ['Power drill', 'Jigsaw', 'Sander'],
    'cleaning': ['Vacuum cleaner', 'Pressure washer', 'Steam mop'],
    'garden': ['Gardening tools', 'Leaf blower', 'Lawn mower'],
    'electrical': ['Extension cable (heavy-duty)', 'Generator'],
    'av_equipment': ['Projector', 'Speakers', 'Microphone'],
    'access_equipment': ['Ladder', 'Step stool'],
  };

  static String getLabel(String category) {
    return categoryLabels[category] ?? category;
  }

  static String getIcon(String category) {
    return categoryIcons[category] ?? '📦';
  }
}
