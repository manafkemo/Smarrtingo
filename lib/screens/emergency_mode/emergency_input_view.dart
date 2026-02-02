import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/emergency_provider.dart';

class EmergencyInputView extends StatefulWidget {
  const EmergencyInputView({super.key});

  @override
  State<EmergencyInputView> createState() => _EmergencyInputViewState();
}

class _EmergencyInputViewState extends State<EmergencyInputView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using a "Modal" look even though it's a full screen view in the switcher,
    // we can style it to look like a card over a blurred background or just a clean page.
    // The PRD says "Appears as a modal / pop-up over the current screen". 
    // Since we navigated to this page, we can simulate the modal look.
    
    return Scaffold(
      backgroundColor: const Color(0xFF90A4AE), // Greyish background like the image
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, color: Color(0xFF004D40), size: 32),
                  ),
                  const SizedBox(height: 24),
                  
                  // Headline
                  Text(
                    "Overwhelmed?\nUnload Here.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF263238),
                      height: 1.2
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    "Write anything. No need to be clear or complete.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF78909C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(16), 
                      border: Border.all(color: const Color(0xFFCFD8DC))
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Just dump it all here...",
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // "Choose From Tasks" Button (Secondary)
                  OutlinedButton.icon(
                    onPressed: () {
                      // Placeholder for future feature
                    },
                    icon: const Icon(Icons.list, size: 20),
                    label: const Text("Choose From Tasks"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF546E7A),
                      side: const BorderSide(color: Color(0xFFCFD8DC)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // "Start Emergency Mode" Button (Primary)
                  ElevatedButton(
                    onPressed: () {
                      final text = _controller.text.trim();
                      // Even if empty, we can proceed (provider handles fallback)
                      context.read<EmergencyModeProvider>().submitInput(text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40), // Dark Teal
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start Emergency Mode",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
