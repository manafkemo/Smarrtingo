import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../widgets/pomodoro_timer.dart';
import '../providers/timer_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'timer_completion_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  // Timer State
  Timer? _timer;
  Duration _duration = const Duration(minutes: 5, seconds: 0); // Default 5 min
  Duration _remainingTime = const Duration(minutes: 5, seconds: 0);
  bool _isRunning = false;
  bool _isSetupMode = true;

  // Celebration
  late ConfettiController _confettiController;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _audioPlayer = AudioPlayer();
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency); // Low-latency mode
    _audioPlayer.audioCache.prefix = ''; // Use custom prefix
    _audioPlayer.setSource(AssetSource('assist/audio/done.mp3')); // Pre-load
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isSetupMode = false;
      _isRunning = true;
      _remainingTime = _duration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        _playDoneCelebration();
      }
    });
  }
  
  void _playDoneCelebration() {
    _confettiController.play();
    _audioPlayer.stop().then((_) {
      _audioPlayer.play(AssetSource('assist/audio/done.mp3'));
    });
    
    // Navigate to completion screen after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (mounted) {
         final xp = _calculateXP(_duration);
         final result = await Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => TimerCompletionScreen(
               focusedDuration: _duration,
               xpEarned: xp,
             ),
           ),
         );

         if (mounted) {
            if (result == true) {
              // Start Break (5 min)
              setState(() {
                _duration = const Duration(minutes: 5);
                _startTimer();
              });
            } else {
              // Seamless restart: Reset to setup mode with same duration
              _resetTimer();
            }
         }
      }
    });
  }
  
  int _calculateXP(Duration duration) {
    // Basic calculation: 10 XP per minute
    return duration.inMinutes * 10;
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
         _playDoneCelebration();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isSetupMode = true;
      _remainingTime = _duration;
    });
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed, required Color color, required Color iconColor}) {
      return InkWell(
         onTap: onPressed,
         borderRadius: BorderRadius.circular(30),
         child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
               color: color,
               shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
         ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Confetti Layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF0F5257),
                Color(0xFFC8F3F0),
                Color(0xFF8DBFAF),
                Colors.yellow,
                Colors.pink,
              ],
            ),
          ),
          // --- Decorations ---
          // Top Left Light Blob
          Positioned(
            top: 50,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                  color: const Color(0xFFC8F3F0).withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Top Right Light Accent
          Positioned(
            top: 80,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: const Color(0xFFC8F3F0).withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
           // Bottom Left Large Light Blob
          Positioned(
            bottom: -20,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                  color: const Color(0xFFC8F3F0).withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom Right Dark Arc
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFF0F5257),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // --- Main Content ---
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Center(
                  child: _buildPomodoroView(timerProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroView(TimerProvider timerProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Task Type Button
        InkWell(
          onTap: () => _showTaskTypeDialog(timerProvider),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F5257),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  timerProvider.taskType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 50),

        // Pomodoro Timer Widget
        PomodoroTimer(
            duration: _remainingTime,
            totalDuration: _duration,
            isSetupMode: _isSetupMode,
            onDurationChanged: (val) {
               setState(() {
                  _duration = val;
                  _remainingTime = val;
               });
            },
            size: 320,
        ),
        
        const SizedBox(height: 30),
        
        Text(
          "Drag The Handle to Adjust Time",
          style: TextStyle(
            color: const Color(0xFF0F5257).withValues(alpha: 0.5),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 60),

        // Controls (Reset, Start/Pause, Sound)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Reset
            Column(
              children: [
                 _buildCircleButton(
                    icon: Icons.replay,
                    onPressed: _resetTimer,
                    color: const Color(0xFFC8F3F0),
                    iconColor: const Color(0xFF0F5257),
                 ),
                 const SizedBox(height: 8),
                 Text("RESET", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F5257).withValues(alpha: 0.8))),
              ],
            ),
            const SizedBox(width: 40),
            
            // Start/Pause
            Column(
              children: [
                 SizedBox(
                  width: 80,
                  height: 80,
                  child: FloatingActionButton(
                     onPressed: _isSetupMode ? _startTimer : (_isRunning ? _pauseTimer : _resumeTimer),
                     backgroundColor: const Color(0xFF0F5257),
                     shape: const CircleBorder(),
                     elevation: 8,
                     child: Icon(
                        _isSetupMode 
                           ? Icons.play_arrow 
                           : (_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        size: 40,
                        color: Colors.white,
                     ),
                  ),
                 ),
                 const SizedBox(height: 8),
                 Text("START", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F5257).withValues(alpha: 0.8))),
              ],
            ),

            const SizedBox(width: 40),

            // Sound
            Column(
              children: [
                 _buildCircleButton(
                    icon: Icons.volume_up_rounded,
                    onPressed: () {
                       // Toggle sound
                    },
                    color: const Color(0xFFC8F3F0),
                    iconColor: const Color(0xFF0F5257),
                 ),
                 const SizedBox(height: 8),
                 Text("SOUND", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F5257).withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  final TextEditingController _taskController = TextEditingController();

  void _showTaskTypeDialog(TimerProvider timerProvider) {
    _taskController.text = timerProvider.taskType;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What are you focusing on?"),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter task type...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              timerProvider.setTaskType(_taskController.text.isEmpty ? "Focus Session" : _taskController.text);
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}
