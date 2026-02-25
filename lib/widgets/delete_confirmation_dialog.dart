import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onDelete;
  final String title;
  final String content;

  const DeleteConfirmationDialog({
    super.key,
    required this.onDelete,
    this.title = 'Delete Task?',
    this.content = 'Are you sure? This action will permanently remove this task from your To Do List.',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B9E9E),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1514B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F7F7),
                      foregroundColor: const Color(0xFF3B4A4A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Subtle highlight at the bottom
          Positioned(
            bottom: 0,
            left: 40,
            right: 40,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFF8A65).withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Icon Container
          Positioned(
            top: -35,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFF1514B),
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
