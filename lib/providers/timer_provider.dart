import 'package:flutter/material.dart';

class TimerProvider with ChangeNotifier {
  String _taskType = "Focus Session";
  String get taskType => _taskType;

  void setTaskType(String type) {
    if (_taskType != type) {
      _taskType = type;
      notifyListeners();
    }
  }
}
