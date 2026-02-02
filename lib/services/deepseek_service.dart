import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/task_model.dart';

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static const String _model = 'deepseek-chat';
  
  String get _apiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  /// Generate smart tasks from a goal description
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
      final response = await _sendChatRequest(prompt);
      
      if (response == null || response.isEmpty) return [];

      // Clean up potential markdown code blocks
      String cleanText = response.replaceAll('```json', '').replaceAll('```', '').trim();
      
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

  /// Enhance task description with AI assistance
  Future<String?> enhanceTaskDescription(String userInput, {String? taskContext}) async {
    final prompt = '''
The user is working on a task.
Task Context (Title/Description): "${taskContext ?? 'Not provided'}"
User Request: "$userInput"

Based on the User Request, provide an enhanced, detailed description for this task.
You can include specific subtasks, a more professional description, or steps to achieve the goal.
Return ONLY the suggested text for the description box. Do not output JSON.
''';

    try {
      return await _sendChatRequest(prompt);
    } catch (e) {
      debugPrint('Error enhancing description: $e');
      return null;
    }
  }

  /// Send a chat completion request to DeepSeek API
  Future<String?> _sendChatRequest(String prompt) async {
    if (_apiKey.isEmpty) {
      debugPrint('DeepSeek API key not found in .env file');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful task management assistant. Focus on clarifying requirements, breaking down tasks, and improving descriptions.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 402) {
        throw Exception('Insufficient balance in DeepSeek account. Please add funds.');
      } else {
        debugPrint('DeepSeek API error: ${response.statusCode} - ${response.body}');
        throw Exception('AI Service Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling DeepSeek API: $e');
      rethrow;
    }
  }
}
