import 'dart:convert';
import 'package:flutter/material.dart';

enum HabitFrequency {
  daily,
  weekly,
}

enum CompletionStatus {
  completed,
  skipped,
}

class Habit {
  final String id;
  final String name;
  final String? category; // New optional category
  final int dailyTarget; // New daily target, default 1
  final HabitFrequency frequency;
  final List<int> selectedDays; // 1 = Monday, 7 = Sunday
  final int colorValue;
  final int iconCodePoint;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    this.category,
    this.dailyTarget = 1,
    this.frequency = HabitFrequency.daily,
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7],
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'dailyTarget': dailyTarget,
      'frequency': frequency.index,
      'selectedDays': selectedDays,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      dailyTarget: map['dailyTarget'] ?? 1,
      frequency: HabitFrequency.values[map['frequency']],
      selectedDays: List<int>.from(map['selectedDays']),
      colorValue: map['colorValue'],
      iconCodePoint: map['iconCodePoint'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Habit.fromJson(String source) => Habit.fromMap(json.decode(source));

  Habit copyWith({
    String? id,
    String? name,
    String? category,
    bool clearCategory = false,
    int? dailyTarget,
    HabitFrequency? frequency,
    List<int>? selectedDays,
    int? colorValue,
    int? iconCodePoint,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: clearCategory ? null : (category ?? this.category),
      dailyTarget: dailyTarget ?? this.dailyTarget,
      frequency: frequency ?? this.frequency,
      selectedDays: selectedDays ?? this.selectedDays,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class HabitCompletion {
  final String habitId;
  final DateTime date;
  final int currentValue; // New field for multi-completion progress
  final CompletionStatus status;

  HabitCompletion({
    required this.habitId,
    required this.date,
    this.currentValue = 1,
    this.status = CompletionStatus.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'currentValue': currentValue,
      'status': status.index,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      habitId: map['habitId'],
      date: DateTime.parse(map['date']),
      currentValue: map['currentValue'] ?? 1,
      status: CompletionStatus.values[map['status']],
    );
  }

  String toJson() => json.encode(toMap());

  factory HabitCompletion.fromJson(String source) => HabitCompletion.fromMap(json.decode(source));
}

class HabitCategory {
  final String id;
  final String name;
  final int iconCodePoint;

  HabitCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory HabitCategory.fromMap(Map<String, dynamic> map) {
    return HabitCategory(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
    );
  }

  String toJson() => json.encode(toMap());

  factory HabitCategory.fromJson(String source) => HabitCategory.fromMap(json.decode(source));
}
