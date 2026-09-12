import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/app_notification_service.dart';
import '../../services/theme_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppNotificationService _service = AppNotificationService();

  @override
  void initState() {
    super.initState();

    _service.enforceRetention();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'feedback_reply':
        return Icons.feedback_rounded;
      case 'admin_message':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'feedback_reply':
        return const Color(0xFF10B981);
      case 'admin_message':
        return const Color(0xFFE91E8C);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  List<QueryDocumentSnapshot> _sortedNewestFirst(
      List<QueryDocumentSnapshot> docs) {
    DateTime resolve(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    final sorted = List<QueryDocumentSnapshot>.from(docs);
    sorted.sort((a, b) {
      final da = (a.data() as Map<String, dynamic>)['createdAt'];
      final db = (b.data() as Map<String, dynamic>)['createdAt'];
      return resolve(db).compareTo(resolve(da));
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDarkMode;
    final bg = isDark ? const Color(0xFF1A0D1E) : const Color(0xFFFFF0F5);
    final cardColor = isDark ? const Color(0xFF2A1A2E) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFF5E6F5) : const Color(0xFF3D1A2E);
    final subColor = isDark ? const Color(0xFFB08AB8) : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: titleColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w600, color: titleColor)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: titleColor),
            tooltip: 'Mark all as read',
            onPressed: () => _service.markAllAsRead(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.streamMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE91E8C)));
          }
          if (snapshot.hasError) {
            debugPrint(
                'NotificationsScreen: streamMyNotifications error: ${snapshot.error}');
            return Center(
              child: Text('Something went wrong.',
                  style: GoogleFonts.poppins(color: subColor)),
            );
          }
          final docs = _sortedNewestFirst(snapshot.data?.docs ?? []);
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_rounded,
                      size: 56, color: Colors.pink.shade100),
                  const SizedBox(height: 12),
                  Text('No notifications yet',
                      style:
                          GoogleFonts.poppins(color: subColor, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool read = data['read'] ?? false;
              final String type = data['type'] ?? 'admin_message';
              final String title = data['title'] ?? '';
              final String body = data['body'] ?? '';
              final Timestamp? ts = data['createdAt'];
              final String timeLabel = ts != null
                  ? DateFormat('dd/MM/yyyy hh:mm a').format(ts.toDate())
                  : '';
              final color = _colorFor(type);

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) => _service.deleteNotification(doc.id),
                child: GestureDetector(
                  onTap: () {
                    if (!read) _service.markAsRead(doc.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: read
                          ? null
                          : Border.all(color: color.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_iconFor(type), color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: read
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                  if (!read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(body,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.5, color: subColor)),
                              const SizedBox(height: 6),
                              Text(timeLabel,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.5, color: subColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
