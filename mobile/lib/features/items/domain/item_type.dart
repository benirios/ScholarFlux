enum ItemType {
  assignment,
  homework,
  test;

  String get label {
    switch (this) {
      case ItemType.assignment:
        return 'Assignment';
      case ItemType.homework:
        return 'Homework';
      case ItemType.test:
        return 'Test';
    }
  }

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ItemType.assignment,
    );
  }
}

enum ItemPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case ItemPriority.low:
        return 'Low';
      case ItemPriority.medium:
        return 'Medium';
      case ItemPriority.high:
        return 'High';
    }
  }
}

enum ItemStatus {
  pending,
  completed;

  String get label {
    switch (this) {
      case ItemStatus.pending:
        return 'Pending';
      case ItemStatus.completed:
        return 'Completed';
    }
  }
}
