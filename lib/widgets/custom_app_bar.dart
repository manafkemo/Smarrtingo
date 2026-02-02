import 'package:flutter/material.dart';

import '../utils/theme.dart';
import '../screens/profile_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/emergency_mode/emergency_mode_screen.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentTab;
  const CustomAppBar({super.key, this.currentTab = 0});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.primary, size: 28),
        onPressed: () {
          // TODO: Implement drawer or menu action
        },
      ),
      actions: [
        // Emergency Mode Button
        IconButton(
          icon: const Icon(Icons.crisis_alert_rounded, color: Colors.deepOrangeAccent, size: 28),
          tooltip: 'Emergency Mode',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencyModeScreen()),
            );
          },
        ),
        // Stats Icon
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(initialTab: currentTab),
              ),
            );
          },
        ),
        // Notification Icon
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 28),
          onPressed: () {
            // TODO: Implement notifications
          },
        ),
        const SizedBox(width: 8),
        // Profile Icon
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0E0E0), // Placeholder color for avatar
                  border: Border.all(color: AppColors.secondary, width: 2), // Ring effect
                ),
                child: ClipOval(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                  // Note: In a real app, use Image.network or Image.asset here
                  // child: Image.asset('assets/images/avatar.png', fit: BoxFit.cover), 
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
