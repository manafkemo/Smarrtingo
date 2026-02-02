import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emergency_provider.dart';
import 'emergency_input_view.dart';
import 'emergency_decision_view.dart';
import 'execution_switch_view.dart';
import 'execution_view.dart';

class EmergencyModeScreen extends StatelessWidget {
  const EmergencyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmergencyModeProvider(),
      child: Scaffold(
        backgroundColor: Colors.white, // Base generic color, specific views might override
        body: Consumer<EmergencyModeProvider>(
          builder: (context, provider, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentView(context, provider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentView(BuildContext context, EmergencyModeProvider provider) {
    switch (provider.currentStep) {
      case EmergencyStep.input:
        return const EmergencyInputView();
      case EmergencyStep.decision:
        return const EmergencyDecisionView();
      case EmergencyStep.executionSwitch:
        return const ExecutionSwitchView();
      case EmergencyStep.execution:
        return const ExecutionView();
      case EmergencyStep.completed:
         return _buildCompletionView(provider, context);
    }
  }

  Widget _buildCompletionView(EmergencyModeProvider provider, BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text("Session Complete", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             ElevatedButton(
               onPressed: () {
                 // Restart
                 provider.endSession(); // resets to input, essentially restarting
               }, 
               child: const Text("Another Action")
             ),
             TextButton(
               onPressed: () {
                 Navigator.of(context).pop(); // Exit Emergency Mode
               }, 
               child: const Text("End Session")
             )
          ],
        ),
      );
  }
}
