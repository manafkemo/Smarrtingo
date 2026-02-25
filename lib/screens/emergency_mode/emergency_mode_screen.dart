import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/task_provider.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.completionAcknowledgment.isNotEmpty 
                  ? provider.completionAcknowledgment 
                  : "Session Complete",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 40),
              if (provider.completionAcknowledgment.isEmpty)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final tasks = context.read<TaskProvider>().tasks;
                        final taskTitles = tasks.map((t) => t.title).toList();
                        provider.continueSession(taskTitles);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("CONTINUE"),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        provider.stopSession();
                      },
                      child: Text(
                        "STOP",
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("DONE"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
