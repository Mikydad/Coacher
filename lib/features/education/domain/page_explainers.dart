/// One-page, illustrated "why this works" explainer for a concept page
/// (decision log 2026-09-27). Shown once on a user's first visit, and again
/// from the page's `?`. Short on purpose: a title, one line, a first-person
/// example, three icon steps, one small psychology line.
///
/// Distinct from [FeatureGuide] (the long help text the Coach AI also
/// teaches from): an explainer sells the idea, a guide documents it.
/// [guideId] links the two so the explainer's "More details" can open the
/// full guide.
class PageExplainer {
  const PageExplainer({
    required this.id,
    required this.scene,
    required this.title,
    required this.body,
    required this.example,
    required this.why,
    required this.steps,
    required this.primaryLabel,
    this.action = ExplainerAction.dismiss,
    this.guideId,
  });

  final String id;
  final ExplainerScene scene;
  final String title;

  /// One sentence: what the user does here.
  final String body;

  /// First-person, concrete, one sentence.
  final String example;

  /// The psychology line — why this works on a human.
  final String why;

  /// Exactly three.
  final List<ExplainerStep> steps;

  final String primaryLabel;
  final ExplainerAction action;

  /// The [FeatureGuide] with the long version, if any.
  final String? guideId;

  /// Key in the education seen-set (shared with first-time cards).
  String get seenKey => 'explainer:$id';
}

class ExplainerStep {
  const ExplainerStep(this.icon, this.label);

  /// An [ExplainerIcon] rather than IconData so this file stays Flutter-free.
  final ExplainerIcon icon;
  final String label;
}

/// Which illustration heads the sheet.
enum ExplainerScene { stake, group, direction, strictness, coach }

enum ExplainerIcon {
  target,
  camera,
  lock,
  groupAdd,
  checklist,
  eye,
  flag,
  route,
  calendar,
  moveOn,
  question,
  shield,
  chat,
  sparkle,
  undo,
}

/// What the primary button does. [dismiss] fits pages where the page
/// itself is the next step (Direction's editor, the Strictness picker).
enum ExplainerAction { dismiss, createStake, createGroup }

abstract final class PageExplainers {
  static const List<PageExplainer> all = [
    accountability,
    groups,
    direction,
    strictness,
    coach,
  ];

  static PageExplainer? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// The explainer that replaces the long help sheet for [guideId]'s `?`.
  static PageExplainer? forGuide(String guideId) {
    for (final e in all) {
      if (e.guideId == guideId) return e;
    }
    return null;
  }

  static const accountability = PageExplainer(
    id: 'accountability',
    scene: ExplainerScene.stake,
    title: 'Put something at stake',
    body: "Choose what happens if you don't reach your goal.",
    example:
        "“If I don't work out 3 times this week, my embarrassing photo "
        'gets shared with my group.”',
    why: 'We try harder to avoid losing something than to win something.',
    steps: [
      ExplainerStep(ExplainerIcon.target, 'Pick a goal'),
      ExplainerStep(ExplainerIcon.camera, 'Prove it'),
      ExplainerStep(ExplainerIcon.lock, 'Miss it, lose it'),
    ],
    primaryLabel: 'Create a stake',
    action: ExplainerAction.createStake,
  );

  static const groups = PageExplainer(
    id: 'groups',
    scene: ExplainerScene.group,
    title: 'Do it together',
    body: 'Share your weekly goals with a few friends who check on you.',
    example:
        "“I told my group I'd study 5 hours this week. Everyone can see "
        "I'm at 2.”",
    why:
        "It's easy to let yourself down. It's harder to let your friends "
        'down.',
    steps: [
      ExplainerStep(ExplainerIcon.groupAdd, 'Invite 3–6 friends'),
      ExplainerStep(ExplainerIcon.checklist, 'Set weekly goals'),
      ExplainerStep(ExplainerIcon.eye, 'See progress'),
    ],
    primaryLabel: 'Start a group',
    action: ExplainerAction.createGroup,
    guideId: 'circles',
  );

  static const direction = PageExplainer(
    id: 'direction',
    scene: ExplainerScene.direction,
    title: 'Know where you’re heading',
    body: 'Write what matters most this year, this quarter, and this month.',
    example:
        '“This year: get fit. This quarter: run a 5K. This month: run '
        '3 times a week.”',
    why: 'Small daily choices are easier when you know what they’re for.',
    steps: [
      ExplainerStep(ExplainerIcon.flag, 'Pick your year'),
      ExplainerStep(ExplainerIcon.route, 'Break it down'),
      ExplainerStep(ExplainerIcon.calendar, 'Plans follow it'),
    ],
    primaryLabel: 'Set my direction',
    guideId: 'direction',
  );

  static const strictness = PageExplainer(
    id: 'strictness',
    scene: ExplainerScene.strictness,
    title: 'Choose how strict SidePal is',
    body: "Decide what happens when a task doesn't get done.",
    example:
        "“On Extreme, I can't skip my 6 am workout. I do it, or I move it "
        'and say why.”',
    why: 'When skipping is easy, we skip. A little friction keeps us honest.',
    steps: [
      ExplainerStep(ExplainerIcon.moveOn, 'Flexible: move it'),
      ExplainerStep(ExplainerIcon.question, 'Disciplined: say why'),
      ExplainerStep(ExplainerIcon.shield, 'Extreme: no skipping'),
    ],
    primaryLabel: 'Choose my level',
    guideId: 'disciplineModes',
  );

  static const coach = PageExplainer(
    id: 'coach',
    scene: ExplainerScene.coach,
    title: 'A coach in your pocket',
    body: 'Ask SidePal to plan your day, add tasks, or talk it through.',
    example:
        '“Move my workout to tomorrow and add 30 minutes of reading '
        'tonight.”',
    why: 'Saying a plan out loud makes it clearer, and more likely to happen.',
    steps: [
      ExplainerStep(ExplainerIcon.chat, 'Ask in your words'),
      ExplainerStep(ExplainerIcon.sparkle, 'It updates your plan'),
      ExplainerStep(ExplainerIcon.undo, 'Change it anytime'),
    ],
    primaryLabel: 'Got it',
    guideId: 'coachAi',
  );
}
