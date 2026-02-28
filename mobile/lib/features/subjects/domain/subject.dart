import 'package:flutter/foundation.dart';

import '../../items/domain/item.dart';

@immutable
class SubjectDomain {
  final String id;
  final String name;
  final double weight; // percentage, e.g. 60.0 for 60%

  const SubjectDomain({
    required this.id,
    required this.name,
    required this.weight,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'weight': weight,
      };

  factory SubjectDomain.fromMap(Map<String, dynamic> map) => SubjectDomain(
        id: map['id'] as String,
        name: map['name'] as String,
        weight: (map['weight'] as num).toDouble(),
      );

  SubjectDomain copyWith({String? id, String? name, double? weight}) =>
      SubjectDomain(
        id: id ?? this.id,
        name: name ?? this.name,
        weight: weight ?? this.weight,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SubjectDomain && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class Subject {
  final String id;
  final String name;
  final String? room;
  final List<SubjectDomain> domains;
  final double maxGrade; // grading scale ceiling (e.g. 20, 100, 10)
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subject({
    required this.id,
    required this.name,
    this.room,
    this.domains = const [],
    this.maxGrade = 20,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Compute per-domain averages from graded items.
  Map<String, double> domainAverages(List<Item> items) {
    final result = <String, double>{};
    for (final domain in domains) {
      final domainItems =
          items.where((i) => i.domainId == domain.id && i.grade != null);
      if (domainItems.isEmpty) continue;
      final sum = domainItems.fold<double>(0, (s, i) => s + i.grade!);
      result[domain.id] = sum / domainItems.length;
    }
    return result;
  }

  /// Weighted average grade across all domains.
  /// Returns null if there are no graded items.
  double? averageGrade(List<Item> items) {
    if (domains.isEmpty) {
      // No domains: simple average of all graded items
      final graded = items.where((i) => i.grade != null).toList();
      if (graded.isEmpty) return null;
      return graded.fold<double>(0, (s, i) => s + i.grade!) / graded.length;
    }
    final avgs = domainAverages(items);
    if (avgs.isEmpty) return null;
    double totalWeight = 0;
    double weightedSum = 0;
    for (final domain in domains) {
      final avg = avgs[domain.id];
      if (avg != null) {
        weightedSum += avg * domain.weight;
        totalWeight += domain.weight;
      }
    }
    if (totalWeight == 0) return null;
    return weightedSum / totalWeight;
  }

  Subject copyWith({
    String? id,
    String? name,
    String? room,
    List<SubjectDomain>? domains,
    double? maxGrade,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      domains: domains ?? this.domains,
      maxGrade: maxGrade ?? this.maxGrade,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'room': room,
      'domains': domains.map((d) => d.toMap()).toList(),
      'maxGrade': maxGrade,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      name: map['name'] as String,
      room: map['room'] as String?,
      domains: (map['domains'] as List<dynamic>?)
              ?.map((d) => SubjectDomain.fromMap(Map<String, dynamic>.from(d as Map)))
              .toList() ??
          [],
      maxGrade: (map['maxGrade'] as num?)?.toDouble() ?? 20,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Subject && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
