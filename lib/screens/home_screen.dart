import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../widgets/category_card.dart';
import '../utils/theme.dart';
import 'add_task_screen.dart';
import 'add_category_screen.dart'; // Import the new screen
import 'smart_todo_screen.dart';

import 'habit_tracker_screen.dart';
import 'calendar_screen.dart'; // New
import 'timer_screen.dart'; // New
import '../widgets/custom_app_bar.dart';
import '../widgets/today_category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0; // 0: Tasks, 1: Dashboard, 2: Smart, 3: Profile

  final List<Widget> _screens = [
    const HomeContent(),
    const CalendarScreen(), // Placeholder
    const SmartTodoScreen(),
    const HabitTrackerScreen(), // Replaced Stats
    const TimerScreen(), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.white, // Removed to use theme background
      appBar: CustomAppBar(currentTab: _currentTab),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        backgroundColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F5257),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            label: 'Smart Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'Timer',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTaskScreen()),
                );
                if (result == true) {
                  setState(() {
                    _currentTab = 1;
                  });
                }
              },
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null,
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {

  String _getGreeting() {
  final int hour = DateTime.now().hour;

  if (hour >= 0 && hour < 12) {
    return 'Good Morning';
  } else if (hour >= 12 && hour < 18) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}


  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final filteredTasks = taskProvider.filteredTasks;
    final selectedCategory = taskProvider.selectedCategory;

    return Column(
      children: [
        // Header Section - Greeting & Date
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '👋', 
                    style: TextStyle(
                      fontSize: 30, 
                      fontFamily: 'Noto Color Emoji',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.details,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        // Content Area
        Expanded(
          child: Column(
            children: [
              // Categories Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Categories Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                               showDialog(
                                 context: context,
                                 barrierColor: const Color(0x59000000),
                                 builder: (context) => const AddCategoryScreen(),
                               );
                            },
                            icon: Icon(Icons.add, color: AppColors.primary, size: 24),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TodayCategoryCard(
                      taskCount: taskProvider.tasks.where((t) => 
                            t.date.year == DateTime.now().year && 
                            t.date.month == DateTime.now().month && 
                            t.date.day == DateTime.now().day && 
                            !t.isCompleted).length,
                      isSelected: selectedCategory?.id == TaskCategory.today.id,
                      onTap: () {
                        taskProvider.setSelectedCategory(
                          selectedCategory?.id == TaskCategory.today.id ? null : TaskCategory.today,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...() {
                            final allTasks = taskProvider.tasks;
                            final allCategories = taskProvider.categories;
                            final List<TaskCategory> displayCategories = [
                              TaskCategory.completed
                            ];
                            
                            for (var category in allCategories) {
                               if (category.id != TaskCategory.today.id && 
                                   category.id != TaskCategory.completed.id) {
                                 displayCategories.add(category);
                               }
                            }

                            return displayCategories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: CategoryCard(
                                  category: category,
                                  taskCount: category.id == TaskCategory.completed.id
                                          ? allTasks.where((t) => t.isCompleted).length
                                          : allTasks.where((t) => t.category.id == category.id && !t.isCompleted).length,
                                  isSelected: selectedCategory?.id == category.id,
                                  onTap: () {
                                    taskProvider.setSelectedCategory(
                                      selectedCategory?.id == category.id ? null : category,
                                    );
                                  },
                                  onLongPress: () {
                                    if ([TaskCategory.completed.id, TaskCategory.today.id].contains(category.id)) return;
                                    _showEditDeleteDialog(context, category, taskProvider);
                                  },
                                ),
                              );
                            }).toList();
                          }(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assist/images/smarttingo-logo.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedCategory != null 
                                  ? 'No Tasks In ${selectedCategory.name}'
                                  : 'No Tasks Yet!',
                              style: TextStyle(fontSize: 18, color: Colors.grey.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return TaskTile(
                            task: task,
                            onToggle: () => taskProvider.toggleTaskCompletion(task.id),
                            onDelete: () {
                              _confirmDeleteTask(context, task, taskProvider);
                            },
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddTaskScreen(taskToEdit: task)),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteTask(BuildContext context, Task task, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(ctx);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDeleteDialog(BuildContext context, TaskCategory category, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit Category'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AddCategoryScreen(categoryToEdit: category),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Category', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Confirm delete
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Category?'),
                      content: Text('Are you sure you want to delete "${category.name}"? Tasks in this category will not be deleted but might lose their category reference.'), 
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            provider.deleteCategory(category.id);
                            Navigator.pop(ctx);
                          }, 
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}



