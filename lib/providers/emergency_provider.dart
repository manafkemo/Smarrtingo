import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'task_provider.dart';

enum EmergencyStep {
  input,
  decision,
  executionSwitch,
  execution,
  completed,
}

class EmergencyModeProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  EmergencyStep _currentStep = EmergencyStep.input;
  String _userText = '';
  String _actionToExecute = '';
  String _durationText = '5 minutes';
  String _completionAcknowledgment = '';
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isLoading = false;
  bool _wasStoppedEarly = false;
  final Duration _defaultDuration = const Duration(minutes: 5);

  EmergencyStep get currentStep => _currentStep;
  String get userText => _userText;
  String get actionToExecute => _actionToExecute;
  String get durationText => _durationText;
  String get completionAcknowledgment => _completionAcknowledgment;
  Duration get remainingTime => _remainingTime;
  bool get isLoading => _isLoading;
  bool get wasStoppedEarly => _wasStoppedEarly;

  bool get isTimerRunning => _timer != null && _timer!.isActive;

  // Step 1: Input
  Future<void> submitInput(String text, List<String>? taskTitles) async {
    _userText = text;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _geminiService.getEmergencyAction(text, taskTitles);
      _actionToExecute = result['action'] ?? "Just start somewhere.";
      _durationText = result['duration'] ?? "5 minutes";
      
      // Parse duration to set timer
      int minutes = 5;
      final minutesMatch = RegExp(r'(\d+)').firstMatch(_durationText);
      if (minutesMatch != null) {
        minutes = int.tryParse(minutesMatch.group(1)!) ?? 5;
      }
      _remainingTime = Duration(minutes: minutes);
      
      // Directly start execution to avoid "confirmation" as per PRD "no confirmation required"
      _currentStep = EmergencyStep.execution;
      _startTimer();
    } catch (e) {
      debugPrint('Error in Emergency AI submit: $e');
      _actionToExecute = "Take 5 minutes to clear your mind.";
      _remainingTime = const Duration(minutes: 5);
      _currentStep = EmergencyStep.execution;
      _startTimer();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit a specifically selected task title
  Future<void> submitSelectedTask(String taskTitle) async {
    _userText = "Task: $taskTitle";
    _isLoading = true;
    notifyListeners();

    try {
      // When a specific task is selected, we pass it as the main input
      // and we don't necessarily need the rest of the task list context 
      // as the AI should focus on this specific one.
      final result = await _geminiService.getEmergencyAction("I am stuck on this task: $taskTitle", null);
      _actionToExecute = result['action'] ?? "Just start somewhere.";
      _durationText = result['duration'] ?? "5 minutes";
      
      int minutes = 5;
      final minutesMatch = RegExp(r'(\d+)').firstMatch(_durationText);
      if (minutesMatch != null) {
        minutes = int.tryParse(minutesMatch.group(1)!) ?? 5;
      }
      _remainingTime = Duration(minutes: minutes);
      
      _currentStep = EmergencyStep.execution;
      _startTimer();
    } catch (e) {
      debugPrint('Error in Emergency AI task submit: $e');
      _actionToExecute = "Take 5 minutes to clear your mind.";
      _remainingTime = const Duration(minutes: 5);
      _currentStep = EmergencyStep.execution;
      _startTimer();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle choice after timer ends
  Future<void> continueSession(List<String>? taskTitles) async {
    // Generate another single action
    await submitInput(_actionToExecute, taskTitles);
  }

  void stopSession() {
    _completionAcknowledgment = "Good. You started.";
    _currentStep = EmergencyStep.completed;
    notifyListeners();
  }

  // Step 2: Decision -> Switch
  void confirmDecision() {
    _currentStep = EmergencyStep.executionSwitch;
    notifyListeners();
  }

  // Step 3: Switch -> Execution (Lock)
  void lockAndStart() {
    _currentStep = EmergencyStep.execution;
    _remainingTime = _defaultDuration;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        _remainingTime = _remainingTime - const Duration(seconds: 1);
        notifyListeners();
      } else {
        _completeSession();
      }
    });
  }

  void _completeSession() {
    _timer?.cancel();
    _currentStep = EmergencyStep.completed;
    notifyListeners();
  }

  // Manual completion (optional "intentional gesture")
  void completeEarly() {
    _wasStoppedEarly = true;
    _completionAcknowledgment = "Stopping is fine. You can start again later.";
    _completeSession();
  }

  // Reset / Exit
  void endSession() {
    _timer?.cancel();
    _reset();
  }

  void _reset() {
     _currentStep = EmergencyStep.input;
    _userText = '';
    _actionToExecute = '';
    _remainingTime = Duration.zero;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
