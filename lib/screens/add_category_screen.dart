import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';


class AddCategoryScreen extends StatefulWidget {
  final TaskCategory? categoryToEdit;

  const AddCategoryScreen({super.key, this.categoryToEdit});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameController = TextEditingController();
  int _selectedIconCode = 0xe491; // Default to person outline
  int _selectedColorValue = 0xFF5C6BC0; // Default to Indigo

  // List of available icons (more than 30 as requested)
  final List<int> _availableIcons = [
    0xe491, 0xe6f4, 0xe59c, 0xe227, 0xf068, 0xe559, 0xe293, 0xe0b0, 0xe25b, 0xe62a, // Existing
    0xe123, 0xe3a7, 0xe15d, // System
    0xe539, 0xe54c, 0xe532, 0xe541, 0xe54d, // places
    0xe52f, 0xe574, 0xe55b, 0xe56c, 0xe53f, // maps
    0xe3e3, 0xe40f, 0xe405, 0xe432, 0xe425, // nature
    0xe84e, 0xe84f, 0xe88a, 0xe88f, 0xe897, // action
    0xe038, 0xe040, 0xe043, 0xe04b, 0xe04c, // av
  ];

  // List of colors (15+)
  final List<int> _availableColors = [
    0xFF5C6BC0, 0xFFEF5350, 0xFFAB47BC, 0xFF43A047, 0xFFEC407A, // Defaults
    0xFFFFA726, 0xFF0F5257, 0xFF78909C, 0xFF26A69A, 0xFF8D6E63, // Defaults
    0xFF039BE5, 0xFF0F5257,
    0xFFD32F2F, 0xFFC2185B, 0xFF7B1FA2, 0xFF512DA8, 0xFF303F9F, 0xFF1976D2,
    0xFF0288D1, 0xFF0097A7, 0xFF00796B, 0xFF388E3C, 0xFF689F38, 0xFFAFB42B,
    0xFFFBC02D, 0xFFFFA000, 0xFFF57C00, 0xFFE64A19, 0xFF5D4037, 0xFF616161,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _selectedIconCode = widget.categoryToEdit!.iconCodePoint;
      _selectedColorValue = widget.categoryToEdit!.colorValue;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_nameController.text.trim().isEmpty) return;

    final provider = Provider.of<TaskProvider>(context, listen: false);
    final name = _nameController.text.trim();

    final category = TaskCategory(
      id: widget.categoryToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      iconCodePoint: _selectedIconCode,
      iconFontFamily: 'MaterialIcons',
      colorValue: _selectedColorValue,
    );

    if (widget.categoryToEdit != null) {
      provider.updateCategory(category);
    } else {
      provider.addCategory(category);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
     return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Header Bar (Matches Add Task)
             Container(
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF0F5257),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
             Container(
              height: 8,
              color: const Color(0xFF2E8B92), 
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.categoryToEdit != null ? 'Edit Category' : 'New Category',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Dark Teal
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8F3F0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Color(0xFF0F5257), size: 20),
                          ),
                        ),
                      ],
                   ),
                   if (widget.categoryToEdit == null)
                   Padding(
                     padding: const EdgeInsets.only(top: 4.0),
                     child: Text(
                        'Create a new space for your tasks',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                     ),
                   ),

                   const SizedBox(height: 24),

                   // Name Input
                   const Text(
                     'CATEGORY NAME',
                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F5257), letterSpacing: 1.0),
                   ),
                   const SizedBox(height: 8),
                   TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Health & Wellness',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                   ),

                   const SizedBox(height: 24),

                   // Icon Picker
                   const Text(
                     'SELECT ICON',
                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F5257), letterSpacing: 1.0),
                   ),
                   const SizedBox(height: 8),
                   Container(
                     height: 70, // Row of icons
                     padding: const EdgeInsets.symmetric(vertical: 8),
                     decoration: BoxDecoration(
                        color: Colors.white, // Or slightly grey?
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                     ),
                     child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       padding: const EdgeInsets.symmetric(horizontal: 8),
                       itemCount: _availableIcons.length,
                       itemBuilder: (context, index) {
                         final iconCode = _availableIcons[index];
                         final isSelected = _selectedIconCode == iconCode;
                         return GestureDetector(
                           onTap: () {
                             setState(() {
                               _selectedIconCode = iconCode;
                             });
                           },
                           child: Container(
                             width: 50,
                             margin: const EdgeInsets.only(right: 8),
                             alignment: Alignment.center,
                             decoration: BoxDecoration(
                               color: isSelected ? const Color(0xFF0F5257) : Colors.white,
                               borderRadius: BorderRadius.circular(12),
                               // border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                             ),
                             child: Icon(
                               IconData(iconCode, fontFamily: 'MaterialIcons'),
                               color: isSelected ? Colors.white : Colors.grey,
                               size: 24,
                             ),
                           ),
                         );
                       },
                     ),
                   ),

                   const SizedBox(height: 24),

                   // Color Picker
                   const Text(
                     'COLOR THEME',
                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F5257), letterSpacing: 1.0),
                   ),
                   const SizedBox(height: 8),
                   SizedBox(
                     height: 50,
                     child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       itemCount: _availableColors.length,
                       itemBuilder: (context, index) {
                         final colorValue = _availableColors[index];
                         final isSelected = _selectedColorValue == colorValue;
                         final color = Color(colorValue);
                         
                         return GestureDetector(
                           onTap: () {
                             setState(() {
                               _selectedColorValue = colorValue;
                             });
                           },
                           child: Container(
                             width: 40,
                             height: 40,
                             margin: const EdgeInsets.only(right: 12),
                             decoration: BoxDecoration(
                               color: color,
                               shape: BoxShape.circle,
                               border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                               boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF0F5257).withValues(alpha: 0.3),
                                    blurRadius: 4, spreadRadius: 2
                                  )
                               ] : null,
                             ),
                             child: isSelected 
                               ? const Icon(Icons.check, color: Colors.white, size: 20)
                               : null, // Checkmark inside color circle? User image shows checkmark inside white circle OUTSIDE the color? 
                               // Image shows checkmark INSIDE the color circle for selected.
                               // Wait, image shows: Dark Teal filled circle with Checkmark.
                               // Other colors are just filled circles.
                           ),
                         );
                       },
                     ),
                   ),

                   const SizedBox(height: 32),

                   // Save Button
                   ElevatedButton.icon(
                      onPressed: _saveCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5257),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        widget.categoryToEdit != null ? 'Update Category' : 'Save Category',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
