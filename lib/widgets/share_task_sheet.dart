import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class ShareTaskSheet extends StatefulWidget {
  final Task task;

  const ShareTaskSheet({super.key, required this.task});

  @override
  State<ShareTaskSheet> createState() => _ShareTaskSheetState();
}

class _ShareTaskSheetState extends State<ShareTaskSheet> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _shareAsImage() async {
    try {
      final context = _globalKey.currentContext;
      if (context == null) {
        throw Exception('Share preview context not found');
      }

      final RenderRepaintBoundary boundary =
          context.findRenderObject() as RenderRepaintBoundary;
      
      // Wait a tiny bit to ensure it's painted if called immediately
      await Future.delayed(const Duration(milliseconds: 100));
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        await Share.shareXFiles(
          [XFile.fromData(pngBytes, name: 'smarttingo_goal.png', mimeType: 'image/png')],
          text: 'Check out my goal: ${widget.task.title}',
        );
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/smarttingo_goal.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Check out my goal: ${widget.task.title}',
        );
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate sharing image')),
      );
    }
  }

  String _getTaskSummary() {
    String summary = '📋 Goal: ${widget.task.title}\n';
    if (widget.task.description.isNotEmpty) {
      summary += '${widget.task.description}\n';
    }
    
    final progress = widget.task.subtasks.isEmpty 
        ? (widget.task.isCompleted ? 1.0 : 0.0)
        : widget.task.subtasks.where((s) => s.isCompleted).length / widget.task.subtasks.length;
    
    summary += 'Progress: ${(progress * 100).toInt()}%\n';

    if (widget.task.subtasks.isNotEmpty) {
      summary += '\nSteps:\n';
      for (var sub in widget.task.subtasks) {
        summary += '${sub.isCompleted ? '✅' : '⬜'} ${sub.title}\n';
      }
    }
    summary += '\nShared via Smarttingo';
    return summary;
  }

  void _shareAsChecklist() {
    Share.share(_getTaskSummary());
  }

  void _shareAsLink() {
    // Placeholder link logic
    final String link = 'https://smarttingo.app/task/${widget.task.id}';
    Share.share('Check out my goal on Smarttingo: $link');
  }

  void _shareSocial() {
    // For social icons, use the system share with the full summary
    Share.share(_getTaskSummary());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hidden Branded Preview for Capture - positioned off-screen to ensure it's painted
        Positioned(
          left: -1000,
          child: RepaintBoundary(
            key: _globalKey,
            child: _buildBrandedPreview(),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F5257),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF0F5257),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose how you'd like to share this goal",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B9E9E),
            ),
          ),
          const SizedBox(height: 24),


              _buildShareOption(
                icon: Icons.checklist_rounded,
                title: 'As Text',
                subtitle: 'Share a text summary of your goal',
                iconColor: const Color(0xFF01579B),
                backColor: const Color(0xFFE1F5FE),
                onTap: _shareAsChecklist,
              ),
              const SizedBox(height: 12),
              _buildShareOption(
                icon: Icons.image_outlined,
                title: 'As an Image',
                subtitle: 'Branded graphic with progress ring.',
                iconColor: const Color(0xFF7B1FA2),
                backColor: const Color(0xFFF3E5F5),
                onTap: _shareAsImage,
              ),
              const SizedBox(height: 12),
              _buildShareOption(
                icon: Icons.link_rounded,
                title: 'As a Link',
                subtitle: 'Direct access to this task in Smarttingo.',
                iconColor: const Color(0xFFBF360C),
                backColor: const Color(0xFFFFF8E1),
                onTap: _shareAsLink,
              ),
          
          const SizedBox(height: 32),
          const Text(
            'SHARE VIA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF0F5257),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialIcon('WhatsApp', FontAwesomeIcons.whatsapp, const Color(0xFF25D366), onTap: _shareSocial),
              _buildSocialIcon('Telegram', FontAwesomeIcons.telegram, const Color(0xFF0088CC), onTap: _shareSocial),
              _buildSocialIcon('Email', FontAwesomeIcons.envelope, const Color(0xFF8B9E9E), onTap: _shareSocial),
              _buildSocialIcon('More', Icons.more_horiz_rounded, const Color(0xFFE8EDED), onTap: _shareSocial),
            ],
          ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildBrandedPreview() {
    return Container(
      width: 400, // Adjusted width for better layout
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo + Title + Priority
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assist/images/smarttingo-logo.png',
                height: 48,
                width: 48,
              ),
              const SizedBox(width: 12),
              const Text(
                'Smarttingo',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.task.priority.color, // red, orange, green, gray
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.task.priority.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Task Title
          Text(
            widget.task.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),

          // Category Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1), // Light green box
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.task.category.name,
              style: const TextStyle(
                color: Color(0xFF0F5257),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description
          if (widget.task.description.isNotEmpty)
            Text(
              widget.task.description,
              style: const TextStyle(
                color: Color(0xFF616161),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 24),

          // Subtasks
          if (widget.task.subtasks.isNotEmpty) ...[
            ...widget.task.subtasks.map((subtask) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                   Icon(
                    subtask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: const Color(0xFF2196F3),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subtask.title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          const SizedBox(height: 40),
          
          // Footer: Date + Media Count
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF9E9E9E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(widget.task.date)}',
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.attach_file, color: Color(0xFF9E9E9E), size: 20),
              const SizedBox(width: 4),
              Text(
                '${widget.task.mediaPaths.length}',
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color backColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0F5F5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5257),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B9E9E),
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

  Widget _buildSocialIcon(String label, dynamic iconData, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Center(
                child: iconData is IconData
                    ? Icon(iconData, color: color, size: 28)
                    : const Icon(Icons.share, color: Colors.blue, size: 28), // Placeholder
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B9E9E),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
