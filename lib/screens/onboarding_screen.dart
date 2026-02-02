import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_button.dart';
import '../widgets/onboarding_background.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start at a large index to allow scrolling back and forth "infinitely"
    _pageController = PageController(initialPage: 1000);
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Restart timer on hot reload so the new 5s interval takes effect immediately
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _onAutoScroll();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _onAutoScroll() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  // Color Palette
  static const Color mainColor = Color(0xFF0F5257);


  final List<Map<String, String>> _pages = [
    {
      'title': 'AI Breakdown Ideas',
      'body': 'Let AI help you deconstruct complex goals into manageable steps.',
      'image': 'AI_break_down_ideas.png',
    },
    {
      'title': 'To-Do List',
      'body': 'Stay organized and keep track of your daily tasks effortlessly.',
      'image': 'to_do_list.png',
    },
    {
      'title': 'Calendar View',
      'body': 'Visualize your schedule and plan ahead with the calendar view.',
      'image': 'calender_view.png',
    },
    {
      'title': 'Habit Tracker',
      'body': 'Build good habits and track your consistency over time.',
      'image': 'habit_tracker.png',
    },
    {
      'title': 'Pomodoro Timer',
      'body': 'Boost your productivity with focused work sessions using the Pomodoro technique.',
      'image': 'pomodoro_timer.png',
    },
  ];

  void _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorations
          const OnboardingBackground(),
          
          // Page Content
          Column(
            children: [
              Expanded(
                child: Listener(
                  onPointerDown: (_) => _stopTimer(),
                  onPointerUp: (_) => _startTimer(),
                  onPointerCancel: (_) => _startTimer(),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    // Infinite scroll: itemCount is null (default) or a very large number, 
                    // but usually keeping it null works if we control it.
                    // Actually, for PageView.builder, if itemCount is null, it's infinite.
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final page = _pages[index % _pages.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Image.asset(
                              'assist/images/${page['image']}',
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 40),
                            Text(
                              page['title']!,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: mainColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['body']!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = index == (_currentPage % _pages.length);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? mainColor : mainColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              
              // Bottom Section (Button)
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, left: 24, right: 24),
                child: CustomButton(
                  text: 'Get Started',
                  onTap: _onGetStarted,
                  color: mainColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
