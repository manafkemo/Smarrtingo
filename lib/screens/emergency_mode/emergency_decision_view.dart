import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/emergency_provider.dart';

class EmergencyDecisionView extends StatelessWidget {
  const EmergencyDecisionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238), // Dark background for impact
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "STOP\nTHINKING.",
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 56,
                color: Colors.white,
                height: 0.9,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "We have selected one single action for you to focus on.",
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            
            // "Action" Card Preview (Blurred/Obscured or simply abstract)
            // Just a visual cue that something is ready.
            Container(
              height: 4,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A),
                borderRadius: BorderRadius.circular(2)
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<EmergencyModeProvider>().confirmDecision();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A), // Teal Accent
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "SHOW ME",
                  style: GoogleFonts.outfit(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.2
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
