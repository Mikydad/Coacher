import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/page_headers.dart';
import 'commitment_card.dart';

/// Card Preview (FR-10…FR-12): shows the commitment card full-bleed, lets the
/// user flip story ↔ square, and hands a 1080-wide PNG to the native share
/// sheet. Everything is local — this screen must never wait on the network,
/// and skipping the share changes nothing about the challenge (FR-11, Q3).
class CardPreviewScreen extends StatefulWidget {
  const CardPreviewScreen({super.key, required this.data, this.onRecommit});

  final CommitmentCardData data;

  /// FR-17 — shown on failure cards: opens the create flow pre-filled with
  /// the same commitment so the miss turns into a recommitment.
  final VoidCallback? onRecommit;

  @override
  State<CardPreviewScreen> createState() => _CardPreviewScreenState();
}

class _CardPreviewScreenState extends State<CardPreviewScreen> {
  final _boundaryKey = GlobalKey();
  CommitmentCardAspect _aspect = CommitmentCardAspect.story;
  bool _sharing = false;
  bool _saving = false;

  (String, String) get _copy => switch (widget.data.state) {
    CommitmentCardState.pledge => (
      'Your pledge card',
      'Share it. Show how much you care about your goals.',
    ),
    CommitmentCardState.success => (
      'Your victory card',
      'You called your shot and hit it. Let them see.',
    ),
    CommitmentCardState.failure => (
      'Your card',
      'Own it, share it, and come back stronger.',
    ),
  };

  /// Logical 360x640 (or 360x360) x 3 -> 1080x1920 / 1080x1080 (FR-12).
  Future<Uint8List?> _capturePng() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  String get _exportName {
    final suffix = _aspect == CommitmentCardAspect.story ? 'story' : 'square';
    return 'sidepal_${widget.data.state.name}_$suffix';
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final png = await _capturePng();
      if (png == null) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: '$_exportName.png',
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not prepare the card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// OQ-2 - Save to Photos. gal throws GalException on denied access; the
  /// message stays honest and local.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final png = await _capturePng();
      if (png == null) return;
      await Gal.putImageBytes(png, name: _exportName);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved to Photos.')));
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.type == GalExceptionType.accessDenied
                  ? 'Photos access is off - allow it in Settings to save '
                        'cards.'
                  : 'Could not save the card: ${e.type.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save the card: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _aspectPill(String label, CommitmentCardAspect value) {
    final selected = _aspect == value;
    return GestureDetector(
      onTap: () => setState(() => _aspect = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.inkCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.fg12,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSoft,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (title, nudge) = _copy;
    final size = _aspect == CommitmentCardAspect.story
        ? CommitmentCard.storySize
        : CommitmentCard.squareSize;
    return Scaffold(
      appBar: AppBar(title: PageTitle(title)),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _aspectPill('STORY', CommitmentCardAspect.story),
                const SizedBox(width: 10),
                _aspectPill('SQUARE', CommitmentCardAspect.square),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: FittedBox(
                    key: ValueKey(_aspect),
                    fit: BoxFit.contain,
                    // The boundary keeps the card's LOGICAL size regardless
                    // of on-screen scaling, so the capture is always exact;
                    // textScaler is pinned so accessibility font settings
                    // can't reflow the card (FR-12).
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: TextScaler.noScaling),
                          child: CommitmentCard(
                            data: widget.data,
                            aspect: _aspect,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                nudge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _sharing ? null : _share,
                        icon: _sharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded, size: 20),
                        label: Text(_sharing ? 'Preparing…' : 'Share'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _save,
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onRecommit != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: widget.onRecommit,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Recommit — round two'),
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Not now',
                style: TextStyle(color: AppColors.textSoft),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
