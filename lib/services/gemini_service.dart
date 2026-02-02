import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/task_model.dart';

class GeminiService {
  final GenerativeModel _model;
  // Use the API key from .env, fallback to placeholder if not found (though it should be providing error if empty)


  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          // We access the static instance member or load it directly here. 
          // Better to pass it or load it within the method if it's dynamic, 
          // but for now we'll initialize it with the env var.
          apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        );

  Future<String?> enhanceTaskDescription(String userInput, {String? taskContext}) async {
    // Legacy method, keeping for now or we can redirect to chat logic if needed.
    // simpler prompt for just description
    final prompt = '''
The user is working on a task.
Task Context (Title/Description): "${taskContext ?? 'Not provided'}"
User Request: "$userInput"

Based on the User Request, provide an enhanced, detailed description for this task.
Return ONLY the suggested text for the description box.
''';
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint('Error enhancing description with Gemini: $e');
      rethrow;
    }
  }

  /// Chat with AI to build/refine a task.
  /// [history] is a list of sequential messages (User, AI, User, AI...)
  /// [currentTaskState] is a Map of the current task fields
  /// [availableCategories] is a Map of "id": "name"
  Future<Map<String, dynamic>> chatWithAI({
    required List<Map<String, String>> history,
    required Map<String, dynamic> currentTaskState,
    required Map<String, String> availableCategories,
  }) async {
    
    // Construct the conversation history for context
    final StringBuffer historyBuffer = StringBuffer();
    for (var msg in history) {
      historyBuffer.writeln("${msg['role']}: ${msg['content']}");
    }

    final String categoriesStr = availableCategories.entries
        .map((e) => "- ID: ${e.key}, Name: ${e.value}")
        .join("\n");

    final prompt = '''
You are a smart task assistant. Help the user create or refine a task.
Current Task State:
$currentTaskState

Available Categories:
$categoriesStr

Conversation History:
$historyBuffer

User's Latest Input: (See end of history)

INSTRUCTIONS:
1. Analyze the user's latest input and the conversation history.
2. Determine if you need to ask clarifying questions (e.g., "When is the deadline?", "Which category?").
3. Determine if the user's request implies updating any task fields (Title, Description, Category, Date/Time, Subtasks).
4. If the user asks to "simplify", generate a list of subtasks and clear/simplify the description.
5. Provide a JSON response with the following structure:
{
  "ai_response": "Your natural language response to the user here.",
  "suggested_task_updates": {
     // Only include keys that you recommend changing.
     "title": "New Title",
     "description": "New Description",
     "category_id": "category_id_from_list", 
     "date": "YYYY-MM-DD",
     "time": "HH:mm",
     "subtasks": ["Subtask 1", "Subtask 2"]
  },
  "is_confirmation": false // Set to true if you are asking "Shall I create this?" or similar.
}

COMMAND HANDLERS:
- "Simplify Steps": Break the task title/description into a logical list of subtasks.
- "Set a Deadline": Suggest a reasonable deadline (date and time) based on the task description.
- "Optimize Title": Suggest a more concise, action-oriented title.
- "Expand Notes": Generate a detailed, professional description/notes section for the task.
- "Add Details": Suggest categories, priorities, or additional context.
- "Study Plan": Act as a tutor. Break the goal into study sessions, topics to cover, and resources.
- "Workout Plan": Act as a personal trainer. Create a structured workout routine with sets/reps.
- "Code Task": Act as a senior engineer. Break this into technical implementation steps, edge cases, and testing.
- "Trip Plan": Act as a travel agent. Create a logical itinerary with transportation and activities.
- "Recipe Steps": Act as a chef. Convert the task into a clear, step-by-step recipe with preparation details.


CRITICAL: Return ONLY the raw JSON string. No markdown block markers.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      String? responseText = response.text;
      if (responseText == null) return {};

      // Clean markdown if present
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      try {
        return json.decode(responseText) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('JSON Parse Error: $responseText');
        // Fallback if model fails to output JSON
        return {
          "ai_response": "I'm having trouble processing that request. Please try again.",
          "suggested_task_updates": {}
        };
      }
    } catch (e) {
      debugPrint('Error interacting with Gemini: $e');
      rethrow;
    }
  }

  Future<List<Task>> generateSmartTasks(String goal) async {
    final prompt = '''
    I want to achieve the following goal: "$goal".
    Break this down into 3-5 actionable tasks.
    For each task, provide a title, a brief description, and a difficulty level (Easy, Medium, Hard).
    Format the output as a JSON list of objects with keys: "title", "description", "difficulty".
    Example:
    [
      {"title": "Research", "description": "Find resources", "difficulty": "Easy"},
      {"title": "Draft", "description": "Write initial draft", "difficulty": "Medium"}
    ]
    Do not include markdown formatting like ```json. Just the raw JSON string.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) return [];

      // Clean up potential markdown code blocks if the model ignores the instruction
      String cleanText = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      

      
      final List<dynamic> jsonList = json.decode(cleanText);
      final List<Task> tasks = [];
      
      for (var i = 0; i < jsonList.length; i++) {
        final item = jsonList[i];
        TaskPriority priority;
        switch (item['difficulty'].toString().toLowerCase()) {
          case 'high':
          case 'hard':
            priority = TaskPriority.high;
            break;
          case 'medium':
            priority = TaskPriority.medium;
            break;
          case 'low':
          case 'easy':
          default:
            priority = TaskPriority.low;
        }

        tasks.add(Task(
          id: DateTime.now().add(Duration(milliseconds: i)).millisecondsSinceEpoch.toString(),
          title: item['title'],
          description: item['description'],
          priority: priority,
          date: DateTime.now(),
        ));
      }
      
      return tasks;
    } catch (e) {
      debugPrint('Error generating tasks: $e');
      return [];
    }
  }
}
