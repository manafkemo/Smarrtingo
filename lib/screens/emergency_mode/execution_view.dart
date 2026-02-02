import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/emergency_provider.dart';

class ExecutionView extends StatelessWidget {
  const ExecutionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyModeProvider>(
      builder: (context, provider, _) {
        final duration = provider.remainingTime;
        final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

        return Scaffold(
          backgroundColor: Colors.black, // Extreme focus
          body: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "DO THIS NOW",
                          style: GoogleFonts.outfit(
                            color: Colors.grey[700],
                            fontSize: 14,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          provider.actionToExecute,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 36,
                            height: 1.1
                          ),
                        ),
                        const SizedBox(height: 60),
                         Text(
                          "$minutes:$seconds",
                          style: GoogleFonts.robotoMono(
                            color: const Color(0xFF26A69A), // Digital clock teal
                            fontSize: 64,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Slide to Complete or just a button for now.
              // PRD: "Optional 'intentional' completion gesture"
              Positioned(
                bottom: 50,
                left: 32,
                right: 32,
                child: GestureDetector(
                  onTap: () {
                     // Just a tap for now, can implement slide later if requested
                     provider.completeEarly();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(30)
                    ),
                    child: Center(
                      child: Text(
                        "DONE",
                         style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2
                          ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
