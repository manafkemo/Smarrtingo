import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_selection_bottom_sheet.dart';

class EmergencyInputView extends StatefulWidget {
  const EmergencyInputView({super.key});

  @override
  State<EmergencyInputView> createState() => _EmergencyInputViewState();
}

class _EmergencyInputViewState extends State<EmergencyInputView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
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
      backgroundColor: const Color(0xFF90A4AE),
      body: Center(
        child: SingleChildScrollView(
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
                    Image.asset(
                      'assist/images/smarttingo-logo.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.psychology, color: Color(0xFF004D40), size: 60),
                    ),
                    const SizedBox(height: 24),
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
                    Text(
                      "Write anything. No need to be clear or complete.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF78909C),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<EmergencyModeProvider>(
                      builder: (context, provider, child) {
                        if (provider.selectedTask != null) {
                          final task = provider.selectedTask!;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFCFD8DC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(task.category.icon, color: task.category.color, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: const Color(0xFF263238),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => provider.selectTask(null),
                                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF78909C)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                if (task.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    task.description,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: const Color(0xFF546E7A),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return Container(
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
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Consumer<EmergencyModeProvider>(
                      builder: (context, provider, child) {
                        if (provider.selectedTask != null) return const SizedBox.shrink();
                        return OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => TaskSelectionBottomSheet(
                                onTaskSelected: (task) {
                                  provider.selectTask(task);
                                },
                              ),
                            );
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
                        );
                      },
                    ),
                    Consumer<EmergencyModeProvider>(
                      builder: (context, provider, child) {
                        if (provider.selectedTask == null) return const SizedBox.shrink();
                        return const SizedBox(height: 12);
                      },
                    ),
                    Consumer<EmergencyModeProvider>(
                      builder: (context, provider, child) {
                        final bool isEnabled = (provider.selectedTask != null || _controller.text.trim().isNotEmpty) && !provider.isLoading;
                        return ElevatedButton(
                          onPressed: isEnabled 
                            ? () {
                                if (provider.selectedTask != null) {
                                  provider.submitSelectedTask();
                                } else {
                                  final text = _controller.text.trim();
                                  final tasks = context.read<TaskProvider>().tasks;
                                  final taskTitles = tasks.map((t) => t.title).toList();
                                  provider.submitInput(text, taskTitles);
                                }
                              }
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004D40),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            disabledBackgroundColor: const Color(0xFF004D40).withOpacity(0.4),
                          ),
                          child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
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
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
