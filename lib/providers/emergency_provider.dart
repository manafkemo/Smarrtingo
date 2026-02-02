import 'dart:async';
import 'package:flutter/material.dart';

enum EmergencyStep {
  input,
  decision,
  executionSwitch,
  execution,
  completed,
}

class EmergencyModeProvider with ChangeNotifier {
  EmergencyStep _currentStep = EmergencyStep.input;
  String _userText = '';
  String _actionToExecute = '';
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  final Duration _defaultDuration = const Duration(minutes: 5); 

  EmergencyStep get currentStep => _currentStep;
  String get userText => _userText;
  String get actionToExecute => _actionToExecute;
  Duration get remainingTime => _remainingTime;

  bool get isTimerRunning => _timer != null && _timer!.isActive;

  // Step 1: Input
  void submitInput(String text) {
    _userText = text;
    // Simple heuristic for now: just use the text if short, or a generic placeholder
    // In future: integrate Generative AI here
    _actionToExecute = text.isNotEmpty ? text : "Just start somewhere."; 
    
    _currentStep = EmergencyStep.decision;
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
