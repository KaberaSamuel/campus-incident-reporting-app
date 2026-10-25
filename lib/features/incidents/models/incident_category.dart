enum IncidentCategory {
  facilities('facilities'),
  water('water'),
  electricity('electricity'),
  furniture('furniture'),
  sanitation('sanitation'),
  safety('safety'),
  other('other');

  const IncidentCategory(this.firestoreValue);
  final String firestoreValue;

  static IncidentCategory fromFirestore(String value) {
    return IncidentCategory.values.firstWhere(
      (c) => c.firestoreValue == value,
      orElse: () => IncidentCategory.other,
    );
  }

  String get label {
    switch (this) {
      case IncidentCategory.facilities:
        return 'Facilities';
      case IncidentCategory.water:
        return 'Water';
      case IncidentCategory.electricity:
        return 'Electricity';
      case IncidentCategory.furniture:
        return 'Furniture';
      case IncidentCategory.sanitation:
        return 'Sanitation';
      case IncidentCategory.safety:
        return 'Safety';
      case IncidentCategory.other:
        return 'Other';
    }
  }
}
