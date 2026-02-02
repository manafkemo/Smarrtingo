import 'package:flutter/material.dart';

class SubtaskDialog extends StatefulWidget {
  final String initialContent;
  
  const SubtaskDialog({super.key, this.initialContent = ''});

  @override
  State<SubtaskDialog> createState() => _SubtaskDialogState();
}

class _SubtaskDialogState extends State<SubtaskDialog> {
  final List<SubtaskSection> _sections = [];
  final TextEditingController _sectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialContent.isNotEmpty) {
      _parseInitialContent();
    }
  }

  void _parseInitialContent() {
    // Parse existing content if needed
    // For now, just add as a single section
    if (widget.initialContent.isNotEmpty) {
      _sections.add(SubtaskSection(
        title: 'Main',
        subtasks: [],
      ));
    }
  }

  void _addSection() {
    if (_sectionController.text.trim().isEmpty) return;
    
    setState(() {
      _sections.add(SubtaskSection(
        title: _sectionController.text.trim(),
        subtasks: [],
      ));
      _sectionController.clear();
    });
  }

  void _addSubtask(int sectionIndex) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Subtask'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter subtask...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _sections[sectionIndex].subtasks.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5257),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  String _buildFormattedContent() {
    final buffer = StringBuffer();
    
    for (var section in _sections) {
      buffer.writeln(section.title);
      buffer.writeln();
      for (var i = 0; i < section.subtasks.length; i++) {
        buffer.writeln('${i + 1}. ${section.subtasks[i]}');
      }
      buffer.writeln();
    }
    
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Subtasks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2B2D),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Add Section Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sectionController,
                    decoration: InputDecoration(
                      hintText: 'Add paragraph/section...',
                      hintStyle: const TextStyle(color: Color(0xFFACB9B9)),
                      filled: true,
                      fillColor: const Color(0xFFF8FCFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5257),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sections List
            Expanded(
              child: _sections.isEmpty
                  ? const Center(
                      child: Text(
                        'Add a paragraph to start',
                        style: TextStyle(color: Color(0xFFACB9B9)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sections.length,
                      itemBuilder: (context, index) {
                        final section = _sections[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FCFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFD9F4F0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      section.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1B2B2D),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        color: const Color(0xFF0F5257),
                                        onPressed: () => _addSubtask(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        color: Colors.red,
                                        onPressed: () {
                                          setState(() {
                                            _sections.removeAt(index);
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (section.subtasks.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ...section.subtasks.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD9F4F0),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${entry.key + 1}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F5257),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF536969),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          color: Colors.red,
                                          onPressed: () {
                                            setState(() {
                                              section.subtasks.removeAt(entry.key);
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // Done Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _buildFormattedContent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5257),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }
}

class SubtaskSection {
  final String title;
  final List<String> subtasks;

  SubtaskSection({
    required this.title,
    required this.subtasks,
  });
}
