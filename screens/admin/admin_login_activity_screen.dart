import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/session_service.dart';
import '../../services/theme_service.dart';

class AdminLoginActivityScreen extends StatelessWidget {
  final String uid;
  final String userName;

  const AdminLoginActivityScreen({
    super.key,
    required this.uid,
    required this.userName,
  });

  Future<void> _confirmSignOut(
    BuildContext context,
    AppThemeColors theme,
    String sessionId,
    String deviceLabel,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out this device?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: theme.textPrimary)),
        content: Text(
          '"$deviceLabel" will be signed out of $userName\'s account '
          'immediately.',
          style: GoogleFonts.poppins(fontSize: 13, color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade500),
            child: Text('Sign Out',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await SessionService().revokeSession(uid, sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = SessionService();

    return ThemeAware(
      builder: (context, theme) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.accent),
            title: Text('$userName\'s Login Activity',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.accent)),
            centerTitle: true,
          ),
          body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: sessionService.streamActiveSessions(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: theme.accent));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Could not load login activity.',
                        style:
                            GoogleFonts.poppins(color: theme.textSecondary)));
              }
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text('No active sessions for this account.',
                      style: GoogleFonts.poppins(color: theme.textSecondary)),
                );
              }

              final sorted = docs.toList()
                ..sort((a, b) {
                  DateTime resolve(dynamic v) =>
                      v is Timestamp ? v.toDate() : DateTime.now();
                  return resolve(b.data()['lastSeenAt'])
                      .compareTo(resolve(a.data()['lastSeenAt']));
                });

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14, left: 4),
                    child: Text(
                      'Every device currently signed in to this account.',
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: theme.textSecondary),
                    ),
                  ),
                  ...sorted.map((doc) {
                    final data = doc.data();
                    final deviceLabel =
                        (data['deviceLabel'] ?? 'Unknown device').toString();
                    final Timestamp? lastSeen = data['lastSeenAt'];
                    final Timestamp? createdAt = data['createdAt'];
                    final timeLabel = lastSeen != null
                        ? DateFormat('dd/MM/yyyy hh:mm a')
                            .format(lastSeen.toDate())
                        : createdAt != null
                            ? DateFormat('dd/MM/yyyy hh:mm a')
                                .format(createdAt.toDate())
                            : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.accent.withValues(alpha: 0.10)),
                        boxShadow: [
                          BoxShadow(
                              color: theme.accent
                                  .withValues(alpha: theme.isDark ? 0.14 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: theme.accent
                                  .withValues(alpha: theme.isDark ? 0.18 : 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              deviceLabel.toLowerCase().contains('android') ||
                                      deviceLabel
                                          .toLowerCase()
                                          .contains('iphone')
                                  ? Icons.smartphone_rounded
                                  : deviceLabel
                                          .toLowerCase()
                                          .contains('web')
                                      ? Icons.language_rounded
                                      : Icons.laptop_mac_rounded,
                              color: theme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(deviceLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textPrimary)),
                                const SizedBox(height: 2),
                                Text(timeLabel,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: theme.textSecondary)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _confirmSignOut(
                                context, theme, doc.id, deviceLabel),
                            child: Text('Sign Out',
                                style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade400)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
