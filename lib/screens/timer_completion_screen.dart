import 'package:flutter/material.dart';
 // Assuming AppColors exists here, or I'll use raw values if needed.

class TimerCompletionScreen extends StatelessWidget {
  final Duration focusedDuration;
  final int xpEarned;

  const TimerCompletionScreen({
    super.key,
    required this.focusedDuration,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFC8F3F0).withValues(alpha: 0.3),
              const Color(0xFFE0F7FA).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorations (dots/blobs) - simplified for now
             Positioned(
              top: 100,
              left: 40,
              child: _buildDot(6, const Color(0xFF0F5257).withValues(alpha: 0.4)),
            ),
             Positioned(
              top: 250,
              right: 60,
              child: _buildDot(12, const Color(0xFF8DBFAF).withValues(alpha: 0.4)),
            ),
             Positioned(
              bottom: 150,
              right: 40,
              child: _buildDot(8, Colors.grey.withValues(alpha: 0.3)),
            ),

            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Stack
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC8F3F0),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 60,
                            color: Color(0xFF0F5257),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F5257),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Text
                  const Text(
                    "Great job!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5257),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "You've earned it. Take a quick break before your next task to recharge.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Stats Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50), // Pill shape
                      border: Border.all(color: const Color(0xFFC8F3F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFABC0BF).withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Left Side
                          Container(
                             width: 48,
                             height: 48,
                             decoration: BoxDecoration(
                               color: const Color(0xFFC8F3F0), // Light Teal Icon BG
                               shape: BoxShape.circle,
                             ),
                             child: const Icon(Icons.timer_outlined, color: Color(0xFF0F5257), size: 24),
                           ),
                           const SizedBox(width: 16),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                Text(
                                  "${focusedDuration.inMinutes}m",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F5257), // Dark Teal
                                  ),
                                ),
                                const Text(
                                  "DEEP FOCUS",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8DBFAF), // Medium Teal
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                             ],
                           ),
                           
                           const Spacer(),
                           
                           // Divider
                           Container(
                             width: 1,
                             height: 40,
                             color: const Color(0xFFC8F3F0), // Light Teal Divider
                           ),
                           
                           const Spacer(),
                           
                           // Right Side
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.center,
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                Text(
                                  "+$xpEarned",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F5257),
                                  ),
                                ),
                                const Text(
                                  "XP EARNED",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8DBFAF),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                             ],
                           ),
                           const SizedBox(width: 16), // Balance visual weight
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Buttons
                  if (focusedDuration.inMinutes >= 25)
                     Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: SizedBox(
                           width: double.infinity,
                           height: 56,
                           child: ElevatedButton.icon(
                             onPressed: () {
                                // Start Break
                                Navigator.pop(context, true); 
                             },
                             icon: const Icon(Icons.coffee, color: Colors.white),
                             label: const Text("Start Break", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF0F5257),
                               foregroundColor: Colors.white,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(30),
                               ),
                               elevation: 5,
                             ),
                           ),
                        ),
                     ),
                  
                  const SizedBox(height: 16),
                  
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    icon: const Text("", style: TextStyle(fontSize: 0)), // Hack to center text if needed, or just TextButton
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          focusedDuration.inMinutes >= 25 ? "Skip Break" : "Go back to timer",
                          style: const TextStyle(color: Color(0xFF0F5257), fontWeight: FontWeight.bold, fontSize: 15)
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F5257), size: 18),
                      ],
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

  Widget _buildDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
