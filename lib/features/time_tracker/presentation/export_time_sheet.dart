import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/time_export_service.dart';
import '../domain/duration_format.dart';
import '../domain/time_export.dart';

/// Export sheet for the Time page: pick Day / Week / Month around the day
/// being viewed, pick Markdown or JSON, share. The file is built from Isar
/// alone, so airplane mode is indistinguishable from online; the only
/// "failure" is the user dismissing the share sheet.
///
/// Pro gating (later): read `TierGate.canExportTimeLog` here and swap the
/// Share button for the upgrade pill — nothing else changes.
Future<void> showExportTimeSheet(
  BuildContext context, {
  required DateTime anchor,
  TimeExportScope initialScope = TimeExportScope.day,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfacePanel,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    routeSettings: const RouteSettings(name: ExportTimeSheet.routeName),
    builder: (_) => ExportTimeSheet(anchor: anchor, initialScope: initialScope),
  );
}

class ExportTimeSheet extends ConsumerStatefulWidget {
  const ExportTimeSheet({
    super.key,
    required this.anchor,
    this.initialScope = TimeExportScope.day,
  });

  static const routeName = '/time/export';

  /// The day the Time page is showing; the scope widens around it.
  final DateTime anchor;
  final TimeExportScope initialScope;

  @override
  ConsumerState<ExportTimeSheet> createState() => _ExportTimeSheetState();
}

class _ExportTimeSheetState extends ConsumerState<ExportTimeSheet> {
  late TimeExportScope _scope = widget.initialScope;
  TimeExportFormat _format = TimeExportFormat.markdown;
  TimeExport? _preview;
  bool _sharing = false;

  TimeExportPeriod get _period =>
      TimeExportPeriod.around(_scope, widget.anchor);

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final period = _period;
    final export = await ref.read(timeExportServiceProvider).build(period);
    if (!mounted || period.key != _period.key) return;
    setState(() => _preview = export);
  }

  void _setScope(TimeExportScope scope) {
    if (scope == _scope) return;
    setState(() {
      _scope = scope;
      _preview = null;
    });
    _loadPreview();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final file = await ref
          .read(timeExportServiceProvider)
          .render(_period, _format);
      await ref.read(shareTimeExportProvider)(file);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share the export. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final period = _period;
    final canShare = preview != null && !preview.isEmpty && !_sharing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Export time log'),
          const SizedBox(height: 6),
          Text(
            'Share a file for another AI, a spreadsheet, or your notes. '
            'Only what you logged — nothing is uploaded.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          const _MicroLabel('Period'),
          const SizedBox(height: 8),
          SegmentedButton<TimeExportScope>(
            key: const ValueKey('time_export_scope'),
            segments: const [
              ButtonSegment(value: TimeExportScope.day, label: Text('Day')),
              ButtonSegment(value: TimeExportScope.week, label: Text('Week')),
              ButtonSegment(value: TimeExportScope.month, label: Text('Month')),
            ],
            selected: {_scope},
            showSelectedIcon: false,
            onSelectionChanged: (s) => _setScope(s.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Column(
              key: ValueKey(period.key),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.label,
                  key: const ValueKey('time_export_period_label'),
                  style: TextStyle(
                    color: AppColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _previewLine(preview),
                  key: const ValueKey('time_export_preview'),
                  style: TextStyle(color: AppColors.textSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const _MicroLabel('Format'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                key: const ValueKey('time_export_format_markdown'),
                label: const Text('Markdown · for AI & notes'),
                selected: _format == TimeExportFormat.markdown,
                onSelected: (_) =>
                    setState(() => _format = TimeExportFormat.markdown),
              ),
              ChoiceChip(
                key: const ValueKey('time_export_format_json'),
                label: const Text('JSON · for apps'),
                selected: _format == TimeExportFormat.json,
                onSelected: (_) =>
                    setState(() => _format = TimeExportFormat.json),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              key: const ValueKey('time_export_share'),
              onPressed: canShare ? _share : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(
                _sharing ? 'Preparing…' : 'Share',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _previewLine(TimeExport? preview) {
    if (preview == null) return 'Reading your log…';
    if (preview.isEmpty) return 'Nothing logged in this period.';
    final b = StringBuffer(
      'Logged ${formatActivityDuration(preview.logged)}',
    );
    if (preview.days.length > 1) {
      b.write(
        ' across ${preview.daysWithEntries} of ${preview.days.length} days',
      );
    }
    if (preview.untracked > Duration.zero) {
      b.write(' · untracked ${formatActivityDuration(preview.untracked)}');
    }
    return b.toString();
  }
}

class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppColors.textSoft,
      ),
    );
  }
}
