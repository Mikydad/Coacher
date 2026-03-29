import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/models/accountability_log.dart';
import '../domain/models/flow_transition_event.dart';

class AccountabilityHistoryScreen extends ConsumerStatefulWidget {
  const AccountabilityHistoryScreen({super.key});

  static const routeName = '/accountability-history';

  @override
  ConsumerState<AccountabilityHistoryScreen> createState() => _AccountabilityHistoryScreenState();
}

class _AccountabilityHistoryScreenState extends ConsumerState<AccountabilityHistoryScreen> {
  DateTimeRange? _range;
  String? _modeRefId;
  OverrideReasonCategory? _reason;
  bool _loading = false;
  List<AccountabilityLog> _logs = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final repo = ref.read(planningRepositoryProvider);
    final result = await repo.getAccountabilityLogs(
      fromCreatedAtMs: _range?.start.millisecondsSinceEpoch,
      toCreatedAtMs: _range?.end.millisecondsSinceEpoch,
      modeRefId: _modeRefId,
      reasonCategory: _reason,
    );
    if (!mounted) return;
    setState(() {
      _logs = result;
      _loading = false;
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (selected == null) return;
    setState(() => _range = selected);
    await _reload();
  }

  Future<void> _deleteOne(String id) async {
    await ref.read(planningRepositoryProvider).deleteAccountabilityLog(id);
    await _reload();
  }

  Future<void> _deleteRange() async {
    if (_range == null) return;
    await ref.read(planningRepositoryProvider).deleteAccountabilityLogsInRange(
          fromCreatedAtMs: _range!.start.millisecondsSinceEpoch,
          toCreatedAtMs: _range!.end.millisecondsSinceEpoch,
        );
    await _reload();
  }

  Future<void> _export(String format) async {
    final raw = await ref.read(planningRepositoryProvider).exportAccountabilityLogs(format: format);
    final pretty = format == 'json'
        ? const JsonEncoder.withIndent('  ').convert(jsonDecode(raw) as Object)
        : raw;
    await Clipboard.setData(ClipboardData(text: pretty));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${format.toUpperCase()} copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountability History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _export,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'json', child: Text('Export JSON')),
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(_range == null ? 'Filter date' : 'Date filtered'),
                ),
                DropdownButton<String?>(
                  value: _modeRefId,
                  hint: const Text('Mode'),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('All modes')),
                    DropdownMenuItem<String?>(value: 'flexible', child: Text('Flexible')),
                    DropdownMenuItem<String?>(value: 'disciplined', child: Text('Disciplined')),
                    DropdownMenuItem<String?>(value: 'extreme', child: Text('Extreme')),
                  ],
                  onChanged: (v) async {
                    setState(() => _modeRefId = v);
                    await _reload();
                  },
                ),
                DropdownButton<OverrideReasonCategory?>(
                  value: _reason,
                  hint: const Text('Reason'),
                  items: [
                    const DropdownMenuItem<OverrideReasonCategory?>(
                      value: null,
                      child: Text('All reasons'),
                    ),
                    ...OverrideReasonCategory.values.map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.storageValue)),
                    ),
                  ],
                  onChanged: (v) async {
                    setState(() => _reason = v);
                    await _reload();
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _range == null ? null : _deleteRange,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Delete date range'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No accountability logs found.'))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final l = _logs[index];
                          final dt = DateTime.fromMillisecondsSinceEpoch(l.createdAtMs);
                          return ListTile(
                            title: Text('${l.action.storageValue} • ${l.reasonCategory.storageValue}'),
                            subtitle: Text('${l.reasonNote}\n${dt.toLocal()}'),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteOne(l.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
