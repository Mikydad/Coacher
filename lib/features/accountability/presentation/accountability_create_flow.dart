import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/tier/tier_providers.dart';
import '../../../core/utils/stable_id.dart';
import '../../community/application/circle_providers.dart';
import '../application/points_providers.dart';
import '../application/stake_functions.dart';
import '../application/stakes_providers.dart';
import '../domain/models/points.dart';
import '../domain/models/stake_challenge.dart';
import 'stake_challenge_detail_screen.dart';
import 'stake_photo_cache.dart';

/// The unified accountability creation flow (PRD 1.4). All three entry
/// points land here:
///  - goal/task editor → [prefilledTitle]
///  - Accountability hub → nothing prefilled
///  - circle → [prefilledCircleId]
///
/// Steps: category → commitment → details (skipped for practice) →
/// consent (photo/money) → pledge → review. Category comes FIRST
/// (decision log 2026-07-17): the flow opens on what's at stake, then
/// the commitment, then type-specific setup.
/// Multi-step back is intercepted (PopScope steps back, never exits
/// mid-flow); step changes animate (~260 ms).
Future<void> openAccountabilityCreateFlow(
  BuildContext context, {
  String? prefilledTitle,
  String? prefilledCircleId,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AccountabilityCreateFlow(
        prefilledTitle: prefilledTitle,
        prefilledCircleId: prefilledCircleId,
      ),
    ),
  );
}

class AccountabilityCreateFlow extends ConsumerStatefulWidget {
  const AccountabilityCreateFlow({
    super.key,
    this.prefilledTitle,
    this.prefilledCircleId,
  });

  final String? prefilledTitle;
  final String? prefilledCircleId;

  @override
  ConsumerState<AccountabilityCreateFlow> createState() =>
      _AccountabilityCreateFlowState();
}

enum _Step { category, commitment, details, consent, pledge, review }

/// What's on the line: photo (P1), h2h points (P2), money ($ — SIMULATED
/// until Stripe activates; debug builds only), practice.
enum _StakeChoice { photo, h2h, money, practice }

class _AccountabilityCreateFlowState
    extends ConsumerState<AccountabilityCreateFlow> {
  _Step _step = _Step.category;

  // Commitment
  late final TextEditingController _title =
      TextEditingController(text: widget.prefilledTitle ?? '');
  String _unitKind = 'minutes';
  int _unitTarget = 60;
  int _totalUnits = 7;
  String _mode = 'disciplined';

  // Stake
  _StakeChoice _stake = _StakeChoice.photo;
  String? _circleId;
  XFile? _photo;
  int _revealWindowMins = 60;
  // h2h (D5/D6, M-4)
  String? _opponentUid;
  int _h2hStake = 100;
  String? _charityId;
  String? _bothLoseCharityId;
  // solo money ($-1) — SIMULATED provider until Stripe is live
  int _moneyCents = 2000;
  String? _antiCharityId;

  bool get _isPractice => _stake == _StakeChoice.practice;
  bool get _isH2h => _stake == _StakeChoice.h2h;
  bool get _isMoney => _stake == _StakeChoice.money;

  // Consent + pledge
  bool _consentIsMe = false;
  bool _consentPosting = false;
  bool _consentAdult = false;
  late final TextEditingController _why = TextEditingController();

  // Create
  bool _creating = false;
  String? _createError;

  @override
  void initState() {
    super.initState();
    _circleId = widget.prefilledCircleId;
  }

  @override
  void dispose() {
    _title.dispose();
    _why.dispose();
    super.dispose();
  }

  // Category first (decision log 2026-07-17): pick WHAT'S on the line,
  // then describe the commitment, then the type-specific setup. Practice
  // has no setup, so it skips the details page.
  List<_Step> get _steps => [
        _Step.category,
        _Step.commitment,
        if (!_isPractice) _Step.details,
        if (_stake == _StakeChoice.photo || _isMoney) _Step.consent,
        _Step.pledge,
        _Step.review,
      ];

  void _goBack() {
    final order = _steps;
    final i = order.indexOf(_step);
    if (i > 0) setState(() => _step = order[i - 1]);
  }

  void _goNext() {
    final order = _steps;
    final i = order.indexOf(_step);
    if (i < order.length - 1) setState(() => _step = order[i + 1]);
  }

  int get _requiredUnits {
    final pct = switch (_mode) {
      'flexible' => 70,
      'extreme' => 100,
      _ => 85,
    };
    return ((_totalUnits * pct) + 99) ~/ 100;
  }

  int get _mercyTarget => (_unitTarget * 3 + 3) ~/ 4;

  bool get _stepValid => switch (_step) {
        _Step.commitment =>
          _title.text.trim().isNotEmpty && _unitTarget > 0 && _totalUnits > 0,
        _Step.category => true, // a card is always selected
        _Step.details => switch (_stake) {
            _StakeChoice.practice => true,
            _StakeChoice.photo => _circleId != null && _photo != null,
            _StakeChoice.h2h => _circleId != null &&
                _opponentUid != null &&
                _charityId != null &&
                _bothLoseCharityId != null,
            _StakeChoice.money => _antiCharityId != null,
          },
        _Step.consent => _isMoney
            ? _consentPosting && _consentAdult
            : _consentIsMe && _consentPosting && _consentAdult,
        _Step.pledge => _why.text.trim().isNotEmpty,
        _Step.review => !_creating,
      };

  @override
  Widget build(BuildContext context) {
    final atFirstStep = _steps.indexOf(_step) == 0;
    return PopScope(
      canPop: atFirstStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const PageTitle('New Challenge'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (atFirstStep) {
                Navigator.of(context).pop();
              } else {
                _goBack();
              }
            },
          ),
        ),
        body: Column(
          children: [
            _StepDots(current: _steps.indexOf(_step), total: _steps.length),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: _buildStep(),
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: _step == _Step.pledge
                    ? _HoldToCommitButton(
                        enabled: _stepValid,
                        onCommitted: () {
                          setState(_goNext);
                        },
                      )
                    : FilledButton(
                        onPressed: _stepValid
                            ? (_step == _Step.review ? _create : _goNext)
                            : null,
                        child: _creating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                _step == _Step.review
                                    ? 'Start the challenge'
                                    : 'Continue',
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
        _Step.category => _categoryStep(),
        _Step.commitment => _commitmentStep(),
        _Step.details => _detailsStep(),
        _Step.consent => _consentStep(),
        _Step.pledge => _pledgeStep(),
        _Step.review => _reviewStep(),
      };

  // ─── Step: commitment ──────────────────────────────────────────────────────

  Widget _commitmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('The commitment'),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          maxLength: 80,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'What will you do?',
            hintText: 'Read for my exams',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        _microLabel('MEASURED IN'),
        const SizedBox(height: 8),
        Row(
          children: [
            _choiceChip('Minutes', _unitKind == 'minutes',
                () => setState(() => _unitKind = 'minutes')),
            const SizedBox(width: 8),
            _choiceChip('Count', _unitKind == 'count',
                () => setState(() => _unitKind = 'count')),
          ],
        ),
        const SizedBox(height: 16),
        _microLabel('EVERY DAY'),
        const SizedBox(height: 8),
        _stepperRow(
          value: _unitTarget,
          label: _unitKind == 'minutes' ? 'minutes a day' : 'times a day',
          options: _unitKind == 'minutes'
              ? const [15, 30, 45, 60, 90, 120]
              : const [1, 2, 3, 5, 10, 20],
          onChanged: (v) => setState(() => _unitTarget = v),
        ),
        const SizedBox(height: 16),
        _microLabel('FOR'),
        const SizedBox(height: 8),
        _stepperRow(
          value: _totalUnits,
          label: 'days',
          options: const [3, 7, 14, 21, 30],
          onChanged: (v) => setState(() => _totalUnits = v),
        ),
        const SizedBox(height: 20),
        _microLabel('STRICTNESS'),
        const SizedBox(height: 8),
        _modeCard('flexible', 'Flexible', 'Pass 70% of days'),
        _modeCard('disciplined', 'Disciplined', 'Pass 85% of days'),
        _modeCard('extreme', 'Extreme', 'Every single day. No excuses'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.fg12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'You pass by hitting $_requiredUnits of $_totalUnits days. '
            'A day counts from $_mercyTarget '
            '${_unitKind == 'minutes' ? 'min' : ''} — '
            'a 25% mercy for timer slips.',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step: stake ───────────────────────────────────────────────────────────

  Widget _categoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('What\'s on the line?'),
        const SizedBox(height: 12),
        _stakeChoiceCard(
          selected: _stake == _StakeChoice.photo,
          icon: Icons.photo_camera_rounded,
          iconColor: AppColors.coral,
          title: 'Photo stake',
          subtitle:
              'An embarrassing photo of you. Fail and it posts to your circle.',
          onTap: () => setState(() => _stake = _StakeChoice.photo),
        ),
        _stakeChoiceCard(
          selected: _isH2h,
          icon: Icons.sports_kabaddi_rounded,
          iconColor: AppColors.amber,
          title: 'Challenge a friend',
          subtitle:
              'Both stake points. The loser\'s points fund the winner\'s cause.',
          onTap: () => setState(() => _stake = _StakeChoice.h2h),
        ),
        // $ — debug builds only until Stripe activates (Phase 3 runbook);
        // the server rail is the SIMULATED provider either way.
        if (kDebugMode)
          _stakeChoiceCard(
            selected: _isMoney,
            icon: Icons.attach_money_rounded,
            iconColor: AppColors.statusGreen,
            title: 'Money stake (simulated)',
            subtitle:
                'Fail and it\'s donated to a cause you can\'t stand. No real '
                'money until Stripe is live.',
            onTap: () => setState(() => _stake = _StakeChoice.money),
          ),
        _stakeChoiceCard(
          selected: _isPractice,
          icon: Icons.school_rounded,
          iconColor: AppColors.textSoft,
          title: 'Practice run',
          subtitle: 'No stake — learn the loop first.',
          onTap: () => setState(() => _stake = _StakeChoice.practice),
        ),
      ],
    );
  }

  /// Type-specific setup, now that the category and commitment are known.
  Widget _detailsStep() {
    final circlesAsync = ref.watch(myCirclesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Set it up'),
        if (_isH2h) ..._h2hFields(),
        if (_isMoney) ..._moneyFields(),
        if (_stake == _StakeChoice.photo) ...[
          const SizedBox(height: 20),
          _microLabel('POSTS TO'),
          const SizedBox(height: 8),
          circlesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load circles',
                style: TextStyle(color: AppColors.danger)),
            data: (circles) {
              if (circles.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'A photo stake needs a circle to post to. Join one in '
                    'Community first — or start with a practice run.',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12.5,
                    ),
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final circle in circles)
                    _choiceChip(
                      circle.name,
                      _circleId == circle.id,
                      () => setState(() => _circleId = circle.id),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _microLabel('THE PHOTO'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.inkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _photo == null ? AppColors.fg24 : AppColors.coral,
                ),
              ),
              child: _photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            color: AppColors.textSoft, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          'Choose the photo you\'d hate them to see',
                          style: TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(
                        File(_photo!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _microLabel('IF IT POSTS, IT STAYS UP FOR'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, mins) in const [
                ('5 min', 5),
                ('30 min', 30),
                ('1 hour', 60),
                ('3 hours', 180),
                ('12 hours', 720),
                ('24 hours', 1440),
              ])
                _choiceChip(label, _revealWindowMins == mins,
                    () => setState(() => _revealWindowMins = mins)),
            ],
          ),
        ],
      ],
    );
  }

  /// h2h fields (D5/D6): opponent, stake size, and the two charity picks.
  List<Widget> _h2hFields() {
    final circlesAsync = ref.watch(myCirclesProvider);
    final charitiesAsync = ref.watch(charitiesProvider);
    final balance = ref.watch(pointsBalanceProvider).valueOrNull ?? 0;
    final myUid = FirestorePaths.activeUid;

    return [
      const SizedBox(height: 20),
      _microLabel('CIRCLE'),
      const SizedBox(height: 8),
      circlesAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) =>
            Text('Could not load circles', style: TextStyle(color: AppColors.danger)),
        data: (circles) => circles.isEmpty
            ? Text('Join a circle first — challenges live inside one.',
                style: TextStyle(color: AppColors.textSoft, fontSize: 12.5))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final circle in circles)
                    _choiceChip(circle.name, _circleId == circle.id, () {
                      setState(() {
                        _circleId = circle.id;
                        _opponentUid = null; // circle changed, re-pick
                      });
                    }),
                ],
              ),
      ),
      if (_circleId != null) ...[
        const SizedBox(height: 16),
        _microLabel('OPPONENT'),
        const SizedBox(height: 8),
        ref.watch(circleMembersProvider(_circleId!)).when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load members',
                  style: TextStyle(color: AppColors.danger)),
              data: (members) {
                final others =
                    members.where((m) => m.userId != myUid).toList();
                if (others.isEmpty) {
                  return Text('Nobody else in this circle yet.',
                      style:
                          TextStyle(color: AppColors.textSoft, fontSize: 12.5));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in others)
                      _choiceChip(
                        m.displayName.isEmpty ? 'Member' : m.displayName,
                        _opponentUid == m.userId,
                        () => setState(() => _opponentUid = m.userId),
                      ),
                  ],
                );
              },
            ),
      ],
      const SizedBox(height: 16),
      _microLabel('POINTS AT STAKE (EACH)'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final amount in const [100, 200, 300, 500])
            _choiceChip('$amount', _h2hStake == amount,
                () => setState(() => _h2hStake = amount)),
        ],
      ),
      if (balance < _h2hStake)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'You have $balance points — earn more before staking $_h2hStake.',
            style: TextStyle(color: AppColors.amber, fontSize: 12),
          ),
        ),
      const SizedBox(height: 16),
      _microLabel('IF YOU WIN, THEIR POINTS FUND'),
      const SizedBox(height: 8),
      _charityChips(
        charitiesAsync,
        selectedId: _charityId,
        onPick: (id) => setState(() => _charityId = id),
      ),
      const SizedBox(height: 16),
      _microLabel('IF YOU BOTH LOSE, EVERYTHING GOES TO'),
      const SizedBox(height: 8),
      _charityChips(
        charitiesAsync,
        selectedId: _bothLoseCharityId,
        onPick: (id) => setState(() => _bothLoseCharityId = id),
      ),
    ];
  }

  /// Solo money ($-1): amount + the anti-charity, with the simulation
  /// banner impossible to miss.
  List<Widget> _moneyFields() {
    final charitiesAsync = ref.watch(charitiesProvider);
    return [
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: Text(
          'SIMULATED — no card is charged and no real money moves. The full '
          'flow runs so it\'s real the day Stripe goes live.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 16),
      _microLabel('ON THE LINE'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, cents) in const [
            ('\$5', 500),
            ('\$10', 1000),
            ('\$20', 2000),
            ('\$50', 5000),
          ])
            _choiceChip(label, _moneyCents == cents,
                () => setState(() => _moneyCents = cents)),
        ],
      ),
      const SizedBox(height: 16),
      _microLabel('IF YOU FAIL, IT FUNDS'),
      const SizedBox(height: 8),
      Text(
        'Pick the one that hurts — that\'s the point.',
        style: TextStyle(color: AppColors.textSoft, fontSize: 12),
      ),
      const SizedBox(height: 8),
      _charityChips(
        charitiesAsync,
        selectedId: _antiCharityId,
        onPick: (id) => setState(() => _antiCharityId = id),
      ),
    ];
  }

  Widget _charityChips(
    AsyncValue<List<Charity>> charitiesAsync, {
    required String? selectedId,
    required ValueChanged<String> onPick,
  }) {
    return charitiesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text('Could not load charities', style: TextStyle(color: AppColors.danger)),
      data: (charities) => charities.isEmpty
          ? Text(
              'The charity list hasn\'t synced yet — check your connection.',
              style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final charity in charities)
                  _choiceChip(charity.name, selectedId == charity.id,
                      () => onPick(charity.id)),
              ],
            ),
    );
  }

  bool _pickingPhoto = false;

  Future<void> _pickPhoto() async {
    // Double-tapping the tile before iOS presents the picker fires a
    // second request that cancels the first with
    // PlatformException(multiple_request) — guard + swallow that case.
    if (_pickingPhoto) return;
    _pickingPhoto = true;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) setState(() => _photo = picked);
    } on PlatformException catch (e) {
      if (e.code != 'multiple_request') rethrow;
    } finally {
      _pickingPhoto = false;
    }
  }

  // ─── Step: consent (P-1 — explicit, in-flow, not ToS) ─────────────────────

  Widget _consentStep() {
    if (_isMoney) return _moneyConsentStep();
    final circles = ref.watch(myCirclesProvider).value ?? const [];
    final circle = circles.where((c) => c.id == _circleId).firstOrNull;
    final circleName = circle?.name ?? 'your circle';
    final members = circle?.memberCount ?? 0;
    final window = _revealWindowLabel(_revealWindowMins);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Read this carefully'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
          ),
          child: Text(
            'If you fail "${_title.text.trim()}" by the deadline, this photo '
            'will be posted to $circleName and visible to its '
            '$members members for $window.\n\n'
            'The decision is made by the server. Going offline, deleting the '
            'app, or missing the moment does not stop it.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _consentIsMe,
          onChanged: (v) => setState(() => _consentIsMe = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'This is a photo of me',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        CheckboxListTile(
          value: _consentPosting,
          onChanged: (v) => setState(() => _consentPosting = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'I understand it will be posted if I fail',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        // P-9 — photo stakes are 18+ (17+ App Store rating is the other
        // layer; this is the in-flow attestation).
        CheckboxListTile(
          value: _consentAdult,
          onChanged: (v) => setState(() => _consentAdult = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'I am 18 or older',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Money consent ($-1, D10): explicit, in-flow, with the no-mercy line.
  Widget _moneyConsentStep() {
    final charities = ref.watch(charitiesProvider).valueOrNull ?? const [];
    final charity = charities.where((c) => c.id == _antiCharityId).firstOrNull;
    final amount = '\$${(_moneyCents / 100).toStringAsFixed(0)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Read this carefully'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
          ),
          child: Text(
            'If you fail "${_title.text.trim()}" by the deadline, $amount '
            'will be donated to ${charity?.name ?? 'your chosen recipient'}. '
            'There is NO mercy veto on money — if you lose, you lose.\n\n'
            'Keep your word and every cent comes back to you.\n\n'
            '(Simulated build: no card is charged yet.)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _consentPosting,
          onChanged: (v) => setState(() => _consentPosting = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'I understand the money is donated if I fail — no undo',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        CheckboxListTile(
          value: _consentAdult,
          onChanged: (v) => setState(() => _consentAdult = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'I am 18 or older',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ─── Step: pledge (PSY-1) ──────────────────────────────────────────────────

  Widget _pledgeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Why does this matter?'),
        const SizedBox(height: 8),
        Text(
          'You\'ll see these words every time you log a day. '
          'Make them yours.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _why,
          maxLength: 280,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'So I stop failing exams I could pass…',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hold the button to give your word.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
        ),
      ],
    );
  }

  // ─── Step: review + create ─────────────────────────────────────────────────

  Widget _reviewStep() {
    final rows = <(String, String)>[
      ('Commitment', _title.text.trim()),
      (
        'Target',
        '$_unitTarget${_unitKind == 'minutes' ? ' min' : '×'} a day, '
            '$_totalUnits days ($_mode — pass $_requiredUnits)'
      ),
      ...switch (_stake) {
        _StakeChoice.photo => [
            ('Stake', 'Embarrassing photo'),
            ('Reveal window', _revealWindowLabel(_revealWindowMins)),
          ],
        _StakeChoice.h2h => [
            ('Stake', '$_h2hStake points each — locked when they accept'),
            ('Mode', 'They see "$_mode" before accepting'),
          ],
        _StakeChoice.money => [
            (
              'Stake',
              '\$${(_moneyCents / 100).toStringAsFixed(0)} — simulated, '
                  'charged at start, refunded if you pass'
            ),
          ],
        _StakeChoice.practice => [
            ('Stake', 'Practice — nothing on the line'),
          ],
      },
      ('Your word', _why.text.trim()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Look it in the eye'),
        const SizedBox(height: 12),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _microLabel(label.toUpperCase()),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        if (_createError != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _createError!,
              style: TextStyle(color: AppColors.danger, fontSize: 12.5),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _createError = null;
    });

    final functions = ref.read(stakeFunctionsProvider);
    final repository = ref.read(stakesRepositoryProvider);
    final uid = FirestorePaths.activeUid;
    final now = DateTime.now();

    // Free-tier monthly photo-stake quota — polite pre-check against the
    // local mirror; stakeCreateChallenge enforces the same rule
    // authoritatively server-side. Only activated challenges count
    // (draft/cancelled don't consume an allowance).
    if (_stake == _StakeChoice.photo) {
      final tierGate = ref.read(tierGateProvider);
      if (!tierGate.isBypassed) {
        final challenges =
            ref.read(stakeChallengesStreamProvider).value ??
            const <StakeChallenge>[];
        final monthStartMs = DateTime(now.year, now.month).millisecondsSinceEpoch;
        final usedThisMonth = challenges
            .where(
              (c) =>
                  c.type == StakeChallengeType.soloPhoto &&
                  c.createdAtMs >= monthStartMs &&
                  c.status != StakeChallengeStatus.draft &&
                  c.status != StakeChallengeStatus.cancelled,
            )
            .length;
        if (!tierGate.canCreatePhotoStakeThisMonth(usedThisMonth)) {
          setState(() {
            _creating = false;
            _createError =
                'The free plan includes '
                '${tierGate.limits.freePhotoStakesPerMonth} photo stakes per '
                'month — the counter resets on the 1st. SidePal Pro removes '
                'the limit.';
          });
          return;
        }
      }
    }
    final startOfToday = DateTime(now.year, now.month, now.day);
    var deadline = startOfToday
        .add(Duration(days: _totalUnits))
        .millisecondsSinceEpoch;
    // Server requires deadline ≥ now + 1h; a 1-day challenge started late
    // at night still gets a real runway.
    final minDeadline =
        now.add(const Duration(hours: 2)).millisecondsSinceEpoch;
    if (deadline < minDeadline) deadline = minDeadline;

    final id = StableId.generate('stk');
    final type = switch (_stake) {
      _StakeChoice.photo => 'solo_photo',
      _StakeChoice.h2h => 'h2h_points',
      _StakeChoice.money => 'solo_money',
      _StakeChoice.practice => 'practice',
    };

    try {
      Map<String, dynamic>? photoPayload;
      if (_stake == _StakeChoice.photo) {
        final storagePath = 'stake_photos/$id/$uid.jpg';
        // Owner-only path (storage.rules); the server verifies this exact
        // layout in stakeCreateChallenge.
        await FirebaseStorage.instance.ref(storagePath).putFile(
              File(_photo!.path),
              SettableMetadata(contentType: 'image/jpeg'),
            );
        photoPayload = {
          'storagePath': storagePath,
          'revealWindowMins': _revealWindowMins,
        };
      }

      await functions.createChallenge(
        challengeId: id,
        type: type,
        circleId: _isPractice ? '' : (_circleId ?? ''),
        goal: {
          'title': _title.text.trim(),
          'unitKind': _unitKind,
          'unitTarget': _unitTarget,
          'totalUnits': _totalUnits,
        },
        mode: _mode,
        deadlineMs: deadline,
        photo: photoPayload,
        opponentUid: _isH2h ? _opponentUid : null,
        stakeAmount: _isH2h ? _h2hStake : null,
        charityId: _isH2h ? _charityId : null,
        bothLoseCharityId: _isH2h ? _bothLoseCharityId : null,
        amountCents: _isMoney ? _moneyCents : null,
        antiCharityId: _isMoney ? _antiCharityId : null,
        pledgeWhy: _why.text.trim(),
      );

      // Optimistic local mirror so the challenge renders before the next
      // background pull (which LWW-overwrites with server truth).
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await repository.upsertLocalMirror(
        StakeChallenge(
          id: id,
          type: switch (_stake) {
            _StakeChoice.photo => StakeChallengeType.soloPhoto,
            _StakeChoice.h2h => StakeChallengeType.h2hPoints,
            _StakeChoice.money => StakeChallengeType.soloMoney,
            _StakeChoice.practice => StakeChallengeType.practice,
          },
          status: switch (_stake) {
            _StakeChoice.photo => StakeChallengeStatus.draft,
            _StakeChoice.h2h => StakeChallengeStatus.pendingAccept,
            _StakeChoice.money ||
            _StakeChoice.practice =>
              StakeChallengeStatus.active,
          },
          creatorUid: uid,
          circleId: (_isPractice || _isMoney) ? '' : (_circleId ?? ''),
          participants: [
            StakeParticipant(
              uid: uid,
              teamId: uid,
              stakeKind: switch (_stake) {
                _StakeChoice.photo => 'photo',
                _StakeChoice.money => 'money',
                _ => 'points',
              },
              stakeAmount: _isH2h
                  ? _h2hStake
                  : _isMoney
                      ? _moneyCents
                      : null,
              photoStoragePath: _stake == _StakeChoice.photo
                  ? 'stake_photos/$id/$uid.jpg'
                  : null,
              revealWindowMins:
                  _stake == _StakeChoice.photo ? _revealWindowMins : null,
              accepted: true,
            ),
            if (_isH2h && _opponentUid != null)
              StakeParticipant(
                uid: _opponentUid!,
                teamId: _opponentUid!,
                stakeKind: 'points',
                stakeAmount: _h2hStake,
                accepted: false,
              ),
          ],
          frozenGoal: StakeFrozenGoal(
            title: _title.text.trim(),
            unitKind: _unitKind,
            unitTarget: _unitTarget,
            totalUnits: _totalUnits,
          ),
          mode: _mode,
          sideCharities: _isH2h && _charityId != null
              ? {uid: _charityId!}
              : const {},
          bothLoseCharityId: _isH2h ? _bothLoseCharityId : null,
          antiCharityId: _isMoney ? _antiCharityId : null,
          deadlineMs: deadline,
          photoState: _stake == _StakeChoice.photo
              ? StakePhotoState.pendingScreen
              : null,
          createdAtMs: nowMs,
          // NOT the client clock: a phone running seconds ahead of the
          // server would make this optimistic row "newer" than the real
          // server writes, and LWW would reject every later flip (the
          // photo-screen result only appeared after a logout wipe).
          // 0 = "placeholder, first server echo replaces me".
          updatedAtMs: 0,
        ),
      );

      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      if (_stake == _StakeChoice.photo && _photo != null) {
        // Seed the owner's preview cache — the detail screen then shows
        // the photo instantly instead of re-downloading it (slow links
        // made the preview take minutes).
        unawaited(StakePhotoCache.seed(id, File(_photo!.path)));
      }
      nav.push(
        MaterialPageRoute(
          builder: (_) => StakeChallengeDetailScreen(challengeId: id),
        ),
      );
    } on StakeActionException catch (e) {
      final photoRejected = e.code == 'failed-precondition' &&
          e.message.toLowerCase().contains('rejected');
      setState(() {
        _creating = false;
        if (photoRejected) {
          // Content screening said no. Re-pressing the button would just
          // re-upload the same doomed photo under a new id and sit at
          // "checking" until it gets rejected again — bounce back to the
          // photo step and demand a different one instead.
          _photo = null;
          _step = _Step.details;
          _createError =
              'That photo was rejected by content screening — pick a '
              'different one.';
        } else {
          _createError = e.isRetryable
              ? 'Couldn\'t reach the server. Check your connection and try again.'
              : e.message;
        }
      });
    } catch (e) {
      setState(() {
        _creating = false;
        _createError = 'Something went wrong: $e';
      });
    }
  }

  // ─── Small shared widgets ──────────────────────────────────────────────────

  Widget _microLabel(String text) => Text(
        text,
        style: TextStyle(
          color: AppColors.textFaint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      );

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.18) : AppColors.inkCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.fg12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textSoft,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _stepperRow({
    required int value,
    required String label,
    required List<int> options,
    required ValueChanged<int> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final option in options)
          _choiceChip('$option', value == option, () => onChanged(option)),
        Text(label,
            style: TextStyle(color: AppColors.textSoft, fontSize: 12.5)),
      ],
    );
  }

  Widget _stakeChoiceCard({
    required bool selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.fg12,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard(String mode, String title, String subtitle) {
    final selected = _mode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _mode = mode),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.fg12,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _revealWindowLabel(int mins) {
    if (mins < 60) return '$mins minutes';
    if (mins == 60) return '1 hour';
    if (mins < 1440) return '${mins ~/ 60} hours';
    return '24 hours';
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i <= current ? AppColors.accent : AppColors.fg24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

/// PSY-1 — the pledge is an active gesture: hold 1.5s to commit.
class _HoldToCommitButton extends StatefulWidget {
  const _HoldToCommitButton({required this.enabled, required this.onCommitted});

  final bool enabled;
  final VoidCallback onCommitted;

  @override
  State<_HoldToCommitButton> createState() => _HoldToCommitButtonState();
}

class _HoldToCommitButtonState extends State<_HoldToCommitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCommitted();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _progress.forward() : null,
      onTapUp: (_) => _progress.reverse(),
      onTapCancel: () => _progress.reverse(),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              color: widget.enabled ? AppColors.accent : AppColors.fg12,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress.value,
                  child: Container(color: AppColors.accentDeep),
                ),
                Center(
                  child: Text(
                    _progress.value > 0 ? 'Keep holding…' : 'Hold to give your word',
                    style: TextStyle(
                      color: widget.enabled
                          ? AppColors.onAccent
                          : AppColors.textFaint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
