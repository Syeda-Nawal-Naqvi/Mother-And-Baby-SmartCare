import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/app_widgets.dart';

enum _FieldKind { text, number, dropdown }

class _FieldConfig {
  final String key;
  final String label;
  final _FieldKind kind;
  final List<String>? options;

  const _FieldConfig({
    required this.key,
    required this.label,
    this.kind = _FieldKind.text,
    this.options,
  });
}

class MotherRecordsGraphsScreen extends StatelessWidget {
  const MotherRecordsGraphsScreen({super.key});

  static const double _kMaxContentWidth = 640;

  static final List<_MotherModule> _modules = [
    _MotherModule(
      title: 'Weight',
      iconPath: 'assets/icons/weight.png',
      fallbackIcon: Icons.monitor_weight_rounded,
      color: const Color.fromARGB(255, 20, 228, 96),
      collection: 'mother_weight',
      field: 'weight',
      unit: 'kg',
    ),
    _MotherModule(
      title: 'Blood Pressure',
      iconPath: 'assets/icons/blood_pressure.png',
      fallbackIcon: Icons.monitor_heart_rounded,
      color: const Color.fromARGB(255, 237, 53, 154),
      collection: 'blood_pressure',
      field: 'systolic',
      unit: '',
      isBloodPressure: true,
    ),
    _MotherModule(
      title: 'Glucose Level',
      iconPath: 'assets/icons/glucose.png',
      fallbackIcon: Icons.bloodtype_rounded,
      color: const Color(0xFF3B82F6),
      collection: 'glucose',
      field: 'glucoseLevel',
      unit: 'mg/dL',
      extraFields: const [
        _FieldConfig(
          key: 'fastingStatus',
          label: 'Status',
          kind: _FieldKind.dropdown,
          options: ['Fasting', 'Not Fasting'],
        ),
      ],
    ),
    _MotherModule(
      title: 'Medical History',
      iconPath: 'assets/icons/medical_report.png',
      fallbackIcon: Icons.healing_rounded,
      color: const Color.fromARGB(255, 255, 221, 0),
      collection: 'medical_history',
      field: 'diseaseName',
      unit: '',
      isNumber: false,
      extraFields: const [
        _FieldConfig(key: 'medicines', label: 'Medicines'),
        _FieldConfig(key: 'status', label: 'Status'),
      ],
    ),
  ];

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
            title: Text(
              'Mother Records & Graphs',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9C1458),
              ),
            ),
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _kMaxContentWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1,
                          ),
                          itemCount: _modules.length,
                          itemBuilder: (context, index) {
                            final m = _modules[index];
                            return _SquareModuleCard(
                              title: m.title,
                              iconPath: m.iconPath,
                              fallbackIcon: m.fallbackIcon,
                              accentColor: m.color,
                              theme: theme,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _MotherModuleDetailScreen(module: m),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MotherModule {
  final String title;
  final String iconPath;
  final IconData fallbackIcon;
  final Color color;
  final String collection;
  final String field;
  final String unit;
  final bool isNumber;
  final bool isBloodPressure;
  final List<_FieldConfig> extraFields;

  const _MotherModule({
    required this.title,
    required this.iconPath,
    required this.fallbackIcon,
    required this.color,
    required this.collection,
    required this.field,
    required this.unit,
    this.isNumber = true,
    this.isBloodPressure = false,
    this.extraFields = const [],
  });
}

class _SquareModuleCard extends StatefulWidget {
  final String title;
  final String iconPath;
  final IconData fallbackIcon;
  final Color accentColor;
  final AppThemeColors theme;
  final VoidCallback onTap;

  const _SquareModuleCard({
    required this.title,
    required this.iconPath,
    required this.fallbackIcon,
    required this.accentColor,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_SquareModuleCard> createState() => _SquareModuleCardState();
}

class _SquareModuleCardState extends State<_SquareModuleCard> {
  bool _hover = false;
  bool _pressed = false;
  bool _opening = false;

  bool get _active => _hover || _pressed || _opening;

  Future<void> _handleTap() async {
    setState(() {
      _pressed = false;
      _opening = true;
    });
    await Future.delayed(const Duration(milliseconds: 190));
    if (!mounted) return;
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _opening ? 1.10 : (_pressed ? 0.96 : 1.0);
    final isDark = widget.theme.isDark;

    final restColor = isDark
        ? Color.alphaBlend(
            widget.accentColor.withValues(alpha: 0.12),
            widget.theme.surface,
          )
        : Colors.white;
    final activeColor = isDark
        ? Color.alphaBlend(
            widget.accentColor.withValues(alpha: 0.24),
            widget.theme.surface,
          )
        : Color.alphaBlend(
            widget.accentColor.withValues(alpha: 0.08),
            Colors.white,
          );
    final baseColor = _active ? activeColor : restColor;
    final tileColor = isDark ? widget.theme.surfaceAlt : Colors.white;

    final shadowColor = isDark
        ? widget.accentColor.withValues(
            alpha: _active ? (_opening ? 0.70 : 0.58) : 0.30,
          )
        : (_active
            ? widget.accentColor.withValues(alpha: _opening ? 0.55 : 0.42)
            : Colors.black.withValues(alpha: 0.10));
    final shadowBlur = isDark
        ? (_opening ? 40.0 : (_active ? 32.0 : 22.0))
        : (_opening ? 34.0 : (_active ? 26.0 : 16.0));
    final shadowSpread = isDark
        ? (_opening ? 4.0 : (_active ? 3.0 : 1.5))
        : (_opening ? 3.0 : (_active ? 2.0 : 0.5));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => _handleTap(),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: _opening ? 190 : 150),
          curve: _opening ? Curves.easeOutBack : Curves.easeOut,
          transform: Matrix4.identity()
            ..scaleByDouble(scale, scale, 1.0, 1.0)
            ..translateByDouble(
                0.0, _hover && !_pressed && !_opening ? -3.0 : 0.0, 0.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: shadowBlur,
                offset: _active ? const Offset(0, 10) : const Offset(0, 6),
                spreadRadius: shadowSpread,
              ),
            ],
            border: Border.all(
              color: _active
                  ? widget.accentColor.withValues(alpha: 0.4)
                  : (isDark
                      ? widget.accentColor.withValues(alpha: 0.20)
                      : Colors.transparent),
              width: 1.4,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _active ? 68 : 62,
                    height: _active ? 68 : 62,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(
                            alpha: isDark ? 0.45 : 0.32,
                          ),
                          blurRadius: isDark ? 18 : 14,
                          offset: const Offset(0, 4),
                          spreadRadius: isDark ? 1.0 : 0.5,
                        ),
                      ],
                      border: Border.all(
                        color: widget.accentColor.withValues(
                          alpha: isDark ? 0.28 : 0.18,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      widget.iconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        widget.fallbackIcon,
                        color: widget.accentColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

DateTime? _parseCreatedAt(dynamic when) {
  if (when is Timestamp) return when.toDate();
  if (when is String) return DateTime.tryParse(when);
  return null;
}

class _MotherModuleDetailScreen extends StatelessWidget {
  final _MotherModule module;
  const _MotherModuleDetailScreen({required this.module});

  static const double _kMaxContentWidth = 640;

  @override
  Widget build(BuildContext context) {
    return ThemeAware(
      builder: (context, theme) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: module.color),
            title: Text(
              module.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _kMaxContentWidth),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (module.isBloodPressure) ...[
                          Text(
                            'Systolic Trend',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SingleFieldTrendChart(
                            collection: module.collection,
                            field: 'systolic',
                            color: module.color,
                            theme: theme,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Diastolic Trend',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SingleFieldTrendChart(
                            collection: module.collection,
                            field: 'diastolic',
                            color: const Color(0xFF7C3AED),
                            theme: theme,
                          ),
                          const SizedBox(height: 22),
                        ] else if (module.isNumber) ...[
                          Text(
                            'Trend',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SingleFieldTrendChart(
                            collection: module.collection,
                            field: module.field,
                            color: module.color,
                            theme: theme,
                          ),
                          const SizedBox(height: 22),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: module.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: module.color.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: module.color, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Medical history entries are text-based, so no trend graph is shown here.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                        Text(
                          'Records',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 420,
                          child: AppRecordStreamList(
                            collection: module.collection,
                            emptyMessage: 'No ${module.title} records yet',
                            emptyIcon: module.fallbackIcon,
                            itemBuilder: (context, data, id, pending) {
                              final createdAt =
                                  _parseCreatedAt(data['createdAt']);

                              if (module.isBloodPressure) {
                                final subtitle = createdAt != null
                                    ? DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(createdAt)
                                    : '';
                                return _HoverRecordWrap(
                                  accentColor: module.color,
                                  child: AppRecordCard(
                                    icon: module.fallbackIcon,
                                    color: module.color,
                                    title:
                                        'BP: ${data['systolic']}/${data['diastolic']}',
                                    subtitle: subtitle,
                                    onEdit: () => _showEditRecordDialog(
                                      context: context,
                                      theme: theme,
                                      title: 'Blood Pressure',
                                      color: module.color,
                                      fields: [
                                        _EditField(
                                          key: 'systolic',
                                          label: 'Systolic',
                                          initialValue: (data['systolic'] ?? '')
                                              .toString(),
                                          kind: _FieldKind.number,
                                        ),
                                        _EditField(
                                          key: 'diastolic',
                                          label: 'Diastolic',
                                          initialValue:
                                              (data['diastolic'] ?? '')
                                                  .toString(),
                                          kind: _FieldKind.number,
                                        ),
                                      ],
                                      initialDateTime:
                                          createdAt ?? DateTime.now(),
                                      onSave: (values) =>
                                          FirestoreService.update(
                                              module.collection, id, values),
                                    ),
                                    onDelete: () => FirestoreService.delete(
                                        module.collection, id),
                                    pendingSync: pending,
                                  ),
                                );
                              }

                              final valueText = module.unit.isNotEmpty
                                  ? '${data[module.field] ?? ''} ${module.unit}'
                                  : '${data[module.field] ?? ''}';

                              final extraParts = module.extraFields
                                  .map((f) =>
                                      '${f.label}: ${data[f.key] ?? '-'}')
                                  .join(' • ');

                              final dateStr = createdAt != null
                                  ? (module.title == 'Weight'
                                      ? DateFormat('dd MMM yyyy')
                                          .format(createdAt)
                                      : DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(createdAt))
                                  : '';

                              final subtitle = extraParts.isNotEmpty
                                  ? '$dateStr\n$extraParts'
                                  : dateStr;

                              final title = module.isNumber
                                  ? '${module.title}: $valueText'.trim()
                                  : (data[module.field]?.toString() ??
                                      module.title);

                              return _HoverRecordWrap(
                                accentColor: module.color,
                                child: AppRecordCard(
                                  icon: module.fallbackIcon,
                                  color: module.color,
                                  title: title,
                                  subtitle: subtitle,
                                  onEdit: () => _showEditRecordDialog(
                                    context: context,
                                    theme: theme,
                                    title: module.title,
                                    color: module.color,
                                    fields: [
                                      _EditField(
                                        key: module.field,
                                        label: module.unit.isNotEmpty
                                            ? '${module.title} (${module.unit})'
                                            : module.title,
                                        initialValue: (data[module.field] ?? '')
                                            .toString(),
                                        kind: module.isNumber
                                            ? _FieldKind.number
                                            : _FieldKind.text,
                                      ),
                                      for (final f in module.extraFields)
                                        _EditField(
                                          key: f.key,
                                          label: f.label,
                                          initialValue: (data[f.key] ??
                                                  (f.options != null
                                                      ? f.options!.first
                                                      : ''))
                                              .toString(),
                                          kind: f.kind,
                                          options: f.options,
                                        ),
                                    ],
                                    initialDateTime:
                                        createdAt ?? DateTime.now(),
                                    onSave: (values) => FirestoreService.update(
                                        module.collection, id, values),
                                  ),
                                  onDelete: () => FirestoreService.delete(
                                      module.collection, id),
                                  pendingSync: pending,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoverRecordWrap extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  const _HoverRecordWrap({required this.child, required this.accentColor});

  @override
  State<_HoverRecordWrap> createState() => _HoverRecordWrapState();
}

class _HoverRecordWrapState extends State<_HoverRecordWrap> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : (_hover ? 1.02 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 10),
          transform: Matrix4.identity()
            ..scaleByDouble(scale, scale, 1.0, 1.0)
            ..translateByDouble(0.0, _hover ? -2.0 : 0.0, 0.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    widget.accentColor.withValues(alpha: _hover ? 0.30 : 0.0),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SingleFieldTrendChart extends StatelessWidget {
  final String collection;
  final String field;
  final Color color;
  final AppThemeColors theme;

  const _SingleFieldTrendChart({
    required this.collection,
    required this.field,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.isDark;
    final stream = FirestoreService.stream(collection, descending: false);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator(color: color)),
          );
        }
        final docs = snapshot.data!.docs;
        final values = <double>[];
        final labels = <String>[];
        final dateTimes = <DateTime?>[];
        for (final d in docs) {
          final data = d.data();
          if (data[field] == null) continue;
          values.add(double.tryParse(data[field].toString()) ?? 0);
          final dt = _parseCreatedAt(data['createdAt']);
          dateTimes.add(dt);
          labels.add(dt != null ? DateFormat('d MMM').format(dt) : '');
        }
        if (values.isEmpty) {
          return const AppEmptyState(
              message: 'No data yet', icon: Icons.show_chart_rounded);
        }
        return Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.30 : 0.18),
                blurRadius: isDark ? 22 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) =>
                      color.withValues(alpha: isDark ? 0.92 : 0.95),
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    final dt = idx >= 0 && idx < dateTimes.length
                        ? dateTimes[idx]
                        : null;
                    final timeStr =
                        dt != null ? DateFormat('hh:mm a').format(dt) : '';
                    return LineTooltipItem(
                      '${s.y.toStringAsFixed(0)}\n$timeStr',
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval:
                        (values.length / 4).clamp(1, values.length).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                      show: true, color: color.withValues(alpha: 0.14)),
                  spots: [
                    for (int i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditField {
  final String key;
  final String label;
  final String initialValue;
  final _FieldKind kind;
  final List<String>? options;
  const _EditField({
    required this.key,
    required this.label,
    required this.initialValue,
    this.kind = _FieldKind.text,
    this.options,
  });
}

Future<void> _showEditRecordDialog({
  required BuildContext context,
  required AppThemeColors theme,
  required String title,
  required Color color,
  required List<_EditField> fields,
  DateTime? initialDateTime,
  required Future<void> Function(Map<String, dynamic> values) onSave,
}) async {
  final controllers = {
    for (final f in fields.where((f) => f.kind != _FieldKind.dropdown))
      f.key: TextEditingController(text: f.initialValue),
  };
  final dropdownValues = {
    for (final f in fields.where((f) => f.kind == _FieldKind.dropdown))
      f.key: f.initialValue,
  };
  DateTime? selectedDateTime = initialDateTime;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit $title',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: theme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedDateTime != null) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDateTime!,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate == null || !ctx.mounted) return;
                    final pickedTime = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime!),
                    );
                    if (pickedTime == null || !ctx.mounted) return;
                    setStateDialog(() {
                      selectedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, color: color, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM yyyy, hh:mm a')
                                .format(selectedDateTime!),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.edit_calendar_rounded,
                            color: theme.textSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              for (final f in fields) ...[
                if (f.kind == _FieldKind.dropdown)
                  DropdownButtonFormField<String>(
                    initialValue: dropdownValues[f.key],
                    items: f.options!
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => setStateDialog(
                        () => dropdownValues[f.key] = v ?? f.options!.first),
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: theme.textPrimary),
                    decoration: InputDecoration(
                      labelText: f.label,
                      labelStyle:
                          GoogleFonts.poppins(color: theme.textSecondary),
                      filled: true,
                      fillColor: theme.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 1.5),
                      ),
                    ),
                  )
                else
                  TextField(
                    controller: controllers[f.key],
                    keyboardType: f.kind == _FieldKind.number
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: theme.textPrimary),
                    decoration: InputDecoration(
                      labelText: f.label,
                      labelStyle:
                          GoogleFonts.poppins(color: theme.textSecondary),
                      filled: true,
                      fillColor: theme.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color, width: 1.5),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final values = <String, dynamic>{};
              for (final f in fields) {
                if (f.kind == _FieldKind.dropdown) {
                  values[f.key] = dropdownValues[f.key];
                  continue;
                }
                final text = controllers[f.key]!.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('${f.label} cannot be empty')));
                  return;
                }
                if (f.kind == _FieldKind.number) {
                  final parsed = double.tryParse(text);
                  if (parsed == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text('${f.label} must be a valid number')));
                    return;
                  }
                  values[f.key] = parsed;
                } else {
                  values[f.key] = text;
                }
              }
              if (selectedDateTime != null) {
                values['createdAt'] = Timestamp.fromDate(selectedDateTime!);
              }
              Navigator.pop(ctx);
              await onSave(values);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
