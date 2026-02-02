import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';

class AddHabitDialog extends StatefulWidget {
  final Habit? habitToEdit;

  const AddHabitDialog({super.key, this.habitToEdit});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController; // New
  late int _dailyTarget; // New

  late HabitFrequency _frequency;
  late List<int> _selectedDays;
  late int _selectedColor;
  late int _selectedIcon;

  final List<int> _availableColors = [
    0xFF0F5257, // Primary Teal
    0xFF8DBFAF, // Details Teal
    0xFFC8F3F0, // Light Cyan
    0xFFEF5350, // Red
    0xFFAB47BC, // Purple
    0xFF43A047, // Green
    0xFFFFA726, // Orange
    0xFF5C6BC0, // Indigo
    0xFFEC407A, // Pink
    0xFF78909C, // Blue Grey
    0xFF8D6E63, // Brown
    0xFF26A69A, // Teal Accent
  ];

  final List<int> _availableIcons = [
    Icons.check_circle_outline.codePoint,
    Icons.water_drop_outlined.codePoint,
    Icons.fitness_center.codePoint,
    Icons.menu_book_outlined.codePoint,
    Icons.self_improvement.codePoint,
    Icons.brush_outlined.codePoint,
    Icons.code.codePoint,
    Icons.nightlight_outlined.codePoint,
    Icons.wb_sunny_outlined.codePoint,
    Icons.star_outline.codePoint,
    Icons.local_florist_outlined.codePoint,
    Icons.pedal_bike.codePoint,
    Icons.directions_run.codePoint,
    Icons.spa_outlined.codePoint,
    Icons.work_outline.codePoint,
    Icons.school_outlined.codePoint,
    Icons.home_outlined.codePoint,
    Icons.shopping_cart_outlined.codePoint,
    Icons.music_note_outlined.codePoint,
    Icons.camera_alt_outlined.codePoint,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habitToEdit?.name ?? '');
    _categoryController = TextEditingController(text: widget.habitToEdit?.category ?? '');
    _dailyTarget = widget.habitToEdit?.dailyTarget ?? 1;
    
    _frequency = widget.habitToEdit?.frequency ?? HabitFrequency.daily;
    _selectedDays = widget.habitToEdit?.selectedDays != null 
        ? List<int>.from(widget.habitToEdit!.selectedDays) 
        : [1, 2, 3, 4, 5, 6, 7];
    _selectedColor = widget.habitToEdit?.colorValue ?? _availableColors[0];
    _selectedIcon = widget.habitToEdit?.iconCodePoint ?? _availableIcons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      // Logic same as before
      final provider = Provider.of<HabitProvider>(context, listen: false);
      if (widget.habitToEdit != null) {
        provider.updateHabit(widget.habitToEdit!.copyWith(
          name: _nameController.text,
          category: _categoryController.text.isEmpty ? null : _categoryController.text,
          dailyTarget: _dailyTarget,
          frequency: _frequency,
          selectedDays: _selectedDays,
          colorValue: _selectedColor,
          iconCodePoint: _selectedIcon,
        ));
      } else {
        provider.addHabit(
          _nameController.text,
          _categoryController.text.isEmpty ? null : _categoryController.text,
          _dailyTarget,
          _frequency,
          _selectedDays,
          _selectedColor,
          _selectedIcon,
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.habitToEdit != null ? 'Edit Habit' : 'New Habit',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: 'e.g., Read for 30 mins',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0F5257), width: 2),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 8),
                          Consumer<HabitProvider>(
                            builder: (context, provider, child) {
                              final categories = provider.categories;
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...categories.map((cat) {
                                    final isSelected = _categoryController.text == cat.name;
                                    return ChoiceChip(
                                      label: Text(cat.name),
                                      avatar: Icon(cat.icon, size: 18, color: isSelected ? Colors.white : Colors.black54),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF0F5257),
                                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                                      onSelected: (selected) {
                                        setState(() {
                                          _categoryController.text = selected ? cat.name : '';
                                        });
                                      },
                                    );
                                  }),
                                  ActionChip(
                                    label: const Text('Add New'),
                                    onPressed: () => _showAddCategoryDialog(context),
                                    avatar: const Icon(Icons.add, size: 18),
                                  ),
                                ],
                              );
                            },
                          ),
                       ],
                     ),
                   ),
                   const SizedBox(width: 12),
                   SizedBox(
                     width: 100,
                     child: TextFormField(
                       initialValue: _dailyTarget.toString(),
                       style: const TextStyle(color: Colors.black),
                       keyboardType: TextInputType.number,
                       decoration: InputDecoration(
                         labelText: 'Daily Target',
                         labelStyle: const TextStyle(color: Colors.black54),
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0F5257), width: 2),
                         ),
                       ),
                       onChanged: (val) {
                          int? valInt = int.tryParse(val);
                          if (valInt != null) {
                             if (valInt > 5) valInt = 5;
                             if (valInt < 1) valInt = 1;
                             setState(() => _dailyTarget = valInt!);
                          }
                       },
                       validator: (val) {
                          int? v = int.tryParse(val ?? '');
                          if (v == null) return 'Invalid';
                          if (v > 5) return 'Max 5';
                          return null;
                       },
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: _selectedColor == color 
                              ? Border.all(color: Colors.black, width: 2) 
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final iconCode = _availableIcons[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconCode),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedIcon == iconCode 
                              ? Color(_selectedColor).withValues(alpha: 0.2) 
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: _selectedIcon == iconCode 
                              ? Border.all(color: Color(_selectedColor), width: 2) 
                              : null,
                        ),
                        child: Icon(
                          IconData(iconCode, fontFamily: 'MaterialIcons'),
                          color: _selectedIcon == iconCode ? Color(_selectedColor) : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.habitToEdit != null ? 'Update Habit' : 'Create Habit'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedIcon = _availableIcons[0]; // Default

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Icon:'),
                  SizedBox(
                    height: 50,
                    width: double.maxFinite,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableIcons.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final iconCode = _availableIcons[i];
                        return GestureDetector(
                          onTap: () {
                             setDialogState(() {
                               selectedIcon = iconCode;
                             });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedIcon == iconCode ? const Color(0xFF0F5257) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconData(iconCode, fontFamily: 'MaterialIcons'), 
                              color: selectedIcon == iconCode ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Provider.of<HabitProvider>(context, listen: false)
                          .addCategory(nameController.text, selectedIcon);
                      setState(() {
                        _categoryController.text = nameController.text;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
