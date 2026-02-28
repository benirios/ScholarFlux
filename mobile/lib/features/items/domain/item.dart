import 'package:flutter/foundation.dart';
import 'item_type.dart';

@immutable
class Item {
  final String id;
  final String subjectId;
  final String title;
  final ItemType type;
  final String description;
  final DateTime? dueDate;
  final ItemPriority priority;
  final ItemStatus status;
  final String? origin;
  final double? weight; // percentage weight for tests
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.type,
    this.description = '',
    this.dueDate,
    this.priority = ItemPriority.medium,
    this.status = ItemStatus.pending,
    this.origin,
    this.weight,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue =>
      status == ItemStatus.pending &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  bool get isUpcoming =>
      status == ItemStatus.pending &&
      dueDate != null &&
      dueDate!.isAfter(DateTime.now()) &&
      dueDate!.difference(DateTime.now()).inDays <= 7;

  bool get isCompleted => status == ItemStatus.completed;

  Item copyWith({
    String? id,
    String? subjectId,
    String? title,
    ItemType? type,
    String? description,
    DateTime? dueDate,
    ItemPriority? priority,
    ItemStatus? status,
    String? origin,
    double? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'type': type.name,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
      'origin': origin,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String,
      title: map['title'] as String,
      type: ItemType.fromString(map['type'] as String),
      description: map['description'] as String? ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      priority: ItemPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => ItemPriority.medium,
      ),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.pending,
      ),
      origin: map['origin'] as String?,
      weight: map['weight'] as double?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Item && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
