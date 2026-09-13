import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import 'package:intl/intl.dart';

class HabitHeatMap extends StatelessWidget {
  final String habitId;
  final Color baseColor;
  final bool isYearlyView;
  final DateTime? targetMonth; // For monthly view: specific month to show

  const HabitHeatMap({
    super.key,
    required this.habitId,
    required this.baseColor,
    this.isYearlyView = false,
    this.targetMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (isYearlyView) {
      return _buildYearlyGrid(context);
    }
    return _buildMonthlyCalendar(context);
  }

  // --- Monthly Calendar View (Clean, responsive, overflow-proof) ---
  Widget _buildMonthlyCalendar(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthToShow = targetMonth ?? DateTime(now.year, now.month);

    final int daysInMonth = DateUtils.getDaysInMonth(monthToShow.year, monthToShow.month);
    final int firstWeekday = DateTime(monthToShow.year, monthToShow.month, 1).weekday; // 1=Mon...7=Sun
    final int offset = firstWeekday - 1; // 0 for Mon, 6 for Sun
    final int totalSlots = offset + daysInMonth;
    final int rowCount = (totalSlots / 7).ceil();

    final provider = Provider.of<HabitProvider>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell size that fits both horizontally and vertically
        const double horizontalGap = 3.0;
        const double verticalGap = 3.0;
        const double headerHeight = 16.0;

        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 140.0;

        // Max cell width based on 7 columns
        final double maxCellWidth = ((availableWidth - (6 * horizontalGap)) / 7).clamp(8.0, 26.0);
        // Max cell height based on rowCount + header
        final double maxCellHeight = ((availableHeight - headerHeight - ((rowCount - 1) * verticalGap)) / rowCount).clamp(8.0, 26.0);

        final double cellSize = (maxCellWidth < maxCellHeight ? maxCellWidth : maxCellHeight);

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Weekday Header Row
            SizedBox(
              height: headerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return SizedBox(
                    width: cellSize,
                    child: Text(
                      day,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 2),

            // Calendar Rows
            ...List.generate(rowCount, (rowIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 0 : verticalGap),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (colIndex) {
                    final int slotIndex = rowIndex * 7 + colIndex;
                    if (slotIndex < offset || slotIndex >= totalSlots) {
                      return SizedBox(width: cellSize, height: cellSize);
                    }

                    final int day = slotIndex - offset + 1;
                    final date = DateTime(monthToShow.year, monthToShow.month, day);
                    final bool isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                    final bool isFuture = date.isAfter(today);

                    final double opacity = isFuture ? 0.0 : provider.getOpacity(habitId, date);

                    Color cellColor;
                    if (isFuture) {
                      cellColor = Colors.grey.withValues(alpha: 0.08);
                    } else if (opacity > 0) {
                      cellColor = baseColor.withValues(alpha: opacity);
                    } else {
                      cellColor = baseColor.withValues(alpha: 0.08);
                    }

                    return GestureDetector(
                      onTap: (isToday && !isFuture)
                          ? () => provider.incrementProgress(habitId, date)
                          : null,
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(cellSize > 18 ? 4 : 3),
                          border: isToday
                              ? Border.all(color: Colors.black87, width: 1.5)
                              : (isFuture
                                  ? null
                                  : Border.all(color: Colors.black.withValues(alpha: 0.04), width: 0.5)),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // --- Yearly HeatMap View (GitHub style, blazing-fast CustomPaint) ---
  Widget _buildYearlyGrid(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final provider = Provider.of<HabitProvider>(context, listen: false);

    // Current week's Monday
    final currentWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    // Start of the grid (51 weeks ago)
    final gridStartDate = currentWeekMonday.subtract(const Duration(days: 51 * 7));

    // Precompute opacities for all 364 days in O(1) lookups
    final List<List<_CellData>> columns = List.generate(52, (colIndex) {
      final weekStart = gridStartDate.add(Duration(days: colIndex * 7));
      return List.generate(7, (rowIndex) {
        final date = weekStart.add(Duration(days: rowIndex));
        final isFuture = date.isAfter(today);
        final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
        final double opacity = isFuture ? 0.0 : provider.getOpacity(habitId, date);
        return _CellData(date: date, opacity: opacity, isToday: isToday, isFuture: isFuture);
      });
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Start at the current week
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header labels
          Row(
            children: [
              const SizedBox(width: 30), // Match weekday label width
              ...List.generate(52, (colIndex) {
                final weekStart = gridStartDate.add(Duration(days: colIndex * 7));
                String monthText = "";
                if (weekStart.day <= 7) {
                  monthText = DateFormat('MMM').format(weekStart);
                }
                return SizedBox(
                  width: 15.0, // Cell width (12) + gap (3)
                  child: monthText.isNotEmpty
                      ? Text(
                          monthText,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.grey),
                          overflow: TextOverflow.visible,
                          softWrap: false,
                        )
                      : null,
                );
              }),
            ],
          ),
          const SizedBox(height: 4),

          // Days + Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday labels
              Column(
                children: const [
                  _WeekdayLabel(''),
                  _WeekdayLabel('Tue'),
                  _WeekdayLabel(''),
                  _WeekdayLabel('Thu'),
                  _WeekdayLabel(''),
                  _WeekdayLabel('Sat'),
                  _WeekdayLabel(''),
                ],
              ),
              const SizedBox(width: 4),

              // 52 columns of 7 cells using fast CustomPaint
              CustomPaint(
                size: const Size(52 * 15.0, 7 * 15.0),
                painter: _YearlyHeatMapPainter(
                  columns: columns,
                  baseColor: baseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 15.0, // 12 cell + 3 gap
      width: 26.0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _CellData {
  final DateTime date;
  final double opacity;
  final bool isToday;
  final bool isFuture;

  const _CellData({
    required this.date,
    required this.opacity,
    required this.isToday,
    required this.isFuture,
  });
}

class _YearlyHeatMapPainter extends CustomPainter {
  final List<List<_CellData>> columns;
  final Color baseColor;

  _YearlyHeatMapPainter({
    required this.columns,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cellSize = 12.0;
    const double cellGap = 3.0;
    const double radius = 2.5;

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black87;

    for (int col = 0; col < columns.length; col++) {
      final double x = col * (cellSize + cellGap);
      final colData = columns[col];

      for (int row = 0; row < colData.length; row++) {
        final double y = row * (cellSize + cellGap);
        final cell = colData[row];

        final RRect rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          const Radius.circular(radius),
        );

        if (cell.isFuture) {
          fillPaint.color = Colors.grey.withValues(alpha: 0.08);
        } else if (cell.opacity > 0) {
          fillPaint.color = baseColor.withValues(alpha: cell.opacity);
        } else {
          fillPaint.color = baseColor.withValues(alpha: 0.08);
        }

        canvas.drawRRect(rrect, fillPaint);

        if (cell.isToday) {
          canvas.drawRRect(rrect, borderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _YearlyHeatMapPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor || oldDelegate.columns != columns;
  }
}
