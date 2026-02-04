import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';
import 'task_detail_sheet.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _hideOverlay() async {
    if (_overlayEntry == null) return;
    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dimmed Background
          GestureDetector(
            onTap: _hideOverlay,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withValues(alpha: 0.3 * _animationController.value),
                );
              },
            ),
          ),
          // Floating Task Tile
          Positioned(
            left: offset.dx,
            top: offset.dy,
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _animationController,
                  child: Material(
                    color: Colors.transparent,
                    child: _buildTileContent(context, showMenu: true),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  Color _getPriorityColor() {
    return widget.task.priority.color;
  }

  String _getDueDateText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final taskDate = DateTime(widget.task.date.year, widget.task.date.month, widget.task.date.day);
    
    if (widget.task.isCompleted) {
      if (taskDate == yesterday) {
        return 'Completed yesterday';
      } else if (taskDate == today) {
        return 'Completed today';
      } else {
        return 'Completed ${DateFormat('MMM d').format(widget.task.date)}';
      }
    }
    
    if (taskDate == today) {
      return 'Due today, ${DateFormat('h:mm a').format(widget.task.date)}';
    } else if (taskDate == tomorrow) {
      return 'Due tomorrow';
    } else if (taskDate.isBefore(today)) {
      return 'Overdue - ${DateFormat('MMM d').format(widget.task.date)}';
    } else {
      return 'Due ${DateFormat('MMM d').format(widget.task.date)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: TaskDetailSheet(task: widget.task),
            ),
          );
        },
        onLongPress: _showOverlay,
        child: _buildTileContent(context, showMenu: false),
      ),
    );
  }

  Widget _buildTileContent(BuildContext context, {required bool showMenu}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: widget.task.isCompleted 
            ? Colors.grey.shade100 
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left vertical line indicator
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: widget.task.isCompleted 
                      ? AppColors.primary 
                      : _getPriorityColor(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Task content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.task.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: widget.task.isCompleted 
                                    ? Colors.grey 
                                    : Colors.black,
                                decoration: widget.task.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                decorationColor: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.label_outline_rounded,
                                  size: 14,
                                  color: widget.task.isCompleted ? Colors.grey.shade400 : const Color(0xFF0F5257),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.task.category.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.task.isCompleted 
                                        ? Colors.grey.shade400
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Dot separator
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  _getDueDateText(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.task.isCompleted 
                                        ? Colors.grey.shade400
                                        : Colors.grey[500],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.task.subtasks.isNotEmpty || widget.task.mediaPaths.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (widget.task.subtasks.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2F1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.list_rounded,
                                            size: 14,
                                            color: Color(0xFF0F5257),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.task.subtasks.where((s) => s.isCompleted).length}/${widget.task.subtasks.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0F5257),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (widget.task.mediaPaths.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.attach_file_rounded,
                                            size: 14,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.task.mediaPaths.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Right Content: Menu or Checkbox
                      if (showMenu)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Edit Task
                            InkWell(
                              onTap: () {
                                _hideOverlay();
                                if (widget.onEdit != null) widget.onEdit!();
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 18, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit Task',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Delete Task
                            InkWell(
                              onTap: () {
                                _hideOverlay();
                                widget.onDelete();
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete Task',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        // Right circular checkbox
                        GestureDetector(
                          onTap: widget.onToggle,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.task.isCompleted 
                                    ? AppColors.primary 
                                    : Colors.grey.withValues(alpha: 0.4),
                                width: 2,
                              ),
                              color: widget.task.isCompleted 
                                  ? AppColors.primary 
                                  : Colors.transparent,
                            ),
                            child: widget.task.isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
