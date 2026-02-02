import '../models/task_model.dart';

class RecurrenceUtils {
  /// Calculates the next occurrence date for a task based on its repeat configuration.
  /// Returns null if there are no more occurrences (e.g., end date or occurrences limit reached).
  static DateTime? getNextOccurrence(Task task) {
    if (task.repeatConfig == null) return null;

    final config = task.repeatConfig!;
    final currentDate = task.date;
    DateTime nextDate;

    switch (config.frequency) {
      case RepeatFrequency.daily:
        nextDate = currentDate.add(Duration(days: config.interval));
        break;
      case RepeatFrequency.weekly:
        if (config.repeatOn.isEmpty) {
          nextDate = currentDate.add(Duration(days: 7 * config.interval));
        } else {
          // Find the next day in the repeatOn list
          nextDate = _getNextWeeklyDate(currentDate, config);
        }
        break;
      case RepeatFrequency.monthly:
        nextDate = DateTime(
          currentDate.year,
          currentDate.month + config.interval,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
        // Handle Month-end overflow (e.g., Jan 31 -> Feb 28)
        if (nextDate.month > (currentDate.month + config.interval) % 12 && (currentDate.month + config.interval) % 12 != 0) {
           nextDate = DateTime(nextDate.year, nextDate.month, 0, currentDate.hour, currentDate.minute);
        }
        break;
      case RepeatFrequency.yearly:
        nextDate = DateTime(
          currentDate.year + config.interval,
          currentDate.month,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
        break;
    }

    // Check End Conditions
    if (config.endDate != null && nextDate.isAfter(config.endDate!)) {
      return null;
    }

    // Occurrences check would require tracking how many have passed.
    // In our "cloning" model, the new task doesn't easily know how many preceded it
    // unless we add a counter to Task or RepeatConfig.
    // For now, let's assume 'occurrences' is for the generator logic to stop.
    
    return nextDate;
  }

  static DateTime _getNextWeeklyDate(DateTime current, RepeatConfig config) {
    final sortedDays = List<int>.from(config.repeatOn)..sort();
    final currentDay = current.weekday; // 1 (Mon) - 7 (Sun)

    // Find first day in list that is > currentDay
    for (var day in sortedDays) {
      if (day > currentDay) {
        return current.add(Duration(days: day - currentDay));
      }
    }

    // If none found, go to the first day of the next interval
    final firstDay = sortedDays.first;
    final daysToNextWeek = (7 - currentDay) + firstDay;
    return current.add(Duration(days: daysToNextWeek + (7 * (config.interval - 1))));
  }

  /// Projects all occurrences of a task within a given date range.
  static List<DateTime> getOccurrencesInRange(Task task, DateTime start, DateTime end) {
    if (task.repeatConfig == null) {
      if (task.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
          task.date.isBefore(end.add(const Duration(seconds: 1)))) {
        return [task.date];
      }
      return [];
    }

    List<DateTime> occurrences = [];
    DateTime? next = task.date;

    // We start from the base task date and keep generating until we pass the range 'end'
    // or hit a repeat limit.
    int count = 0;
    while (next != null && next.isBefore(end.add(const Duration(days: 1)))) {
      if ((next.isAfter(start) || _isSameDay(next, start)) && 
          (next.isBefore(end) || _isSameDay(next, end))) {
        occurrences.add(next);
      }
      
      // Stop if occurrences limit reached
      count++;
      if (task.repeatConfig!.occurrences != null && count >= task.repeatConfig!.occurrences!) {
        break;
      }

      // Generate next "virtual" date
      next = _calculateNext(next, task.repeatConfig!);
      
      // Safety break to prevent infinite loops
      if (occurrences.length > 366) break; 
    }

    return occurrences;
  }

  static DateTime? _calculateNext(DateTime current, RepeatConfig config) {
      // Re-using logic similar to getNextOccurrence but without needing a Task object
       DateTime nextDate;

    switch (config.frequency) {
      case RepeatFrequency.daily:
        nextDate = current.add(Duration(days: config.interval));
        break;
      case RepeatFrequency.weekly:
        if (config.repeatOn.isEmpty) {
          nextDate = current.add(Duration(days: 7 * config.interval));
        } else {
          nextDate = _getNextWeeklyDate(current, config);
        }
        break;
      case RepeatFrequency.monthly:
        nextDate = DateTime(
          current.year,
          current.month + config.interval,
          current.day,
          current.hour,
          current.minute,
        );
        break;
      case RepeatFrequency.yearly:
        nextDate = DateTime(
          current.year + config.interval,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
        break;
    }

    if (config.endDate != null && nextDate.isAfter(config.endDate!)) {
      return null;
    }
    return nextDate;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
