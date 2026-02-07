import 'dart:convert';
import 'package:flutter/material.dart';


class TaskCategory {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int colorValue;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.colorValue,
  });

  IconData get icon => IconData(
    iconCodePoint,
    fontFamily: iconFontFamily,
    fontPackage: iconFontPackage,
  );

  Color get color => Color(colorValue);

  // Default Categories
  static const TaskCategory personal = TaskCategory(
    id: 'personal',
    name: 'Personal',
    iconCodePoint: 0xe491, // Icons.person_outline
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF5C6BC0,
  );

  static const TaskCategory work = TaskCategory(
    id: 'work',
    name: 'Work',
    iconCodePoint: 0xe6f4, // Icons.work_outline
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFFEF5350,
  );

  static const TaskCategory shopping = TaskCategory(
    id: 'shopping',
    name: 'Shopping',
    iconCodePoint: 0xe59c, // Icons.shopping_cart_outlined
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFFAB47BC,
  );

  static const TaskCategory finance = TaskCategory(
    id: 'finance',
    name: 'Finance',
    iconCodePoint: 0xe227, // Icons.attach_money
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF43A047,
  );

  static const TaskCategory family = TaskCategory(
    id: 'family',
    name: 'Family',
    iconCodePoint: 0xf068, // Icons.family_restroom
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFFEC407A,
  );

  static const TaskCategory education = TaskCategory(
    id: 'education',
    name: 'Education',
    iconCodePoint: 0xe559, // Icons.school_outlined
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFFFFA726,
  );

  static const TaskCategory goals = TaskCategory(
    id: 'goals',
    name: 'Goals',
    iconCodePoint: 0xe293, // Icons.flag_outlined
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF0F5257,
  );

  static const TaskCategory projects = TaskCategory(
    id: 'projects',
    name: 'Projects',
    iconCodePoint: 0xe0b0, // Icons.assignment_outlined
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF78909C,
  );

  static const TaskCategory health = TaskCategory(
    id: 'health',
    name: 'Health',
    iconCodePoint: 0xe25b, // Icons.favorite_outline
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF26A69A,
  );

  static const TaskCategory hobbies = TaskCategory(
    id: 'hobbies',
    name: 'Hobbies & Fun',
    iconCodePoint: 0xe62a, // Icons.sports_esports_outlined
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF8D6E63,
  );

  // Hidden/System Categories
  static const TaskCategory today = TaskCategory(
    id: 'today',
    name: 'Today',
    iconCodePoint: 0xe123, // Icons.calendar_today_outlined
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF0F5257,
  );

  static const TaskCategory completed = TaskCategory(
    id: 'completed',
    name: 'Completed',
    iconCodePoint: 0xe15d, // Icons.check_circle_outline
    iconFontFamily: 'MaterialIcons',
    colorValue: 0xFF0F5257,
  );

  static List<TaskCategory> get defaults => [
    personal, work, shopping, finance, family, education, goals, projects, health, hobbies,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'colorValue': colorValue,
    };
  }

  factory TaskCategory.fromMap(Map<String, dynamic> map) {
    return TaskCategory(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      iconFontFamily: map['iconFontFamily'],
      iconFontPackage: map['iconFontPackage'],
      colorValue: map['colorValue'],
    );
  }
  
  String toJson() => json.encode(toMap());
  factory TaskCategory.fromJson(String source) => TaskCategory.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum TaskPriority {
  none,
  low,
  medium,
  high,
}

extension TaskPriorityExtension on TaskPriority {
  String get name {
    switch (this) {
      case TaskPriority.none:
        return 'None';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';

    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.none:
        return Colors.grey;
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;

    }
  }
}

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

enum RepeatFrequency { daily, weekly, monthly, yearly }

class RepeatConfig {
  final RepeatFrequency frequency;
  final List<int> repeatOn; // 1-7 for Mon-Sun
  final List<int> repeatMonths; // 1-12 for Jan-Dec
  final int interval;
  final DateTime? endDate;
  final int? occurrences;

  RepeatConfig({
    required this.frequency,
    this.repeatOn = const [],
    this.repeatMonths = const [],
    this.interval = 1,
    this.endDate,
    this.occurrences,
  });

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.index,
      'repeatOn': repeatOn,
      'repeatMonths': repeatMonths,
      'interval': interval,
      'endDate': endDate?.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  factory RepeatConfig.fromMap(Map<String, dynamic> map) {
    return RepeatConfig(
      frequency: RepeatFrequency.values[map['frequency'] ?? 0],
      repeatOn: List<int>.from(map['repeatOn'] ?? []),
      repeatMonths: List<int>.from(map['repeatMonths'] ?? []),
      interval: map['interval'] ?? 1,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      occurrences: map['occurrences'],
    );
  }
}

enum TaskStatus {
  pending,
  completed,
  overdue,
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime date; // Used as due date
  final DateTime createdAt;
  final DateTime? endTime;
  final DateTime? completedAt;
  final List<String> mediaPaths;
  final List<SubTask> subtasks;
  final RepeatConfig? repeatConfig;
  final bool isPinned;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.category = TaskCategory.today,
    this.isCompleted = false,
    required this.date,
    DateTime? createdAt,
    this.endTime,
    this.completedAt,
    this.mediaPaths = const [],
    this.subtasks = const [],
    this.repeatConfig,
    this.isPinned = false,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskStatus get status {
    if (isCompleted) return TaskStatus.completed;
    if (date.isBefore(DateTime.now()) && 
        !(date.year == DateTime.now().year && 
          date.month == DateTime.now().month && 
          date.day == DateTime.now().day)) {
      return TaskStatus.overdue;
    }
    return TaskStatus.pending;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? date,
    DateTime? createdAt,
    DateTime? endTime,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    List<String>? mediaPaths,
    List<SubTask>? subtasks,
    RepeatConfig? repeatConfig,
    bool clearRepeatConfig = false,
    bool? isPinned,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      endTime: endTime ?? this.endTime,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      mediaPaths: mediaPaths ?? this.mediaPaths,
      subtasks: subtasks ?? this.subtasks,
      repeatConfig: clearRepeatConfig ? null : (repeatConfig ?? this.repeatConfig),
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'category': category.toMap(),
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'mediaPaths': mediaPaths,
      'subtasks': subtasks.map((x) => x.toMap()).toList(),
      'repeatConfig': repeatConfig?.toMap(),
      'isPinned': isPinned,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    TaskCategory? cat;
    if (map['category'] is int) {
      int index = map['category'];
      if (index >= 0 && index < TaskCategory.defaults.length) {
         cat = TaskCategory.defaults[index];
      } else {
         cat = TaskCategory.personal;
      }
    } else {
      cat = TaskCategory.fromMap(map['category']);
    }

    // Handle migration from difficulty to priority
    int priorityIndex = map['priority'] ?? map['difficulty'] ?? 0;

    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      priority: TaskPriority.values[priorityIndex],
      category: cat,
      isCompleted: map['isCompleted'] ?? false,
      date: DateTime.parse(map['date']),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      mediaPaths: List<String>.from(map['mediaPaths'] ?? []),
      subtasks: (map['subtasks'] as List<dynamic>?)?.map((x) => SubTask.fromMap(x)).toList() ?? [],
      repeatConfig: map['repeatConfig'] != null ? RepeatConfig.fromMap(map['repeatConfig']) : null,
      isPinned: map['isPinned'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));

  static String encode(List<Task> tasks) => 
      json.encode(tasks.map<Map<String, dynamic>>((task) => task.toMap()).toList());

  static List<Task> decode(String tasks) => 
      (json.decode(tasks) as List<dynamic>)
          .map<Task>((item) => Task.fromMap(item))
          .toList();
}

