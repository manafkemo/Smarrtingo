import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';
import 'package:uuid/uuid.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];
  List<HabitCompletion> _completions = [];
  List<HabitCategory> _categories = [];
  final _uuid = const Uuid();

  // Fast lookup caches for high-performance rendering (O(1) lookups)
  final Map<String, Habit> _habitMap = {};
  final Map<String, int> _completionMap = {};

  List<Habit> get habits => _habits;
  List<HabitCompletion> get completions => _completions;
  List<HabitCategory> get categories => _categories;

  HabitProvider() {
    _loadData();
  }

  String _dateKey(String habitId, DateTime date) =>
      "${habitId}_${date.year}_${date.month}_${date.day}";

  void _rebuildFastLookup() {
    _habitMap.clear();
    for (final h in _habits) {
      _habitMap[h.id] = h;
    }

    _completionMap.clear();
    for (final c in _completions) {
      _completionMap[_dateKey(c.habitId, c.date)] = c.currentValue;
    }
  }

  // --- Persistence ---

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final habitsString = prefs.getString('habits');
    if (habitsString != null) {
      final List<dynamic> decoded = json.decode(habitsString);
      _habits = decoded.map((item) => Habit.fromMap(item)).toList();
    }

    final completionsString = prefs.getString('habit_completions');
    if (completionsString != null) {
      final List<dynamic> decoded = json.decode(completionsString);
      _completions = decoded.map((item) => HabitCompletion.fromMap(item)).toList();
    }
    
    final categoriesString = prefs.getString('habit_categories');
    if (categoriesString != null) {
      final List<dynamic> decoded = json.decode(categoriesString);
      _categories = decoded.map((item) => HabitCategory.fromMap(item)).toList();
    }

    _rebuildFastLookup();
    notifyListeners();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_habits.map((h) => h.toMap()).toList());
    await prefs.setString('habits', encoded);
  }

  Future<void> _saveCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_completions.map((c) => c.toMap()).toList());
    await prefs.setString('habit_completions', encoded);
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_categories.map((c) => c.toMap()).toList());
    await prefs.setString('habit_categories', encoded);
  }

  // --- Habit Management ---

  void addHabit(String name, String? category, int dailyTarget, HabitFrequency frequency, List<int> selectedDays, int colorValue, int iconCodePoint) {
    final newHabit = Habit(
      id: _uuid.v4(),
      name: name,
      category: category,
      dailyTarget: dailyTarget,
      frequency: frequency,
      selectedDays: selectedDays,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
    );
    _habits.add(newHabit);
    _habitMap[newHabit.id] = newHabit;
    _saveHabits();
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      _habitMap[habit.id] = habit;
      _saveHabits();
      notifyListeners();
    }
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _habitMap.remove(id);
    _completions.removeWhere((c) => c.habitId == id);
    _rebuildFastLookup();
    _saveHabits();
    _saveCompletions();
    notifyListeners();
  }

  // --- Category Management ---

  void addCategory(String name, int iconCodePoint) {
    if (_categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
        return; // Prevent duplicates
    }
    final newCategory = HabitCategory(
      id: _uuid.v4(),
      name: name,
      iconCodePoint: iconCodePoint,
    );
    _categories.add(newCategory);
    _saveCategories();
    notifyListeners();
  }

  void updateCategory(String id, String newName) {
    // 1. Update the category itself
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    
    final oldName = _categories[index].name;
    _categories[index] = HabitCategory(
      id: id,
      name: newName,
      iconCodePoint: _categories[index].iconCodePoint,
    );
    _saveCategories();

    // 2. Update all habits that used the old name
    for (int i = 0; i < _habits.length; i++) {
      if (_habits[i].category == oldName) {
        _habits[i] = _habits[i].copyWith(category: newName);
        _habitMap[_habits[i].id] = _habits[i];
      }
    }
    _saveHabits();
    
    notifyListeners();
  }

  void deleteCategory(String id) {
    // 1. Find the name before deleting
    final category = _categories.firstWhere((c) => c.id == id, orElse: () => HabitCategory(id: '', name: '', iconCodePoint: 0));
    if (category.id.isEmpty) return;

    // 2. Remove category
    _categories.removeWhere((c) => c.id == id);
    _saveCategories();

    // 3. Clear category from habits
    for (int i = 0; i < _habits.length; i++) {
      if (_habits[i].category == category.name) {
        _habits[i] = _habits[i].copyWith(clearCategory: true);
        _habitMap[_habits[i].id] = _habits[i];
      }
    }
    _saveHabits();

    notifyListeners();
  }

  // --- Completion Management ---

  void incrementProgress(String habitId, DateTime date) {
    // strict date check: only allow edits for today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate != today) {
        // Prevent editing past/future days
        return;
    }

    final habit = _habitMap[habitId];
    if (habit == null) return;
    
    final key = _dateKey(habitId, targetDate);
    final index = _completions.indexWhere((c) => 
      c.habitId == habitId && 
      c.date.year == targetDate.year &&
      c.date.month == targetDate.month &&
      c.date.day == targetDate.day
    );

    if (index != -1) {
      // Update existing completion
      final current = _completions[index];
      if (current.currentValue < habit.dailyTarget) {
          final updatedValue = current.currentValue + 1;
          _completions[index] = HabitCompletion(
              habitId: habitId,
              date: targetDate,
              currentValue: updatedValue,
              status: CompletionStatus.completed
          );
          _completionMap[key] = updatedValue;
      } else {
        // If already at max, toggle off
        _completions.removeAt(index);
        _completionMap.remove(key);
      }
    } else {
      // New completion
      _completions.add(HabitCompletion(
        habitId: habitId,
        date: targetDate,
        currentValue: 1,
        status: CompletionStatus.completed,
      ));
      _completionMap[key] = 1;
    }
    _saveCompletions();
    notifyListeners();
  }

  int getCompletionValue(String habitId, DateTime date) {
     return _completionMap[_dateKey(habitId, date)] ?? 0;
  }

  bool isCompleted(String habitId, DateTime date) {
     final habit = _habitMap[habitId];
     if (habit == null) return false;
     final val = getCompletionValue(habitId, date);
     return val >= habit.dailyTarget; 
  }

  double getOpacity(String habitId, DateTime date) {
      final habit = _habitMap[habitId];
      if (habit == null) return 0.0;
      final val = getCompletionValue(habitId, date);
      if (val <= 0) return 0.0;
      if (val >= habit.dailyTarget) return 1.0;
      
      final double progress = val / habit.dailyTarget;
      return 0.3 + (0.7 * progress);
  }

  List<HabitCompletion> getCompletionsForHabit(String habitId) {
    return _completions.where((c) => c.habitId == habitId).toList();
  }

  // --- Helper Methods for UI ---

  bool isHabitCompletedToday(String habitId) {
    return isCompleted(habitId, DateTime.now());
  }

  int getCompletionCountForDate(String habitId, DateTime date) {
    return getCompletionValue(habitId, date);
  }
}
