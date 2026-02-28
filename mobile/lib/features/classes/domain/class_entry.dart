/// A recurring weekly class entry linked to a subject.
class ClassEntry {
  final String id;
  final String subjectId;
  final int dayOfWeek; // 1 = Monday .. 7 = Sunday
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String? room;
  final String? floor;
  final String? teacher;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassEntry({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.floor,
    this.teacher,
    required this.createdAt,
    required this.updatedAt,
  });

  ClassEntry copyWith({
    String? id,
    String? subjectId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    String? floor,
    String? teacher,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassEntry(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      floor: floor ?? this.floor,
      teacher: teacher ?? this.teacher,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'floor': floor,
      'teacher': teacher,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClassEntry.fromMap(Map<String, dynamic> map) {
    return ClassEntry(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      dayOfWeek: map['dayOfWeek'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      room: map['room'] as String?,
      floor: map['floor'] as String?,
      teacher: map['teacher'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Compare by start time for sorting.
  int compareTo(ClassEntry other) => startTime.compareTo(other.startTime);

  static const weekdayLabels = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static const weekdayShort = [
    '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  String get weekdayLabel => weekdayLabels[dayOfWeek];

  /// Formatted time range (e.g., "10:00 – 11:30").
  String get timeRange => '$startTime – $endTime';

  /// Location string combining room and floor.
  String? get location {
    final parts = <String>[];
    if (room != null && room!.isNotEmpty) parts.add('Room $room');
    if (floor != null && floor!.isNotEmpty) parts.add('Floor $floor');
    return parts.isEmpty ? null : parts.join(', ');
  }
}
