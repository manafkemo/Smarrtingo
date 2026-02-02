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

  List<Habit> get habits => _habits;
  List<HabitCompletion> get completions => _completions;
  List<HabitCategory> get categories => _categories;

  HabitProvider() {
    _loadData();
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
    _saveHabits();
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      _saveHabits();
      notifyListeners();
    }
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _completions.removeWhere((c) => c.habitId == id);
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

    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception("Habit not found"));
    
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
          _completions[index] = HabitCompletion(
              habitId: habitId,
              date: targetDate,
              currentValue: current.currentValue + 1,
              status: CompletionStatus.completed
          );
      } else {
        // If already at max, maybe we want to toggle it off? 
        // Or for multi-completion, do we just stop? 
        // User requirements say "If the daily target is not completed... cell remains partially filled".
        // It doesn't explicitly say we can decrement. Let's assume toggle off if we hit max, or maybe a separate decrement?
        // Let's implement toggle behavior: if full, reset to 0 (remove).
        _completions.removeAt(index);
      }
    } else {
      // New completion
      _completions.add(HabitCompletion(
        habitId: habitId,
        date: targetDate,
        currentValue: 1,
        status: CompletionStatus.completed,
      ));
    }
    _saveCompletions();
    notifyListeners();
  }

  int getCompletionValue(String habitId, DateTime date) {
     final found = _completions.firstWhere((c) => 
      c.habitId == habitId && 
      c.date.year == date.year &&
      c.date.month == date.month &&
      c.date.day == date.day,
      orElse: () => HabitCompletion(habitId: habitId, date: date, currentValue: 0, status: CompletionStatus.skipped) // treating missing as 0
    );
     // If not found (and thus created dummy), currentValue is 0 if we assume logic above. 
     // Wait, the dummy in orElse has currentValue 1 by default in constructor if not specified? 
     // I passed 0 explicitly.
     return found.currentValue;
  }

  bool isCompleted(String habitId, DateTime date) {
     final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception("Habit not found"));
     final val = getCompletionValue(habitId, date);
     return val >= habit.dailyTarget; 
  }

  double getOpacity(String habitId, DateTime date) {
      final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => throw Exception("Habit not found"));
      final val = getCompletionValue(habitId, date);
      if (val == 0) return 0.0;
      // "The first completion of the day appears as the habit’s color with low opacity."
      // "When the daily target is fully completed, the color reaches full opacity."
      if (val >= habit.dailyTarget) return 1.0;
      
      // Proportional opacity between 0.2 and 1.0?
      // let's say min opacity is 0.3
      double progress = val / habit.dailyTarget;
      // map 0..1 progress to 0.3..1.0 opacity
      return 0.3 + (0.7 * progress);
  }

  List<HabitCompletion> getCompletionsForHabit(String habitId) {
    return _completions.where((c) => c.habitId == habitId).toList();
  }
  
  // Removed GetStreak as strictly requested: "No numeric counters, streak pressure messages"

  // --- Helper Methods for UI ---

  bool isHabitCompletedToday(String habitId) {
    return isCompleted(habitId, DateTime.now());
  }

  int getCompletionCountForDate(String habitId, DateTime date) {
    return getCompletionValue(habitId, date);
  }

}
