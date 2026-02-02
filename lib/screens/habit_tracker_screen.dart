import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/monthly_habit_card.dart';
import '../widgets/yearly_habit_row.dart';
import '../utils/theme.dart';


class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  bool _isGridView = true;
  String? _selectedCategoryName; // Filter by category name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Slightly off-white for background
      appBar: AppBar(
        title: const Text('Habit Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
            IconButton(
                onPressed: () {
                     showDialog(
                        context: context,
                        builder: (context) => const AddHabitDialog(),
                      );
                }, 
                icon: const Icon(Icons.add, color: Colors.black)
            )
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          if (provider.habits.isEmpty) {
            return _buildEmptyState();
          }

          final filteredHabits = _selectedCategoryName == null
              ? provider.habits
              : provider.habits.where((h) => h.category == _selectedCategoryName).toList();

          return Column(
            children: [
              // Category Bar
              if (provider.categories.isNotEmpty)
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                       Padding(
                         padding: const EdgeInsets.only(right: 8),
                         child: FilterChip(
                           label: const Text('All'),
                           selected: _selectedCategoryName == null,
                           onSelected: (val) => setState(() => _selectedCategoryName = null),
                           selectedColor: const Color(0xFF0F5257),
                           labelStyle: TextStyle(color: _selectedCategoryName == null ? Colors.white : Colors.black),
                           checkmarkColor: Colors.white,
                         ),
                       ),
                       ...provider.categories.where((cat) {
                         // Only show categories that have at least one habit
                         return provider.habits.any((h) => h.category == cat.name);
                       }).map((cat) {
                         final isSelected = _selectedCategoryName == cat.name;
                         return Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: GestureDetector(
                             onLongPress: () {
                               _showCategoryParams(context, cat);
                             },
                             child: FilterChip(
                               label: Text(cat.name),
                               avatar: isSelected ? null : Icon(cat.icon, size: 16, color: Colors.black54),
                               selected: isSelected,
                               onSelected: (val) {
                                 setState(() {
                                   _selectedCategoryName = val ? cat.name : null;
                                 });
                               },
                               selectedColor: const Color(0xFF0F5257),
                               labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                               checkmarkColor: Colors.white,
                             ),
                           ),
                         );
                       }),
                    ],
                  ),
                ),

              // Content
              Expanded(
                child: filteredHabits.isEmpty
                    ? const Center(child: Text("No habits found in this category"))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2 habits per row
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75, // Taller cards to prevent overflow
                            ),
                            itemCount: filteredHabits.length,
                            itemBuilder: (context, index) {
                              return MonthlyHabitCard(
                                habit: filteredHabits[index],
                                onTap: () {},
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: filteredHabits.length,
                            itemBuilder: (context, index) {
                              return YearlyHabitRow(habit: filteredHabits[index]);
                            },
                          ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(icon: Icons.grid_view_rounded, isSelected: _isGridView, onTap: () => setState(() => _isGridView = true)),
            const SizedBox(width: 8),
            _buildToggleButton(icon: Icons.list_rounded, isSelected: !_isGridView, onTap: () => setState(() => _isGridView = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5257) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 100,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          const Text(
            'No habits yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddHabitDialog(),
              );
            },
            child: const Text('Add Your First Habit'),
          ),
        ],
      ),
    );
  }

  void _showCategoryParams(BuildContext context, dynamic category) {
    // category is HabitCategory
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Manage ${category.name}'),
        children: [
          SimpleDialogOption(
            onPressed: () {
               Navigator.pop(context);
               _showEditCategoryDialog(context, category);
            },
            child: const Text('Edit'),
          ),
          SimpleDialogOption(
            onPressed: () {
               Navigator.pop(context);
               _confirmDeleteCategory(context, category);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, dynamic category) {
      final nameController = TextEditingController(text: category.name);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                 if (nameController.text.isNotEmpty) {
                    Provider.of<HabitProvider>(context, listen: false).updateCategory(category.id, nameController.text);
                    Navigator.pop(context);
                 }
              },
              child: const Text('Save'),
            )
          ],
        ),
      );
  }

  void _confirmDeleteCategory(BuildContext context, dynamic category) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Delete Category'),
         content: const Text('Are you sure? This will remove the category from all associated habits.'),
         actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                 Provider.of<HabitProvider>(context, listen: false).deleteCategory(category.id);
                 Navigator.pop(context);
              },
              child: const Text('Delete'),
            )
         ],
       ),
     );
  }
}

