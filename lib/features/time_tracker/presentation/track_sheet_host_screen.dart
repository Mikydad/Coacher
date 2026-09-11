import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';
import 'track_activity_sheet.dart';

/// A near-invisible host route for the capture sheet, so a notification tap
/// ("30m are up. What are you doing now?") can land on the sheet even on a
/// cold start through the same queue-then-flush path every other tap uses.
/// It opens the sheet on its first frame and pops itself once the sheet
/// closes — the user never sees this page as a page.
class TrackSheetHostScreen extends StatefulWidget {
  const TrackSheetHostScreen({super.key});

  static const routeName = '/track';

  @override
  State<TrackSheetHostScreen> createState() => _TrackSheetHostScreenState();
}

class _TrackSheetHostScreenState extends State<TrackSheetHostScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showTrackActivitySheet(
        context,
        presetStartMs: DateTime.now().millisecondsSinceEpoch,
      );
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.ink, body: const SizedBox());
  }
}
