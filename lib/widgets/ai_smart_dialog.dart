import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';

import '../providers/task_provider.dart';

class AISmartDialog extends StatefulWidget {
  final Map<String, dynamic> initialTaskState;

  const AISmartDialog({super.key, required this.initialTaskState});

  @override
  State<AISmartDialog> createState() => _AISmartDialogState();
}

class _AISmartDialogState extends State<AISmartDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Chat History: List of Maps {role: 'user'|'model', content: '...'}
  final List<Map<String, String>> _chatHistory = [];
  
  bool _isLoading = false;
  Map<String, dynamic> _pendingUpdates = {};

  @override
  void initState() {
    super.initState();
    // Initial greeting
    _chatHistory.add({
      'role': 'model',
      'content': 'Hi! I can help you organize this task. Tell me what needs to be done, or ask me to simplifiy it.'
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      // Prepare categories map
      final categoriesMap = {
        for (var c in taskProvider.categories) c.id: c.name
      };

      // Call AI
      final result = await geminiService.chatWithAI(
        history: _chatHistory,
        currentTaskState: widget.initialTaskState,
        availableCategories: categoriesMap,
      );

      setState(() {
        _isLoading = false;
        
        if (result.containsKey('ai_response')) {
          _chatHistory.add({
            'role': 'model', 
            'content': result['ai_response']
          });
        }

        if (result.containsKey('suggested_task_updates')) {
          final updates = result['suggested_task_updates'] as Map<String, dynamic>;
          if (updates.isNotEmpty) {
            _pendingUpdates = updates; // Store updates to be applied
          }
        }
      });
      _scrollToBottom();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _chatHistory.add({
          'role': 'model',
          'content': 'Sorry, I encountered an error. Please try again.'
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _applyUpdates() {
    Navigator.pop(context, _pendingUpdates);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF0F5257), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Smarttingo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5257),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final message = _chatHistory[index];
                  final isUser = message['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF0F5257) : Colors.grey[100],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        message['content']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SizedBox(
                   width: 20, 
                   height: 20, 
                   child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F5257))
                ),
              ),

            // Pending Updates Preview (if any)
            if (_pendingUpdates.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'I have suggestions to update this task.',
                        style: TextStyle(color: Colors.orange[900], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: _applyUpdates,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),

            // Suggestions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildSuggestionChip('Simplify Steps', Icons.auto_awesome_mosaic_rounded),
                  _buildSuggestionChip('Optimize Title', Icons.title_rounded),
                  _buildSuggestionChip('Expand Notes', Icons.notes_rounded),
                  _buildSuggestionChip('Set a Deadline', Icons.calendar_month_rounded),
                  _buildSuggestionChip('Study Plan', Icons.school_rounded),
                  _buildSuggestionChip('Workout Plan', Icons.fitness_center_rounded),
                  _buildSuggestionChip('Code Task', Icons.code_rounded),
                  _buildSuggestionChip('Trip Plan', Icons.flight_takeoff_rounded),
                  _buildSuggestionChip('Recipe Steps', Icons.restaurant_menu_rounded),
                  _buildSuggestionChip('Add Details', Icons.add_circle_outline_rounded),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              minLines: 1,
                              maxLines: 3,
                              onSubmitted: (_) => _handleSendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded),
                            color: const Color(0xFF0F5257),
                            onPressed: _handleSendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: const Color(0xFF0F5257)),
        label: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF0F5257))),
        backgroundColor: const Color(0xFFE8F8F6),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          _controller.text = label;
          _handleSendMessage();
        },
      ),
    );
  }
}

