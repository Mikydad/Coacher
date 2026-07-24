import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../memory/presentation/memory_knowledge_screen.dart';

// ─── User bubble ─────────────────────────────────────────────────────────────

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppColors.inkElevated,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(fontSize: 14, color: AppColors.fg),
        ),
      ),
    );
  }
}

// ─── Assistant bubble ─────────────────────────────────────────────────────────

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    // Grounding contract (humanizing Phase 2): the model cites memory as
    // "[mem:<id>]" markers. Strip them from the visible text and surface
    // one quiet "from your memory" chip instead — tapping opens the fact
    // in "What SidePal knows".
    final grounded = extractMemoryReferences(content);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              markdownLiteSpan(
                grounded.text,
                TextStyle(fontSize: 14, color: AppColors.textSoft),
              ),
            ),
            // One chip per distinct cited fact (P3-01) — a reply grounded
            // in several memories shows every source, not just the first.
            if (grounded.factIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final factId in grounded.factIds)
                      MemoryReferenceChip(factId: factId),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The quiet "from your memory" affordance — the user always sees WHY the
/// Coach knows something personal, and one tap shows the fact itself.
class MemoryReferenceChip extends StatelessWidget {
  const MemoryReferenceChip({super.key, required this.factId});

  final String factId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.pushNamed(
        context,
        MemoryKnowledgeScreen.routeName,
        arguments: factId,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.fg12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.fg54),
            const SizedBox(width: 5),
            Text(
              'From your memory',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.fg54,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result of stripping memory citations out of an assistant reply.
class GroundedMessage {
  const GroundedMessage({required this.text, required this.factIds});

  final String text;
  final List<String> factIds;
}

final RegExp _kMemMarker = RegExp(r'\s*\[mem:([A-Za-z0-9_-]+)(?:\|[^\]]*)?\]');

/// Extracts `[mem:<id>]` citation markers (with or without the `|label`
/// suffix the payload lines carry) and returns the cleaned display text
/// plus the referenced fact ids in order of first appearance.
GroundedMessage extractMemoryReferences(String content) {
  final ids = <String>[];
  final cleaned = content.replaceAllMapped(_kMemMarker, (m) {
    final id = m.group(1)!;
    if (!ids.contains(id)) ids.add(id);
    return '';
  });
  return GroundedMessage(
    text: cleaned.trim(),
    factIds: List.unmodifiable(ids),
  );
}

/// Renders the markdown-lite subset the Coach agent is allowed to produce:
/// `**bold**` and `- ` / `* ` / `1. ` list markers (converted to bullets).
/// Everything else passes through verbatim — no dependency needed.
@visibleForTesting
TextSpan markdownLiteSpan(String text, TextStyle baseStyle) {
  final bold = baseStyle.copyWith(
    fontWeight: FontWeight.w700,
    color: AppColors.fg,
  );

  final lines = text.split('\n');
  final children = <TextSpan>[];

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];

    // List markers → bullet dot.
    final listMatch = RegExp(r'^(\s*)([-*]|\d+\.)\s+').firstMatch(line);
    if (listMatch != null) {
      children.add(TextSpan(text: '${listMatch.group(1)}• ', style: baseStyle));
      line = line.substring(listMatch.end);
    }

    // Inline **bold** segments.
    var cursor = 0;
    for (final match in RegExp(r'\*\*(.+?)\*\*').allMatches(line)) {
      if (match.start > cursor) {
        children.add(
          TextSpan(text: line.substring(cursor, match.start), style: baseStyle),
        );
      }
      children.add(TextSpan(text: match.group(1), style: bold));
      cursor = match.end;
    }
    if (cursor < line.length) {
      children.add(TextSpan(text: line.substring(cursor), style: baseStyle));
    }
    if (i < lines.length - 1) {
      children.add(TextSpan(text: '\n', style: baseStyle));
    }
  }

  return TextSpan(children: children);
}

// ─── Loading indicator (thinking dots) ───────────────────────────────────────

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final begin = i * 0.2;
            final end = begin + 0.4;
            return AnimatedBuilder(
              animation: _controller,
              builder: (ctx, child) {
                final t = _controller.value;
                double opacity;
                if (t < begin) {
                  opacity = 0.3;
                } else if (t < end) {
                  opacity = 0.3 + 0.7 * ((t - begin) / 0.4);
                } else {
                  opacity =
                      1.0 - 0.7 * ((t - end) / (1.0 - end).clamp(0.01, 1.0));
                }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cyan.withValues(
                      alpha: opacity.clamp(0.3, 1.0),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
