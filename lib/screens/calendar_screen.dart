import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/recurrence_utils.dart';

import 'add_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late ScrollController _verticalScrollController;
  late ScrollController _horizontalScrollController;
  final double _hourHeight = 80.0;
  final double _timeColumnWidth = 60.0;
  double _dayHeaderWidth = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-calculate vertical offset
    double verticalOffset = (DateTime.now().hour * _hourHeight) - 100;
    if (verticalOffset < 0) verticalOffset = 0;
    _verticalScrollController = ScrollController(initialScrollOffset: verticalOffset);
    
    // Horizontal offset will be set in the first build since it needs screen width
    _horizontalScrollController = ScrollController();
    
    _initHorizontalScroll();
  }

  void _initHorizontalScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (_horizontalScrollController.hasClients) {
         final screenWidth = MediaQuery.of(context).size.width;
         _dayHeaderWidth = screenWidth / 5;
         _horizontalScrollController.jumpTo((500 - 1) * _dayHeaderWidth);
         if (mounted) setState(() {});
       }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Scroll to the selected date as the SECOND item
      final todayAtMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final pickedAtMidnight = DateTime(picked.year, picked.month, picked.day);
      final difference = pickedAtMidnight.difference(todayAtMidnight).inDays;
      final index = 500 + difference;
      
      _horizontalScrollController.animateTo(
        (index - 1) * _dayHeaderWidth,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate 5 days: Yesterday, Today, +3 Future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DateTime> headerDays = List.generate(
      5, 
      (index) => today.subtract(const Duration(days: 1)).add(Duration(days: index))
    );

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedDate);

    return Scaffold(
      body: Column(
        children: [
          // 1. Month Title (Clickable)
          Padding(
             padding: const EdgeInsets.only(top: 16, bottom: 8),
             child: GestureDetector(
               onTap: _pickDate,
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                     monthTitle,
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                   const Icon(Icons.arrow_drop_down, size: 24),
                 ],
               ),
             ),
          ),

          // 2. Horizontal Day Header Strip
          Container(
            height: 90,
            child: ListView.builder(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 1000, // Large range for scrolling
              itemBuilder: (context, index) {
                final today = DateTime.now();
                final date = DateTime(today.year, today.month, today.day).add(Duration(days: index - 500));
                return SizedBox(
                  width: _dayHeaderWidth,
                  child: _buildDateHeaderItem(date),
                );
              },
            ),
          ),
          
          const Divider(height: 1, color: Colors.grey),

          // 3. Single Day Time Grid
          Expanded(
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: Stack(
                children: [
                  // Grid Lines
                  Column(
                    children: List.generate(24, (hour) {
                      return IntrinsicHeight(
                        child: Row(
                          children: [
                            SizedBox(
                              width: _timeColumnWidth,
                              height: _hourHeight,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    hour == 0 ? '' : '${hour.toString().padLeft(2, '0')}:00',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  // Hour line
                                  Divider(color: Colors.grey[200], height: 1),
                                  // Half-hour line (optional hint)
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        height: 1, 
                                        color: Colors.transparent, // Clean look, no half hour line
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  // Tasks for Selected Date
                  Positioned.fill(
                    left: _timeColumnWidth,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: _buildTaskWidgets(_selectedDate, constraints.maxWidth),
                        );
                      },
                    ),
                  ),

                  // Current Time Indicator (Only if selected date is Today)
                  if (_isSameDay(_selectedDate, DateTime.now()))
                    _buildCurrentTimeIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeaderItem(DateTime date) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    
    // Style from photo: Dark circle for selected.
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        // Also scroll to make this tapped date the SECOND item
        final todayAtMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final dateAtMidnight = DateTime(date.year, date.month, date.day);
        final difference = dateAtMidnight.difference(todayAtMidnight).inDays;
        final index = 500 + difference;
        
        _horizontalScrollController.animateTo(
          (index - 1) * _dayHeaderWidth,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('E').format(date).toUpperCase(), // MON
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF0F5257) : Colors.grey[500], // Teal if selected
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: isSelected 
              ? const BoxDecoration(
                  color: Color(0xFF0F5257), // Dark Teal Selected
                  shape: BoxShape.circle,
                  boxShadow: [
                     BoxShadow(
                       color: Colors.black26, blurRadius: 4, offset: Offset(0,2)
                     )
                  ]
                )
              : null,
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected 
                   ? Colors.white 
                   : (isToday ? const Color(0xFF0F5257) : Colors.black87), // Today colored text if not selected
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskWidgets(DateTime date, double fullWidth) {
    final taskProvider = Provider.of<TaskProvider>(context);
    
    // 1. Collect real tasks for the day
    final List<Task> dayTasks = taskProvider.tasks.where((t) => 
      _isSameDay(t.date, date)
    ).toList();

    // 2. Project recurring tasks for this day
    // We look at all tasks that HAVE a repeat config and could potentially occur on this day
    final recurringTasks = taskProvider.tasks.where((t) => t.repeatConfig != null).toList();
    
    for (var masterTask in recurringTasks) {
       // Only project if the master task hasn't occurred ON or AFTER this date as a real task
       // (To avoid showing both the project AND the real instance if they are both in the list)
       // Actually, getOccurrencesInRange is safer.
       
       final occurrences = RecurrenceUtils.getOccurrencesInRange(
         masterTask, 
         DateTime(date.year, date.month, date.day), 
         DateTime(date.year, date.month, date.day, 23, 59, 59)
       );
       
       for (var occurrenceDate in occurrences) {
          // Check if we already have a real task for this specific recurrence
          // (Simple check: same title and same day/time)
          bool alreadyExists = dayTasks.any((t) => 
            t.title == masterTask.title && 
            t.date.hour == occurrenceDate.hour && 
            t.date.minute == occurrenceDate.minute
          );
          
          if (!alreadyExists) {
             dayTasks.add(masterTask.copyWith(
               id: "${masterTask.id}_virtual_${occurrenceDate.millisecondsSinceEpoch}",
               date: occurrenceDate,
               endTime: masterTask.endTime != null 
                 ? occurrenceDate.add(masterTask.endTime!.difference(masterTask.date))
                 : null,
             ));
          }
       }
    }

    if (dayTasks.isEmpty) return [];

    // Layout Logic: Simple Greedy Column packing
    dayTasks.sort((a, b) => a.date.compareTo(b.date));

    List<List<Task>> columns = [];
    for (var task in dayTasks) {
      bool placed = false;
      for (var column in columns) {
          Task lastTask = column.last;
          DateTime lastEnd = lastTask.endTime ?? lastTask.date.add(const Duration(hours: 1));
          // If no overlap with last task in column, can place here?
          // NO, strictly checking if it starts AFTER the last one ends?
          // Actually, for visual side-by-side, we want to group overlapping tasks.
          // This logic places non-overlapping tasks in same column.
          // We want to find columns for CONCURRENT tasks.
          
          // Using the previous "column packing" logic:
          // A column represents a "lane". 
          // If task fits in lane (starts after last task in lane ends), add it.
          // Else new lane.
          if (task.date.isAfter(lastEnd) || task.date.isAtSameMomentAs(lastEnd)) {
             column.add(task);
             placed = true;
             break;
          }
      }
      if (!placed) {
        columns.add([task]);
      }
    }

    final int totalCols = columns.length;
    // Constraint: Max 3 columns visible? Or just let it be dynamic?
    // User requested "task take all width... if 2 tasks... width 2 part".
    // This implies flexible width = fullWidth / totalOverlappingCols.
    // BUT 'columns' list here represents "lanes". Lanes persist down the day.
    // If I have Task A (9-10) and Task B (11-12), they are in same lane (col 0).
    // They should both be full width?
    // Yes.
    // Issue: With this packing, Task A and B share lane 0. totalCols = 1. Width = Full. Correct.
    // If Task A (9-10) and Task C (9:30-10:30). Task C goes to lane 1. totalCols = 2.
    // Both A and C get 50% width?
    // Yes. A covers 9-10 (left half). C covers 9:30-10:30 (right half).
    // This is a simplified "lanes" viewing model (like Google Calendar).
    
    final double colWidth = fullWidth / totalCols;

    List<Widget> taskWidgets = [];

    for (int c = 0; c < totalCols; c++) {
      for (var task in columns[c]) {
         final top = (task.date.hour + (task.date.minute / 60)) * _hourHeight;
         
         double durationHours = 1.0; 
         if (task.endTime != null) {
           final diff = task.endTime!.difference(task.date).inMinutes;
           if (diff > 0) durationHours = diff / 60.0;
         }
         final height = durationHours * _hourHeight;

         taskWidgets.add(
           Positioned(
             left: c * colWidth, // Lane position
             top: top,
             width: colWidth - 4, // Leave small gap (space)
             // height: height, 
             child: SizedBox(
               height: height > 40 ? height : 40, // Min height
               child: CalendarTaskBlock(
                  key: ValueKey('${task.id}_${task.category.id}'),
                  task: task,
                ),
             ),
           ),
         );
      }
    }
    return taskWidgets;
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final top = (now.hour + (now.minute / 60)) * _hourHeight;

    return Positioned(
       top: top,
       left: 0, 
       right: 0,
       child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
             // The Red Line
             Container(
               margin: EdgeInsets.only(left: _timeColumnWidth), // Start line after time column
               height: 1, 
               color: Colors.red
             ),
             // The Time Bubble Tag
             Positioned(
                left: 2, // Inside Time Column area
                child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                   decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                   ),
                   child: Text(
                      DateFormat('HH:mm').format(now),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                   ),
                ),
             ),
             // The Circle Dot on the line
             Positioned(
               left: _timeColumnWidth - 3,
               child: Container(
                 width: 6, height: 6, 
                 decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
               ),
             )
          ],
       ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class CalendarTaskBlock extends StatefulWidget {
  final Task task;

  const CalendarTaskBlock({super.key, required this.task});

  @override
  State<CalendarTaskBlock> createState() => _CalendarTaskBlockState();
}

class _CalendarTaskBlockState extends State<CalendarTaskBlock> with SingleTickerProviderStateMixin {
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
          // Floating task block
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
                    child: _buildBlockContent(context, showMenu: true),
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onLongPress: _showOverlay,
        child: _buildBlockContent(context, showMenu: false),
      ),
    );
  }

  Widget _buildBlockContent(BuildContext context, {required bool showMenu}) {
    final task = widget.task;
    Color bgColor = task.category.color;
    if (task.isCompleted) {
      bgColor = bgColor.withValues(alpha: 0.5);
    }

    Color textColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    Color subTextColor = textColor.withValues(alpha: 0.8);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (!task.isCompleted || showMenu)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(1, 1),
            )
        ],
      ),
      child: showMenu
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    _hideOverlay();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddTaskScreen(taskToEdit: task)),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text('Edit', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    _hideOverlay();
                    final provider = Provider.of<TaskProvider>(context, listen: false);
                    _confirmDeleteTask(context, task, provider);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text('Delete', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat('HH:mm').format(task.date)} - ${DateFormat('HH:mm').format(task.endTime ?? task.date.add(const Duration(hours: 1)))}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
                      ),
                    ),
                    if (task.isCompleted)
                      Icon(Icons.check_circle, size: 14, color: textColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      task.description,
                      style: TextStyle(fontSize: 10, color: subTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
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
}
