import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';
import '../../services/theme_service.dart';
import '../../utils/countries.dart';
import 'admin_login_activity_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  final String? initialRoleFilter;
  const AdminUsersScreen({super.key, this.initialRoleFilter});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  late String _roleFilter = widget.initialRoleFilter ?? '';

  static const List<Map<String, String>> _roleTabs = [
    {'value': '', 'label': 'All'},
    {'value': 'mother', 'label': 'Mothers'},
    {'value': 'father', 'label': 'Fathers'},
    {'value': 'caretaker', 'label': 'Caretakers'},
    {'value': 'admin', 'label': 'Admins'},
  ];

  String? get _myUid => _adminService.currentUid;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'father':
        return 'Father';
      case 'caretaker':
        return 'Caretaker';
      default:
        return 'Mother';
    }
  }

  Color _roleColor(String role, AppThemeColors theme) {
    switch (role) {
      case 'admin':
        return const Color(0xFF8B5CF6);
      case 'father':
        return const Color(0xFF3B82F6);
      case 'caretaker':
        return const Color(0xFFF59E0B);
      default:
        return theme.accent;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'father':
        return Icons.man_rounded;
      case 'caretaker':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.pregnant_woman_rounded;
    }
  }

  String? _roleAvatarAsset(String role) {
    switch (role) {
      case 'father':
        return 'assets/icons/father.png';
      case 'caretaker':
        return 'assets/icons/caretaker.png';
      case 'mother':
        return 'assets/icons/woman.png';
      default:
        return null;
    }
  }

  Future<void> _toggleBlock(
      String uid, bool currentlyBlocked, String name) async {
    try {
      await _adminService.setUserBlocked(uid, !currentlyBlocked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(currentlyBlocked ? '$name unblocked.' : '$name blocked.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showCountryBreakdown(AppThemeColors theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StreamBuilder<Map<String, int>>(
            stream: _adminService.streamUserCountsByCountry(),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? {};
              final entries = counts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final total = entries.fold<int>(0, (s, e) => s + e.value);

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Users by Country',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimary)),
                        ),
                        Text('$total total',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: theme.textSecondary)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? Center(
                            child:
                                CircularProgressIndicator(color: theme.accent))
                        : entries.isEmpty
                            ? Center(
                                child: Text('No users yet',
                                    style: GoogleFonts.poppins(
                                        color: theme.textSecondary)))
                            : ListView.builder(
                                controller: scrollCtrl,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                itemCount: entries.length,
                                itemBuilder: (context, i) {
                                  final e = entries[i];
                                  final flag = e.key == 'Unknown'
                                      ? '🏳️'
                                      : countryByName(e.key).flag;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Text(flag.isEmpty ? '🏳️' : flag,
                                            style:
                                                const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(e.key,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.textPrimary)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.accent
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text('${e.value}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: theme.accent)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      AppThemeColors theme, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove this user?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: theme.textPrimary)),
        content: Text(
          'This permanently deletes all of "$name"\'s data — their profile, '
          'baby/mother profiles, and health records — and blocks their '
          'login. This cannot be undone.',
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
            child:
                Text('Remove', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteUserAccount(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('"$name" removed.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeAware(
      builder: (context, theme) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.accent),
            title: Text('Manage Users',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.accent)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.public_rounded, color: theme.accent),
                tooltip: 'Users by country',
                onPressed: () => _showCountryBreakdown(theme),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: theme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: GoogleFonts.poppins(color: theme.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 20, color: theme.accent),
                    filled: true,
                    fillColor: theme.surfaceAlt,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: theme.accent, width: 1.4)),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _roleTabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final tab = _roleTabs[i];
                    final selected = _roleFilter == tab['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _roleFilter = tab['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? theme.accent : theme.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected ? theme.accent : theme.border),
                        ),
                        child: Center(
                          child: Text(
                            tab['label']!,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? Colors.white : theme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _adminService.streamAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child:
                              CircularProgressIndicator(color: theme.accent));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Could not load users.',
                              style: GoogleFonts.poppins(
                                  color: theme.textSecondary)));
                    }
                    var docs = snapshot.data?.docs ?? [];
                    if (_roleFilter.isNotEmpty) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final role = AdminService.normalizeRole(data['role']);
                        return role == _roleFilter;
                      }).toList();
                    }
                    if (_query.isNotEmpty) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final name =
                            (data['name'] ?? '').toString().toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        return name.contains(_query) || email.contains(_query);
                      }).toList();
                    }

                    docs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTs = aData['createdAt'];
                      final bTs = bData['createdAt'];
                      if (aTs is! Timestamp && bTs is! Timestamp) return 0;
                      if (aTs is! Timestamp) return 1;
                      if (bTs is! Timestamp) return -1;
                      return bTs.compareTo(aTs);
                    });
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: theme.accent.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.people_outline_rounded,
                                  size: 40, color: theme.accent),
                            ),
                            const SizedBox(height: 12),
                            Text('No users found',
                                style: GoogleFonts.poppins(
                                    color: theme.textSecondary, fontSize: 14)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        final name = (data['name'] ?? 'Unknown').toString();
                        final email = (data['email'] ?? '').toString();
                        final role = AdminService.normalizeRole(data['role']);
                        final blocked = data['blocked'] == true;
                        final blockedBy = (data['blockedBy'] ?? '').toString();
                        final country = (data['country'] ?? '').toString();
                        final isMe = uid == _myUid;
                        final roleColor = _roleColor(role, theme);
                        final avatarAsset = _roleAvatarAsset(role);

                        final isLegacyRecord = data['createdAt'] is! Timestamp;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: blocked
                                ? Border.all(
                                    color: Colors.red.withValues(alpha: 0.4))
                                : Border.all(
                                    color:
                                        theme.accent.withValues(alpha: 0.12)),
                            boxShadow: [
                              BoxShadow(
                                  color: theme.accent.withValues(
                                      alpha: theme.isDark ? 0.12 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        roleColor.withValues(alpha: 0.16),
                                    child: avatarAsset != null
                                        ? ClipOval(
                                            child: Image.asset(
                                              avatarAsset,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(_roleIcon(role),
                                                      color: roleColor,
                                                      size: 18),
                                            ),
                                          )
                                        : Icon(_roleIcon(role),
                                            color: roleColor, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          theme.textPrimary)),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 6),
                                              Text('(You)',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color:
                                                          theme.textSecondary)),
                                            ],
                                          ],
                                        ),
                                        Text(email,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: theme.textSecondary)),
                                        if (country.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  countryByName(country)
                                                          .flag
                                                          .isEmpty
                                                      ? '🏳️'
                                                      : countryByName(country)
                                                          .flag,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(country,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 11.5,
                                                        color: theme
                                                            .textSecondary)),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (isLegacyRecord) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  Icons
                                                      .history_toggle_off_rounded,
                                                  size: 12,
                                                  color:
                                                      Colors.orange.shade400),
                                              const SizedBox(width: 4),
                                              Text(
                                                'No signup date — likely test/legacy data',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 10.5,
                                                    color:
                                                        Colors.orange.shade400),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _roleLabel(role),
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: roleColor),
                                    ),
                                  ),
                                ],
                              ),
                              if (blocked) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.block_rounded,
                                        size: 14, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                        blockedBy == 'self'
                                            ? 'Blocked — user locked this '
                                                'account (suspicious login)'
                                            : 'Blocked by admin',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: Colors.red.shade300)),
                                  ],
                                ),
                              ],
                              if (!isMe) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _toggleBlock(uid, blocked, name),
                                        icon: Icon(
                                            blocked
                                                ? Icons.lock_open_rounded
                                                : Icons.block_rounded,
                                            size: 16),
                                        label: Text(
                                            blocked ? 'Unblock' : 'Block',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: blocked
                                              ? const Color(0xFF10B981)
                                              : Colors.orange.shade400,
                                          side: BorderSide(
                                              color: blocked
                                                  ? const Color(0xFF10B981)
                                                  : Colors.orange.shade400),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AdminLoginActivityScreen(
                                                  uid: uid, userName: name),
                                        ),
                                      ),
                                      icon: Icon(Icons.devices_other_rounded,
                                          color: theme.accent),
                                      tooltip: 'View login activity',
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _confirmDelete(theme, uid, name),
                                      icon: Icon(Icons.delete_outline_rounded,
                                          color: Colors.red.shade400),
                                      tooltip: 'Remove user',
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
