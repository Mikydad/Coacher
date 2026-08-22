import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/memory_providers.dart';
import '../domain/models/memory_fact.dart';
import '../domain/models/person.dart';

/// "What SidePal knows" (PRD §5.4) — the transparency surface for long-term
/// memory. Three tabs: Facts (everything remembered, provenance-labeled),
/// People (who SidePal knows about), Timeline (episodic summaries).
/// Every fact is correctable (✓), editable (✏) and forgettable (🗑);
/// "Forget everything" nukes the lot. All actions are Isar-first — they
/// work identically in airplane mode.
class MemoryKnowledgeScreen extends ConsumerStatefulWidget {
  const MemoryKnowledgeScreen({super.key});

  static const routeName = '/memory-knowledge';

  @override
  ConsumerState<MemoryKnowledgeScreen> createState() =>
      _MemoryKnowledgeScreenState();
}

class _MemoryKnowledgeScreenState extends ConsumerState<MemoryKnowledgeScreen> {
  bool _handledHighlight = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledHighlight) return;
    _handledHighlight = true;
    // A "from your memory" chip navigates here with the fact id — open
    // that fact's sheet so the tap answers "what exactly do you know?".
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && arg.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final fact = await ref.read(memoryFactsRepositoryProvider).getFact(arg);
        if (fact != null && mounted) {
          _showFactSheet(context, ref, fact);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const PageTitle('What SidePal knows'),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.cyan,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.fg54,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
            tabs: const [
              Tab(text: 'FACTS'),
              Tab(text: 'PEOPLE'),
              Tab(text: 'TIMELINE'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_FactsTab(), _PeopleTab(), _TimelineTab()],
        ),
      ),
    );
  }
}

// ─── Facts tab ────────────────────────────────────────────────────────────────

class _FactsTab extends ConsumerWidget {
  const _FactsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(memoryFactsStreamProvider).valueOrNull ?? const [];
    final facts = all
        .where((f) => f.kind != MemoryFactKind.episodicSummary)
        .toList(growable: false);

    if (facts.isEmpty) {
      return const _EmptyState(
        'Nothing remembered yet.\nTell Coach "remember that…" — or just talk; '
        'SidePal learns quietly and labels every guess.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfacePanel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.fg12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < facts.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.fg12),
                _FactRow(fact: facts[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => _confirmForgetEverything(context, ref),
            icon: Icon(
              Icons.delete_sweep_outlined,
              size: 18,
              color: AppColors.danger,
            ),
            label: Text(
              'Forget everything',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmForgetEverything(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfacePanel,
        title: Text(
          'Forget everything?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'SidePal will forget every remembered fact — people and '
          'conversation summaries included. This cannot be undone.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Forget everything',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final facts = ref.read(memoryFactsRepositoryProvider);
    final people = ref.read(peopleRepositoryProvider);
    await facts.deleteAllFacts();
    for (final p
        in ref.read(peopleStreamProvider).valueOrNull ?? const <Person>[]) {
      await people.deletePerson(p.id);
    }
  }
}

class _FactRow extends ConsumerWidget {
  const _FactRow({required this.fact});

  final MemoryFact fact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showFactSheet(context, ref, fact),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fact.content,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _ProvenanceBadge(provenance: fact.provenance),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _kindLabel(fact.kind),
                    style: TextStyle(color: AppColors.fg54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fact detail sheet ────────────────────────────────────────────────────────

void _showFactSheet(BuildContext context, WidgetRef ref, MemoryFact fact) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.content,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ProvenanceBadge(provenance: fact.provenance),
              const SizedBox(width: 8),
              Text(
                _kindLabel(fact.kind),
                style: TextStyle(color: AppColors.fg54, fontSize: 11),
              ),
            ],
          ),
          if (fact.sourceQuote != null && fact.sourceQuote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fg12.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '"${fact.sourceQuote}"',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              if (!fact.isAsserted) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await ref
                          .read(memoryFactsRepositoryProvider)
                          .confirmFact(fact.id);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Correct'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showFactEditSheet(context, ref, fact);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await ref
                        .read(memoryFactsRepositoryProvider)
                        .deleteFact(fact.id);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Forget'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void _showFactEditSheet(BuildContext context, WidgetRef ref, MemoryFact fact) {
  final controller = TextEditingController(text: fact.content);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EDIT FACT',
            style: TextStyle(
              color: AppColors.fg54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: controller,
            autofocus: true,
            maxLength: 200,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.fg12.withValues(alpha: 0.06),
              counterStyle: TextStyle(color: AppColors.fg54, fontSize: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isEmpty) return;
                Navigator.of(sheetContext).pop();
                // An edit is the strongest correction signal — the result
                // is user-confirmed truth, full confidence.
                await ref
                    .read(memoryFactsRepositoryProvider)
                    .upsertFact(
                      fact.copyWith(
                        content: content,
                        provenance: MemoryProvenance.userConfirmed,
                        confidence: 1.0,
                        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── People tab ───────────────────────────────────────────────────────────────

class _PeopleTab extends ConsumerWidget {
  const _PeopleTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleStreamProvider).valueOrNull ?? const [];

    if (people.isEmpty) {
      return const _EmptyState(
        'No one yet.\nWhen you mention people — "my sister Sarah" — '
        'SidePal remembers who they are, never their data.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfacePanel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.fg12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < people.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.fg12),
                _PersonRow(person: people[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends ConsumerWidget {
  const _PersonRow({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rel = person.relationship?.trim();
    return InkWell(
      onTap: () => _showPersonSheet(context, ref, person),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.fg12,
              child: Text(
                person.displayName.isEmpty
                    ? '?'
                    : person.displayName[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.displayName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (rel != null && rel.isNotEmpty) rel,
                      _lastInteractionLabel(person.lastInteractionAtMs),
                    ].join(' · '),
                    style: TextStyle(color: AppColors.fg54, fontSize: 12),
                  ),
                ],
              ),
            ),
            _ProvenanceBadge(provenance: person.provenance),
          ],
        ),
      ),
    );
  }

  static String _lastInteractionLabel(int? ms) {
    if (ms == null) return 'no interaction recorded';
    final days = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ms))
        .inDays;
    if (days <= 0) return 'interacted today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}

void _showPersonSheet(BuildContext context, WidgetRef ref, Person person) {
  final nameController = TextEditingController(text: person.displayName);
  final relController = TextEditingController(text: person.relationship ?? '');
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERSON',
            style: TextStyle(
              color: AppColors.fg54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: AppColors.fg54, fontSize: 13),
              filled: true,
              fillColor: AppColors.fg12.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: relController,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Relationship (your words)',
              hintText: 'my sister, cofounder…',
              hintStyle: TextStyle(color: AppColors.fg54),
              labelStyle: TextStyle(color: AppColors.fg54, fontSize: 13),
              filled: true,
              fillColor: AppColors.fg12.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(sheetContext).pop();
                    final rel = relController.text.trim();
                    await ref
                        .read(peopleRepositoryProvider)
                        .upsertPerson(
                          person.copyWith(
                            displayName: name,
                            relationship: rel.isEmpty ? null : rel,
                            kind: normalizeRelationship(
                              rel.isEmpty ? null : rel,
                            ),
                            provenance: MemoryProvenance.userConfirmed,
                            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
                          ),
                        );
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await ref
                        .read(peopleRepositoryProvider)
                        .deletePerson(person.id);
                  },
                  child: const Text('Forget'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ─── Timeline tab ─────────────────────────────────────────────────────────────

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(memoryFactsStreamProvider).valueOrNull ?? const [];
    final summaries =
        all
            .where((f) => f.kind == MemoryFactKind.episodicSummary)
            .toList(growable: false)
          ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

    if (summaries.isEmpty) {
      return const _EmptyState(
        'No conversation summaries yet.\nAfter you chat with Coach, the gist '
        'is kept here — the raw transcript is purged.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final fact = summaries[index];
        final day = DateTime.fromMillisecondsSinceEpoch(fact.createdAtMs);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showFactSheet(context, ref, fact),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfacePanel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.fg12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
                    '${day.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: AppColors.fg54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fact.content,
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared pieces ────────────────────────────────────────────────────────────

class _ProvenanceBadge extends StatelessWidget {
  const _ProvenanceBadge({required this.provenance});

  final MemoryProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (provenance) {
      MemoryProvenance.userStated => ('STATED', AppColors.cyan),
      MemoryProvenance.userConfirmed => ('CONFIRMED', AppColors.cyan),
      MemoryProvenance.derivedDeterministic => ('OBSERVED', AppColors.fg70),
      MemoryProvenance.aiInferred => ('INFERRED', AppColors.amber),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

String _kindLabel(MemoryFactKind kind) => switch (kind) {
  MemoryFactKind.semanticFact => 'Fact',
  MemoryFactKind.preference => 'Preference',
  MemoryFactKind.learnedPattern => 'Pattern',
  MemoryFactKind.episodicSummary => 'Conversation summary',
  MemoryFactKind.promiseNote => 'Promise note',
  MemoryFactKind.observation => 'On your radar',
};
