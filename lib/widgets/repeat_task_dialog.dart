import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';


class RepeatTaskDialog extends StatefulWidget {
  final RepeatConfig? initialConfig;

  const RepeatTaskDialog({super.key, this.initialConfig});

  @override
  State<RepeatTaskDialog> createState() => _RepeatTaskDialogState();
}

class _RepeatTaskDialogState extends State<RepeatTaskDialog> {
  late RepeatFrequency _frequency;
  late List<int> _repeatOn;
  late List<int> _repeatMonths;
  late int _interval;
  late DateTime? _endDate;
  late int? _occurrences;

  // Selection for "Ends"
  int _endSelection = 0; // 0: Never, 1: On Date, 2: After occurrences

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _frequency = widget.initialConfig!.frequency;
      _repeatOn = List.from(widget.initialConfig!.repeatOn);
      _repeatMonths = List.from(widget.initialConfig!.repeatMonths);
      _interval = widget.initialConfig!.interval;
      _endDate = widget.initialConfig!.endDate;
      _occurrences = widget.initialConfig!.occurrences;

      if (_endDate != null) {
        _endSelection = 1;
      } else if (_occurrences != null) {
        _endSelection = 2;
      } else {
        _endSelection = 0;
      }
    } else {
      _frequency = RepeatFrequency.daily;
      _repeatOn = [];
      _repeatMonths = [];
      _interval = 1;
      _endDate = null;
      _occurrences = null;
      _endSelection = 0;
    }
  }

  void _save() {
    final config = RepeatConfig(
      frequency: _frequency,
      repeatOn: _frequency == RepeatFrequency.weekly ? _repeatOn : [],
      repeatMonths: _frequency == RepeatFrequency.yearly ? _repeatMonths : [],
      interval: _interval,
      endDate: _endSelection == 1 ? (_endDate ?? DateTime.now().add(const Duration(days: 30))) : null,
      occurrences: _endSelection == 2 ? (_occurrences ?? 10) : null,
    );
    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Repeat Task',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF0F5257)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Frequency
                    const Text(
                      'FREQUENCY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFrequencySelector(),
                    const SizedBox(height: 24),

                    // Repeat On (Only for Weekly)
                    if (_frequency == RepeatFrequency.weekly) ...[
                      const Text(
                        'REPEAT ON',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildWeekdaySelector(),
                      const SizedBox(height: 24),
                    ],

                    // Repeat On Months (Only for Yearly)
                    if (_frequency == RepeatFrequency.yearly) ...[
                      const Text(
                        'REPEAT ON MONTHS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMonthSelector(),
                      const SizedBox(height: 24),
                    ],

                    // Interval
                    const Text(
                      'INTERVAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildIntervalSelector(),
                    const SizedBox(height: 24),

                    // Ends
                    const Text(
                      'ENDS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEndsSelector(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save Button (Fixed at bottom)
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5257),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Save Repeat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Row(
      children: RepeatFrequency.values.map((f) {
        final isSelected = _frequency == f;
        String label = f.name.substring(0, 1).toUpperCase() + f.name.substring(1);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _frequency = f),
            child: Container(
              margin: EdgeInsets.only(right: f == RepeatFrequency.yearly ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F5257) : const Color(0xFFD9F4F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0F5257),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekdaySelector() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final dayNum = index + 1;
          final isSelected = _repeatOn.contains(dayNum);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _repeatOn.remove(dayNum);
                } else {
                  _repeatOn.add(dayNum);
                }
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F5257) : const Color(0xFFD9F4F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0F5257),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthNum = index + 1;
          final isSelected = _repeatMonths.contains(monthNum);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _repeatMonths.remove(monthNum);
                } else {
                  _repeatMonths.add(monthNum);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F5257) : const Color(0xFFD9F4F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  shortMonths[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0F5257),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntervalSelector() {
    String unit = '';
    switch (_frequency) {
      case RepeatFrequency.daily: unit = 'day'; break;
      case RepeatFrequency.weekly: unit = 'week'; break;
      case RepeatFrequency.monthly: unit = 'month'; break;
      case RepeatFrequency.yearly: unit = 'year'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            'Repeat every',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (_interval > 1) setState(() => _interval--);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  )
                ],
              ),
              child: const Icon(Icons.remove, size: 20, color: Color(0xFF0F5257)),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '$_interval',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F5257),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => setState(() => _interval++),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  )
                ],
              ),
              child: const Icon(Icons.add, size: 20, color: Color(0xFF0F5257)),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            unit,
            style: const TextStyle(
              color: Color(0xFFACB9B9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndsSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildEndOption(0, 'Never'),
          const Divider(height: 1, color: Color(0xFFF1F3F3)),
          _buildEndOption(1, 'On Date', 
            subtitle: _endDate != null ? DateFormat('MMM d, y').format(_endDate!) : 'Select Date'),
          const Divider(height: 1, color: Color(0xFFF1F3F3)),
          _buildEndOption(2, 'After occurrences', 
            subtitle: '${_occurrences ?? 10} times'),
        ],
      ),
    );
  }

  Widget _buildEndOption(int value, String title, {String? subtitle}) {
    final isSelected = _endSelection == value;
    return InkWell(
      onTap: () async {
        setState(() => _endSelection = value);
        if (value == 1) {
          final picked = await showDatePicker(
            context: context,
            initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(),
            lastDate: DateTime(2101),
          );
          if (picked != null) setState(() => _endDate = picked);
        } else if (value == 2) {
          final result = await showDialog<int>(
            context: context,
            builder: (context) => OccurrencesDialog(initialOccurrences: _occurrences ?? 10),
          );
          if (result != null) {
            setState(() {
               _occurrences = result;
               _endSelection = 2;
            });
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFACB9B9),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F5257) : const Color(0xFFD9F4F0),
                  width: 2,
                ),
              ),
              child: isSelected 
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F5257),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
            ),
          ],
        ),
      ),
    );
  }
}

class OccurrencesDialog extends StatefulWidget {
  final int initialOccurrences;

  const OccurrencesDialog({super.key, required this.initialOccurrences});

  @override
  State<OccurrencesDialog> createState() => _OccurrencesDialogState();
}

class _OccurrencesDialogState extends State<OccurrencesDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialOccurrences;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'After Occurrences',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircleButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (_count > 1) setState(() => _count--);
                  },
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '$_count',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F5257),
                      ),
                    ),
                    const Text(
                      'TIMES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFACB9B9),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                _buildCircleButton(
                  icon: Icons.add,
                  onTap: () => setState(() => _count++),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Task will repeat for a total of\n$_count times then stop.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFACB9B9),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _count),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5257),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Set occurrences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFACB9B9),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFD9F4F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0F5257), size: 28),
      ),
    );
  }
}
